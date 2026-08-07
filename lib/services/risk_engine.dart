import '../models/crew_certificate.dart';
import '../models/daily_task.dart';
import '../models/defect.dart';
import '../models/fleet_intelligence.dart';
import '../models/maintenance_record.dart';
import '../models/port_requirement.dart';
import '../models/requisition.dart';
import '../models/superintendent_action.dart';
import '../models/urgent_notification.dart';
import '../models/vessel_certificate.dart';
import 'clock.dart';

/// Everything one vessel's risk analysis needs, gathered from the existing
/// providers by the caller. Keeping this a plain value object is what makes
/// [RiskEngine] pure and unit-testable without Flutter or Supabase.
class VesselRiskInput {
  final String vesselId;
  final List<Defect> defects;
  final List<VesselCertificate> vesselCerts;
  final List<CrewCertificate> crewCerts;
  final List<MaintenanceRecord> maintenance;
  final List<Requisition> requisitions;
  final List<PortRequirement> portRequirements;
  final List<UrgentNotification> notifications;
  final List<DailyTask> dailyTasks;
  final List<SuperintendentAction> actions;

  const VesselRiskInput({
    required this.vesselId,
    this.defects = const [],
    this.vesselCerts = const [],
    this.crewCerts = const [],
    this.maintenance = const [],
    this.requisitions = const [],
    this.portRequirements = const [],
    this.notifications = const [],
    this.dailyTasks = const [],
    this.actions = const [],
  });
}

/// Deterministic risk detection over a vessel's real records.
///
/// Every emitted [RiskEvent] names the record it came from, so the UI can
/// always answer "why?" by opening the source. No AI, no inference beyond
/// the stated rules — a pattern (like a repeated defect) is reported as a
/// pattern needing human review, never as a diagnosed cause.
class RiskEngine {
  const RiskEngine._();

  /// Certificate windows (spec §13). Expired and <= 7 days are CRITICAL.
  static const int certCriticalDays = 7;
  static const int certHighDays = 30;
  static const int certMediumDays = 60;
  static const int certLowDays = 90;

  /// A low/medium defect still open this long is itself a risk.
  static const int defectStaleDays = 30;

  /// Same defect title appearing this many times = recurring pattern.
  static const int recurringDefectThreshold = 3;

  /// Urgent requisition still inside the approval chain this long.
  static const int requisitionStalledDays = 7;

  static const int maintenanceDueSoonDays = 7;

  static List<RiskEvent> analyze(VesselRiskInput input) {
    final now = clockNow();
    final risks = <RiskEvent>[
      ..._defectRisks(input, now),
      ..._certificateRisks(input, now),
      ..._maintenanceRisks(input, now),
      ..._requisitionRisks(input, now),
      ..._portReadinessRisks(input),
      ..._operationalRisks(input, now),
      ..._dataQualityRisks(input),
    ];
    risks.sort((a, b) {
      final bySeverity = a.severity.index.compareTo(b.severity.index);
      if (bySeverity != 0) return bySeverity;
      return a.subject.compareTo(b.subject);
    });
    return risks;
  }

  // --- Defects ------------------------------------------------------------

