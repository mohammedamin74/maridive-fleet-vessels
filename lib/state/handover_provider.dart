import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment.dart';
import '../models/handover_report.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed crew handover reports. Records live in the shared Supabase
/// table so the incoming officer sees the outgoing officer's report from any
/// device. An in-memory cache is loaded on login (and refreshed after writes)
/// and exposed synchronously to the UI.
class HandoverProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('handover_reports');
  List<HandoverReport> _all = [];

  HandoverProvider() {
    _load();
    SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
          _load();
          break;
        case AuthChangeEvent.signedOut:
          _all = [];
          notifyListeners();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _load() async {
    try {
      final maps = await _store.fetchAll();
      _all = maps.map(HandoverReport.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  List<HandoverReport> forVessel(String vesselId) {
    final list = _all.where((h) => h.vesselId == vesselId).toList();
    list.sort((a, b) => b.handoverDate.compareTo(a.handoverDate));
    return list;
  }

  Future<void> _save(HandoverReport report) async {
    final idx = _all.indexWhere((h) => h.id == report.id);
    if (idx >= 0) {
      _all[idx] = report;
    } else {
      _all = [..._all, report];
    }
    notifyListeners();
    await _store.put(report.id, report.vesselId, report.toMap());
  }

  HandoverReport? _byId(String id) {
    for (final h in _all) {
      if (h.id == id) return h;
    }
    return null;
  }

  Future<void> add({
    required String vesselId,
    required String outgoingOfficer,
    required String incomingOfficer,
    String rank = '',
    required DateTime handoverDate,
    String safety = '',
    String machinery = '',
    String pendingDefects = '',
    String bunkersAndTanks = '',
    String certificatesExpiring = '',
    String remarks = '',
    List<Attachment> attachments = const [],
  }) async {
    await _save(HandoverReport(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      outgoingOfficer: outgoingOfficer,
      incomingOfficer: incomingOfficer,
      rank: rank,
      handoverDate: handoverDate,
      safety: safety,
      machinery: machinery,
      pendingDefects: pendingDefects,
      bunkersAndTanks: bunkersAndTanks,
      certificatesExpiring: certificatesExpiring,
      remarks: remarks,
      status: HandoverStatus.draft,
      attachments: attachments,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> update(HandoverReport report) => _save(report);

  Future<void> issue(String id) async {
    final report = _byId(id);
    if (report == null) return;
    await _save(report.copyWith(status: HandoverStatus.issued));
  }

  /// Marks the report read by the incoming officer. [acknowledgedBy] records
  /// who confirmed, defaulting to the report's incoming officer name.
  Future<void> acknowledge(String id, {String? acknowledgedBy}) async {
    final report = _byId(id);
    if (report == null) return;
    await _save(report.copyWith(
      status: HandoverStatus.acknowledged,
      acknowledgedBy: acknowledgedBy ?? report.incomingOfficer,
    ));
  }

  /// Reverts an issued report to draft so the outgoing officer can keep
  /// editing. Acknowledged reports are immutable history and stay locked.
  Future<void> reopen(String id) async {
    final report = _byId(id);
    if (report == null || report.status == HandoverStatus.acknowledged) return;
    await _save(report.copyWith(status: HandoverStatus.draft));
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final report = _byId(id);
    if (report == null) return;
    await _save(
        report.copyWith(attachments: [...report.attachments, attachment]));
  }

  Future<void> removeAttachment(String id, int index) async {
    final report = _byId(id);
    if (report == null) return;
    final files = [...report.attachments]..removeAt(index);
    await _save(report.copyWith(attachments: files));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((h) => h.id == id);
    notifyListeners();
    await _store.remove(id);
  }
}
