import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/batch_file.dart';
import '../models/error_log.dart';
import '../models/ingestion_batch.dart';
import '../models/module_item.dart';
import '../services/attachment_store.dart';
import '../services/cloud_store.dart';
import '../services/extraction_service.dart';
import '../services/routing_rules.dart';

/// Orchestrates a bulk file-ingestion batch: upload -> dedup -> route ->
/// extract -> stage. Never writes to a module's own table itself — that only
/// happens when the caller (a screen, which has BuildContext and therefore
/// access to every module provider) accepts a staged [ModuleItem] and calls
/// that module's existing add() method, then reports back via
/// [markPersisted]/[logPersistError]. This keeps the "AI output is never
/// saved directly" invariant from the single-file AI-fill flow intact at
/// batch scale.
class IngestionBatchProvider extends ChangeNotifier {
  final CloudStore _batches = const CloudStore('ingestion_batches');
  final CloudStore _errors = const CloudStore('ingestion_errors');

  IngestionBatch? _active;
  List<BatchFile> _files = [];
  List<ModuleItem> _items = [];
  List<ErrorLog> _errorsForActive = [];

  IngestionBatch? get active => _active;
  List<BatchFile> get files => List.unmodifiable(_files);
  List<ModuleItem> get items => List.unmodifiable(_items);
  List<ErrorLog> get errors => List.unmodifiable(_errorsForActive);

  Map<String, List<ModuleItem>> get itemsByKind {
    final map = <String, List<ModuleItem>>{};
    for (final item in _items) {
      map.putIfAbsent(item.targetKind, () => []).add(item);
    }
    return map;
  }

  Future<IngestionBatch> startBatch({
    required String uploadedBy,
    required List<String> vesselScope,
  }) async {
    final batch = IngestionBatch(
      id: 'batch_${DateTime.now().microsecondsSinceEpoch}',
      uploadedBy: uploadedBy,
      vesselScope: vesselScope,
      status: BatchStatus.uploading,
      createdAt: DateTime.now(),
    );
    _active = batch;
    _files = [];
    _items = [];
    _errorsForActive = [];
    notifyListeners();
    await _batches.put(batch.id, null, batch.toMap());
    return batch;
  }

  Future<void> _logError({
    required IngestionStage stage,
    required String reasonCode,
    String? fileId,
    String message = '',
  }) async {
    final batch = _active;
    if (batch == null) return;
    final err = ErrorLog(
      id: 'err_${DateTime.now().microsecondsSinceEpoch}_${_errorsForActive.length}',
      batchId: batch.id,
      fileId: fileId,
      stage: stage,
      reasonCode: reasonCode,
      message: message,
      occurredAt: DateTime.now(),
    );
    _errorsForActive = [..._errorsForActive, err];
    notifyListeners();
    await _errors.put(err.id, null, err.toMap());
  }

  /// Uploads [name]/[bytes] pairs, deduping exact-byte repeats within this
  /// batch by content hash before spending a Storage upload or an extraction
  /// call on something already queued.
  Future<void> addFiles(List<(String name, Uint8List bytes)> picked) async {
    final batch = _active;
    if (batch == null) return;
    final seenHashes = _files.map((f) => f.contentHash).toSet();
    for (final (name, bytes) in picked) {
      final hash = sha256.convert(bytes).toString();
      if (seenHashes.contains(hash)) {
        await _logError(
          stage: IngestionStage.ingest,
          reasonCode: 'duplicate_detected',
          message: name,
        );
        continue;
      }
      seenHashes.add(hash);
      final attachment = await AttachmentStore.upload(name, bytes);
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      final file = BatchFile(
        id: 'file_${DateTime.now().microsecondsSinceEpoch}_${_files.length}',
        batchId: batch.id,
        attachment: attachment,
        contentHash: hash,
        sizeBytes: bytes.length,
        detectedExt: ext,
        status: FileStatus.uploaded,
        uploadedAt: DateTime.now(),
      );
      _files = [..._files, file];
      notifyListeners();
    }
  }

  void _updateFile(String id, BatchFile Function(BatchFile) update) {
    _files = _files.map((f) => f.id == id ? update(f) : f).toList();
    notifyListeners();
  }

  /// Routes and extracts every uploaded-but-not-yet-processed file. A
  /// per-file failure is logged and skipped — never aborts the batch, same
  /// as the rest of this app's offline/failure handling (CloudStore,
  /// SyncQueue).
  Future<void> processAll({String? screenHint, String? targetVesselId}) async {
    for (final file in _files.where((f) => f.status == FileStatus.uploaded)) {
      await _processOne(file, screenHint: screenHint, targetVesselId: targetVesselId);
    }
  }

