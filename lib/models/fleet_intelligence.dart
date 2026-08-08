/// Computed (never persisted) risk-intelligence value objects for the Smart
/// Fleet layer: deterministic risks derived from module records, and the
/// explainable 0-100 vessel health score built from them. Every risk points
/// back to its source record — nothing here is invented or AI-generated.
library;

/// Ordered most → least severe so `severity.index` sorts risk lists.
enum RiskSeverity { critical, high, medium, low, info }

/// The seven health-score components (spec weights) plus data quality,
/// which surfaces as INFO risks but never deducts points.
enum RiskCategory {
  defects,
  maintenance,
  certificates,
  requisitions,
  crew,
  portReadiness,
  operational,
  dataQuality,
}

/// One deterministic rule id. The UI maps each kind to a localized title
/// template; the engine only emits structured facts (subject/days/count).
enum RiskKind {
  defectCriticalOpen,
  defectHighOpen,
  defectStale,
  defectRecurring,
  certExpired,
  certExpiring,
  crewCertExpired,
  crewCertExpiring,
  maintenanceOverdue,
  maintenanceDueSoon,
  requisitionUrgentStalled,
  requisitionDeliveryOverdue,
  portRequirementPending,
  urgentNotificationOpen,
  urgentActionOverdue,
  dailyTasksOverdue,
  checklistIncomplete,
  checklistMissing,
  dataMissingInfo,
}

/// A single detected risk with its evidence trail. `subject` is real record
/// text (defect title, certificate name, "officer — cert type"); `days` and
/// `count` carry the rule's numeric context (meaning depends on [kind]).
class RiskEvent {
  final String vesselId;
  final RiskKind kind;
  final RiskCategory category;
  final RiskSeverity severity;
  final String subject;
  final String sourceType; // module slug: defect, vesselCert, requisition, ...
  final String sourceId;
  final int? days;
  final int? count;
  final DateTime? dueDate;

  const RiskEvent({
    required this.vesselId,
    required this.kind,
    required this.category,
    required this.severity,
    required this.subject,
    required this.sourceType,
    required this.sourceId,
    this.days,
    this.count,
    this.dueDate,
  });

  /// Stable identity so one record produces one risk per rule.
  String get id => '${kind.name}:$sourceId';
}

enum HealthBand { good, attention, highRisk, critical }

/// One line of the "why is this score X?" explanation: the points removed
/// from the overall score and the risk that caused it.
class HealthDeduction {
  final int points;
  final RiskEvent risk;
  const HealthDeduction(this.points, this.risk);
}

/// Explainable vessel health: overall 0-100, per-component 0-100, and the
/// deduction list that justifies the number. Computed live on-device.
class VesselHealth {
  final String vesselId;
  final int score;
  final HealthBand band;
  final Map<RiskCategory, int> componentScores;
  final List<HealthDeduction> deductions;
  final DateTime calculatedAt;

  const VesselHealth({
    required this.vesselId,
    required this.score,
    required this.band,
    required this.componentScores,
    required this.deductions,
    required this.calculatedAt,
  });
}
