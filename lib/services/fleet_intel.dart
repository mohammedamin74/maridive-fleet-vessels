import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/checklist_templates.dart';
import '../data/fleet_data.dart';
import '../models/fleet_intelligence.dart';
import '../models/vessel.dart';
import '../state/action_provider.dart';
import '../state/certification_provider.dart';
import '../state/checklist_provider.dart';
import 'clock.dart';
import '../state/daily_tasks_provider.dart';
import '../state/maintenance_provider.dart';
import '../state/port_requirement_provider.dart';
import '../state/tank_data_provider.dart';
import '../state/urgent_notification_provider.dart';
import 'risk_engine.dart';
import 'vessel_health_service.dart';

/// One vessel's computed intelligence: its risks, its explainable health
/// score, and its port readiness percentage.
class VesselIntel {
  final Vessel vessel;
  final List<RiskEvent> risks;
  final VesselHealth health;
  final int? portReadinessPercent;

  const VesselIntel({
    required this.vessel,
    required this.risks,
    required this.health,
    required this.portReadinessPercent,
  });

  int get criticalCount =>
      risks.where((r) => r.severity == RiskSeverity.critical).length;
  int get highCount => risks.where((r) => r.severity == RiskSeverity.high).length;
}

/// Fleet-wide snapshot, ranked worst-health first.
class FleetIntel {
  final List<VesselIntel> vessels;
  const FleetIntel(this.vessels);

  List<RiskEvent> get allRisks => [
        for (final v in vessels) ...v.risks,
      ]..sort((a, b) => a.severity.index.compareTo(b.severity.index));

  int countInBand(HealthBand band) =>
      vessels.where((v) => v.health.band == band).length;

  int countBySeverity(RiskSeverity severity) =>
      allRisks.where((r) => r.severity == severity).length;

  VesselIntel? forVessel(String vesselId) {
    for (final v in vessels) {
      if (v.vessel.id == vesselId) return v;
    }
    return null;
  }

  /// Builds the whole fleet's intelligence from the existing module
  /// providers. Everything is computed on-device from already-loaded caches,
  /// so this is cheap at fleet scale and works fully offline; nothing new is
  /// fetched and nothing is persisted.
  ///
  /// Call from a widget that watches the source providers so the snapshot
  /// refreshes whenever any module's data changes.
  static FleetIntel build(BuildContext context) {
    final tanks = context.watch<TankDataProvider>();
    final certs = context.watch<CertificationProvider>();
    final maintenance = context.watch<MaintenanceProvider>();
    final requirements = context.watch<PortRequirementProvider>();
    final notifications = context.watch<UrgentNotificationProvider>();
    final tasks = context.watch<DailyTasksProvider>();
    final actions = context.watch<ActionProvider>();
    final checklists = context.watch<ChecklistProvider>();
    final now = clockNow();

    final result = <VesselIntel>[];
    for (final vessel in FleetData.vessels) {
      final input = VesselRiskInput(
        vesselId: vessel.id,
        defects: tanks.defectsFor(vessel.id),
        requisitions: tanks.requisitionsFor(vessel.id),
        vesselCerts: certs.vesselCertsFor(vessel.id),
        crewCerts: certs.crewCertsFor(vessel.id),
        maintenance: maintenance.forVessel(vessel.id),
        portRequirements: requirements.forVessel(vessel.id),
        notifications: notifications.forVessel(vessel.id),
        dailyTasks: tasks.forVessel(vessel.id),
        actions: actions.forVessel(vessel.id),
        criticalChecklist: checklists.find(
          vesselId: vessel.id,
          templateCode: ChecklistTemplates.criticalEquipment.code,
          year: now.year,
          month: now.month,
        ),
        criticalChecklistItemCount:
            ChecklistTemplates.criticalEquipment.items.length,
      );
      final risks = RiskEngine.analyze(input);
      result.add(VesselIntel(
        vessel: vessel,
        risks: risks,
        health: VesselHealthService.calculate(
            vesselId: vessel.id, risks: risks),
        portReadinessPercent: RiskEngine.portReadinessPercent(input),
      ));
    }

    result.sort((a, b) => a.health.score.compareTo(b.health.score));
    return FleetIntel(result);
  }
}
