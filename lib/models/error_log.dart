/// One ingestion failure, at file or batch scope. Append-only audit trail —
/// stored via CloudStore('ingestion_errors') alongside IngestionBatch so a
/// flaky free-tier extraction day (or a bad routing rule) is diagnosable
/// after the fact, the same way the `extract` edge function's own
/// per-attempt log already makes model failures diagnosable in the moment.
enum IngestionStage { ingest, detect, extract, route, persist }

class ErrorLog {
  final String id;
  final String batchId;
  final String? fileId;
  final IngestionStage stage;
  final String reasonCode;
  final String message;
  final DateTime occurredAt;

  const ErrorLog({
    required this.id,
    required this.batchId,
    this.fileId,
    required this.stage,
    required this.reasonCode,
    this.message = '',
    required this.occurredAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'batchId': batchId,
        if (fileId != null) 'fileId': fileId,
        'stage': stage.name,
        'reasonCode': reasonCode,
        'message': message,
        'occurredAt': occurredAt.toIso8601String(),
      };

  factory ErrorLog.fromMap(Map<dynamic, dynamic> map) => ErrorLog(
        id: map['id'] as String,
        batchId: (map['batchId'] as String?) ?? '',
        fileId: map['fileId'] as String?,
        stage: IngestionStage.values
            .byName((map['stage'] as String?) ?? 'extract'),
        reasonCode: (map['reasonCode'] as String?) ?? 'unexpected',
        message: (map['message'] as String?) ?? '',
        occurredAt: DateTime.tryParse((map['occurredAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