  Future<void> _processOne(BatchFile file,
      {String? screenHint, String? targetVesselId}) async {
    _updateFile(file.id, (f) => f.copyWith(status: FileStatus.extracting));
    if (!file.attachment.isCloud) {
      await _logError(
        stage: IngestionStage.ingest,
        reasonCode: 'upload_failed',
        fileId: file.id,
        message: file.attachment.name,
      );
      _updateFile(file.id, (f) => f.copyWith(status: FileStatus.error));
      return;
    }

    final decision = route(RoutingContext(
      filename: file.attachment.name,
      detectedExt: file.detectedExt,
      screenHint: screenHint,
    ));
    if (!decision.isClassified) {
      await _logError(
        stage: IngestionStage.route,
        reasonCode: 'unclassified',
        fileId: file.id,
        message: file.attachment.name,
      );
      _updateFile(file.id, (f) => f.copyWith(status: FileStatus.error));
      return;
    }

    try {
      final result = await ExtractionService.extractFor(
          storagePath: file.attachment.storagePath!, kind: decision.kind!);
      final rows = result.isList ? result.items! : [result.fields ?? {}];
      if (rows.isEmpty) {
        await _logError(
          stage: IngestionStage.extract,
          reasonCode: 'ai_empty',
          fileId: file.id,
        );
        _updateFile(file.id, (f) => f.copyWith(status: FileStatus.error));
        return;
      }
      var i = 0;
      for (final row in rows) {
        final item = ModuleItem(
          id: 'item_${DateTime.now().microsecondsSinceEpoch}_${i++}',
          batchId: file.batchId,
          sourceFileId: file.id,
          targetKind: decision.kind!,
          targetVesselId: targetVesselId,
          fields: row,
          confidence: decision.confidence,
          matchedRuleId: decision.ruleId,
          createdAt: DateTime.now(),
        );
        _items = [..._items, item];
      }
      _updateFile(file.id, (f) => f.copyWith(status: FileStatus.routed));
      notifyListeners();
    } on ExtractionException catch (e) {
      await _logError(
        stage: IngestionStage.extract,
        reasonCode: e.code,
        fileId: file.id,
      );
      _updateFile(file.id, (f) => f.copyWith(status: FileStatus.error));
    }
  }

  void updateItemFields(String itemId, Map<String, dynamic> fields) {
    _items = _items
        .map((i) => i.id == itemId ? i.copyWith(fields: fields) : i)
        .toList();
    notifyListeners();
  }

  void rejectItem(String itemId) {
    _items = _items
        .map((i) => i.id == itemId ? i.copyWith(status: ItemStatus.rejected) : i)
        .toList();
    notifyListeners();
  }

  /// Marks an item persisted once the caller has actually written it through
  /// the target module's own provider — this class never writes module
  /// tables itself, only tracks staging state.
  void markPersisted(String itemId, String recordId) {
    _items = _items
        .map((i) => i.id == itemId
            ? i.copyWith(status: ItemStatus.persisted, persistedRecordId: recordId)
            : i)
        .toList();
    notifyListeners();
  }

  Future<void> logPersistError(String itemId, String reasonCode) async {
    final item = _items.firstWhere((i) => i.id == itemId);
    await _logError(
      stage: IngestionStage.persist,
      reasonCode: reasonCode,
      fileId: item.sourceFileId,
    );
    _items = _items
        .map((i) => i.id == itemId ? i.copyWith(status: ItemStatus.error) : i)
        .toList();
    notifyListeners();
  }

  BatchSummary get summary {
    final byKind = <String, int>{};
    for (final item in _items) {
      if (item.status == ItemStatus.persisted) {
        byKind[item.targetKind] = (byKind[item.targetKind] ?? 0) + 1;
      }
    }
    return BatchSummary(
      filesTotal: _files.length,
      filesSucceeded: _files.where((f) => f.status == FileStatus.routed).length,
      filesFailed: _files.where((f) => f.status == FileStatus.error).length,
      itemsByModuleKind: byKind,
      duplicatesSkipped:
          _errorsForActive.where((e) => e.reasonCode == 'duplicate_detected').length,
      unclassified:
          _errorsForActive.where((e) => e.reasonCode == 'unclassified').length,
    );
  }

  Future<void> completeBatch() async {
    final batch = _active;
    if (batch == null) return;
    final updated = batch.copyWith(
      status: BatchStatus.completed,
      completedAt: DateTime.now(),
      summary: summary,
    );
    _active = updated;
    notifyListeners();
    await _batches.put(updated.id, null, updated.toMap());
  }
}
