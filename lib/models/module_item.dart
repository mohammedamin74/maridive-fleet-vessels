/// A staged draft targeting one module, produced by routing+extracting one
/// [BatchFile]. Never auto-persisted — mirrors the existing single-file
/// AI-fill invariant (see ai_fill.dart) at batch scale: a human must accept
/// (optionally after editing [fields]) before anything reaches the real
/// module table via that module's own provider.
enum ItemStatus { pending, accepted, rejected, persisted, error }

class ModuleItem {
  final String id;
  final String batchId;
  final String sourceFileId;
  final String targetKind;
  final String? targetVesselId;
  final Map<String, dynamic> fields;
  final double confidence;
  final String matchedRuleId;
  final ItemStatus status;
  final String? persistedRecordId;
  final DateTime createdAt;

  const ModuleItem({
    required this.id,
    required this.batchId,
    required this.sourceFileId,
    required this.targetKind,
    this.targetVesselId,
    required this.fields,
    required this.confidence,
    required this.matchedRuleId,
    this.status = ItemStatus.pending,
    this.persistedRecordId,
    required this.createdAt,
  });

  ModuleItem copyWith({
    Map<String, dynamic>? fields,
    String? targetVesselId,
    ItemStatus? status,
    String? persistedRecordId,
  }) =>
      ModuleItem(
        id: id,
        batchId: batchId,
        sourceFileId: sourceFileId,
        targetKind: targetKind,
        targetVesselId: targetVesselId ?? this.targetVesselId,
        fields: fields ?? this.fields,
        confidence: confidence,
        matchedRuleId: matchedRuleId,
        status: status ?? this.status,
        persistedRecordId: persistedRecordId ?? this.persistedRecordId,
        createdAt: createdAt,
      );
}