  static Iterable<RiskEvent> _defectRisks(VesselRiskInput i, DateTime now) {
    final out = <RiskEvent>[];
    final open =
        i.defects.where((d) => d.status != DefectStatus.closed).toList();

    for (final d in open) {
      final ageDays = now.difference(d.reportedAt).inDays;
      if (d.priority == DefectPriority.critical) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.defectCriticalOpen,
          category: RiskCategory.defects,
          severity: RiskSeverity.critical,
          subject: d.title,
          sourceType: 'defect',
          sourceId: d.id,
          days: ageDays,
        ));
      } else if (d.priority == DefectPriority.high) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.defectHighOpen,
          category: RiskCategory.defects,
          severity: RiskSeverity.high,
          subject: d.title,
          sourceType: 'defect',
          sourceId: d.id,
          days: ageDays,
        ));
      } else if (ageDays >= defectStaleDays) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.defectStale,
          category: RiskCategory.defects,
          severity: RiskSeverity.medium,
          subject: d.title,
          sourceType: 'defect',
          sourceId: d.id,
          days: ageDays,
        ));
      }
    }

    // Recurring pattern across the vessel's whole defect history (including
    // closed ones — a defect that keeps coming back is the point). Reported
    // for human review; the engine never assigns a root cause.
    final byTitle = <String, List<Defect>>{};
    for (final d in i.defects) {
      final key = d.title.trim().toLowerCase();
      if (key.isEmpty) continue;
      byTitle.putIfAbsent(key, () => []).add(d);
    }
    for (final group in byTitle.values) {
      if (group.length < recurringDefectThreshold) continue;
      group.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      out.add(RiskEvent(
        vesselId: i.vesselId,
        kind: RiskKind.defectRecurring,
        category: RiskCategory.defects,
        severity: RiskSeverity.medium,
        subject: group.first.title,
        sourceType: 'defect',
        sourceId: group.first.id,
        count: group.length,
      ));
    }
    return out;
  }

  // --- Certificates -------------------------------------------------------

  static RiskSeverity? _certSeverity(int daysLeft) {
    if (daysLeft <= certCriticalDays) return RiskSeverity.critical;
    if (daysLeft <= certHighDays) return RiskSeverity.high;
    if (daysLeft <= certMediumDays) return RiskSeverity.medium;
    if (daysLeft <= certLowDays) return RiskSeverity.low;
    return null;
  }

  static Iterable<RiskEvent> _certificateRisks(
      VesselRiskInput i, DateTime now) {
    final out = <RiskEvent>[];

    for (final c in i.vesselCerts) {
      final daysLeft = c.expiryDate.difference(now).inDays;
      final severity = _certSeverity(daysLeft);
      if (severity == null) continue;
      out.add(RiskEvent(
        vesselId: i.vesselId,
        kind: daysLeft < 0 ? RiskKind.certExpired : RiskKind.certExpiring,
        category: RiskCategory.certificates,
        severity: severity,
        subject: c.documentName,
        sourceType: 'vesselCert',
        sourceId: c.id,
        days: daysLeft,
        dueDate: c.expiryDate,
      ));
    }

    for (final c in i.crewCerts) {
      final daysLeft = c.expiryDate.difference(now).inDays;
      final severity = _certSeverity(daysLeft);
      if (severity == null) continue;
      out.add(RiskEvent(
        vesselId: i.vesselId,
        kind:
            daysLeft < 0 ? RiskKind.crewCertExpired : RiskKind.crewCertExpiring,
        category: RiskCategory.crew,
        severity: severity,
        subject: '${c.officerName} — ${c.certType.name.toUpperCase()}',
        sourceType: 'crewCert',
        sourceId: c.id,
        days: daysLeft,
        dueDate: c.expiryDate,
      ));
    }
    return out;
  }

  // --- Maintenance --------------------------------------------------------

  static Iterable<RiskEvent> _maintenanceRisks(
      VesselRiskInput i, DateTime now) {
    final out = <RiskEvent>[];
    for (final m in i.maintenance) {
      if (m.status == MaintenanceStatus.completed) continue;
      final daysLeft = m.dueDate.difference(now).inDays;
      if (daysLeft < 0) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.maintenanceOverdue,
          category: RiskCategory.maintenance,
          severity: RiskSeverity.high,
          subject: m.title,
          sourceType: 'maintenance',
          sourceId: m.id,
          days: daysLeft,
          dueDate: m.dueDate,
        ));
      } else if (daysLeft <= maintenanceDueSoonDays) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.maintenanceDueSoon,
          category: RiskCategory.maintenance,
          severity: RiskSeverity.low,
          subject: m.title,
          sourceType: 'maintenance',
          sourceId: m.id,
          days: daysLeft,
          dueDate: m.dueDate,
        ));
      }
    }
    return out;
  }

  // --- Requisitions -------------------------------------------------------

  static const _openRequisitionStatuses = {
    RequisitionStatus.pending,
    RequisitionStatus.hodApproval,
    RequisitionStatus.technicalSupApproval,
  };

  static Iterable<RiskEvent> _requisitionRisks(
      VesselRiskInput i, DateTime now) {
    final out = <RiskEvent>[];
    for (final r in i.requisitions) {
      if (r.status == RequisitionStatus.received ||
          r.status == RequisitionStatus.rejected) {
        continue;
      }

      final waitingDays = now.difference(r.requestedAt).inDays;
      if (r.priority == RequisitionPriority.urgent &&
          _openRequisitionStatuses.contains(r.status) &&
          waitingDays >= requisitionStalledDays) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.requisitionUrgentStalled,
          category: RiskCategory.requisitions,
          severity: RiskSeverity.high,
          subject: r.itemName,
          sourceType: 'requisition',
          sourceId: r.id,
          days: waitingDays,
        ));
        continue;
      }

      final due = r.requiredDeliveryDate;
      if (due != null && due.isBefore(now)) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.requisitionDeliveryOverdue,
          category: RiskCategory.requisitions,
          severity: RiskSeverity.medium,
          subject: r.itemName,
          sourceType: 'requisition',
          sourceId: r.id,
          days: due.difference(now).inDays,
          dueDate: due,
        ));
      }
    }
    return out;
  }

  // --- Port readiness -----------------------------------------------------

  static Iterable<RiskEvent> _portReadinessRisks(VesselRiskInput i) {
    return i.portRequirements
        .where((r) => r.status == RequirementStatus.pending)
        .map((r) => RiskEvent(
              vesselId: i.vesselId,
              kind: RiskKind.portRequirementPending,
              category: RiskCategory.portReadiness,
              severity: RiskSeverity.low,
              subject: r.portName.isEmpty ? r.title : '${r.portName} — ${r.title}',
              sourceType: 'portRequirement',
              sourceId: r.id,
            ));
  }

  /// Share of port requirements that are ready, 0-100. Null when the vessel
  /// has no requirements recorded — an empty list is "no data", not 100%.
  static int? portReadinessPercent(VesselRiskInput i) {
    if (i.portRequirements.isEmpty) return null;
    final ready = i.portRequirements
        .where((r) => r.status == RequirementStatus.ready)
        .length;
    return ((ready / i.portRequirements.length) * 100).round();
  }

  // --- Operational --------------------------------------------------------

  static Iterable<RiskEvent> _operationalRisks(
      VesselRiskInput i, DateTime now) {
    final out = <RiskEvent>[];

    for (final n in i.notifications) {
      if (n.escalationStatus == EscalationStatus.notAcknowledged) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.urgentNotificationOpen,
          category: RiskCategory.operational,
          severity: RiskSeverity.high,
          subject: n.description.isEmpty ? n.alertType.name : n.description,
          sourceType: 'urgentNotification',
          sourceId: n.id,
          days: now.difference(n.timestamp).inDays,
        ));
      } else if (n.isOverdue) {
        out.add(RiskEvent(
          vesselId: i.vesselId,
          kind: RiskKind.urgentActionOverdue,
          category: RiskCategory.operational,
          severity: RiskSeverity.high,
          subject: n.description.isEmpty ? n.alertType.name : n.description,
          sourceType: 'urgentNotification',
          sourceId: n.id,
          dueDate: n.dueDate,
        ));
      }
    }

    final overdueTasks = i.dailyTasks.where((t) => t.isOverdue).toList();
    if (overdueTasks.isNotEmpty) {
      out.add(RiskEvent(
        vesselId: i.vesselId,
        kind: RiskKind.dailyTasksOverdue,
        category: RiskCategory.operational,
        severity: RiskSeverity.medium,
        subject: overdueTasks.first.title,
        sourceType: 'dailyTask',
        sourceId: overdueTasks.first.id,
        count: overdueTasks.length,
      ));
    }
    return out;
  }

  // --- Data quality (INFO only — never deducts health points) -------------

  static Iterable<RiskEvent> _dataQualityRisks(VesselRiskInput i) {
    return i.defects
        .where((d) =>
            d.status != DefectStatus.closed &&
            (d.priority == DefectPriority.critical ||
                d.priority == DefectPriority.high) &&
            d.assignedOfficer.trim().isEmpty)
        .map((d) => RiskEvent(
              vesselId: i.vesselId,
              kind: RiskKind.dataMissingInfo,
              category: RiskCategory.dataQuality,
              severity: RiskSeverity.info,
              subject: d.title,
              sourceType: 'defect',
              sourceId: d.id,
            ));
  }
}
