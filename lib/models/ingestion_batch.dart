/// One multi-file bulk-import run: a user drops N files, each gets routed
/// to a module kind and extracted, and the resulting drafts wait in a
/// review queue until a human accepts or rejects each one. The batch row
/// itself is a lightweight audit record — an append-only log of what was
/// attempted and by whom, not the staged drafts themselves (those are
/// session-local; see [ModuleItem]).
enum BatchStatus { uploading, routing, reviewing, completed }

class BatchSummary {
  final int filesTotal;
  final int filesSucceeded;
  final int filesFailed;
  final Map<String, int> itemsByModuleKind;
  final int duplicatesSkipped;
  final int unclassified;

  const BatchSummary({
    this.filesTotal = 0,
    this.filesSucceeded = 0,
    this.filesFailed = 0,
    this.itemsByModuleKind = const {},
    this.duplicatesSkipped = 0,
    this.unclassified = 0,
  });

  Map<String, dynamic> toMap() => {
        'filesTotal': filesTotal,
        'filesSucceeded': filesSucceeded,
        'filesFailed': filesFailed,
        'itemsByModuleKind': itemsByModuleKind,
        'duplicatesSkipped': duplicatesSkipped,
        'unclassified': unclassified,
      };

  factory BatchSummary.fromMap(Map<dynamic, dynamic> map) => BatchSummary(
        filesTotal: (map['filesTotal'] as num?)?.toInt() ?? 0,
        filesSucceeded: (map['filesSucceeded'] as num?)?.toInt() ?? 0,
        filesFailed: (map['filesFailed'] as num?)?.toInt() ?? 0,
        itemsByModuleKind: (map['itemsByModuleKind'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            const {},
        duplicatesSkipped: (map['duplicatesSkipped'] as num?)?.toInt() ?? 0,
        unclassified: (map['unclassified'] as num?)?.toInt() ?? 0,
      );
}

class IngestionBatch {
  final String id;
  final String uploadedBy;
  final List<String> vesselScope;
  final BatchStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final BatchSummary summary;

  const IngestionBatch({
    required this.id,
    required this.uploadedBy,
    required this.vesselScope,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.summary = const BatchSummary(),
  });

  IngestionBatch copyWith({BatchStatus? status, DateTime? completedAt, BatchSummary? summary}) =>
      IngestionBatch(
        id: id,
        uploadedBy: uploadedBy,
        vesselScope: vesselScope,
        status: status ?? this.status,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
        summary: summary ?? this.summary,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'uploadedBy': uploadedBy,
        'vesselScope': vesselScope,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'summary': summary.toMap(),
      };

  factory IngestionBatch.fromMap(Map<dynamic, dynamic> map) => IngestionBatch(
        id: map['id'] as String,
        uploadedBy: (map['uploadedBy'] as String?) ?? '',
        vesselScope: ((map['vesselScope'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        status:
            BatchStatus.values.byName((map['status'] as String?) ?? 'uploading'),
        createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        completedAt: (map['completedAt'] as String?) != null
            ? DateTime.tryParse(map['completedAt'] as String)
            : null,
        summary: map['summary'] is Map
            ? BatchSummary.fromMap(map['summary'] as Map)
            : const BatchSummary(),
      );
}
