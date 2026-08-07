import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/fleet_intelligence.dart';
import '../models/superintendent_action.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Localized presentation for the risk-intelligence layer: rule titles built
/// from the engine's structured facts (never free text), recommendations,
/// and the shared severity/health colour language used by the Command
/// Center, Risk and Actions screens.

String riskTitle(AppLocalizations t, RiskEvent r) {
  final subject = r.subject;
  final days = r.days ?? 0;
  return switch (r.kind) {
    RiskKind.defectCriticalOpen => t.riskDefectCriticalOpen(subject),
    RiskKind.defectHighOpen => t.riskDefectHighOpen(subject),
    RiskKind.defectStale => t.riskDefectStale(days, subject),
    RiskKind.defectRecurring => t.riskDefectRecurring(r.count ?? 0, subject),
    RiskKind.certExpired => t.riskCertExpired(subject),
    RiskKind.certExpiring => t.riskCertExpiring(days, subject),
    RiskKind.crewCertExpired => t.riskCrewCertExpired(subject),
    RiskKind.crewCertExpiring => t.riskCrewCertExpiring(days, subject),
    RiskKind.maintenanceOverdue => t.riskMaintenanceOverdue(subject),
    RiskKind.maintenanceDueSoon => t.riskMaintenanceDueSoon(days, subject),
    RiskKind.requisitionUrgentStalled =>
      t.riskRequisitionUrgentStalled(days, subject),
    RiskKind.requisitionDeliveryOverdue =>
      t.riskRequisitionDeliveryOverdue(subject),
    RiskKind.portRequirementPending => t.riskPortRequirementPending(subject),
    RiskKind.urgentNotificationOpen => t.riskUrgentNotificationOpen(subject),
    RiskKind.urgentActionOverdue => t.riskUrgentActionOverdue(subject),
    RiskKind.dailyTasksOverdue => t.riskDailyTasksOverdue(r.count ?? 0),
    RiskKind.dataMissingInfo => t.riskDataMissingInfo(subject),
  };
}

/// What the superintendent should do about it. Deliberately procedural — the
/// app recommends a next step, it never concludes a technical cause.
String riskRecommendation(AppLocalizations t, RiskEvent r) {
  return switch (r.kind) {
    RiskKind.defectCriticalOpen => t.recDefectCritical,
    RiskKind.defectHighOpen => t.recDefectHigh,
    RiskKind.defectStale => t.recDefectStale,
    RiskKind.defectRecurring => t.recDefectRecurring,
    RiskKind.certExpired ||
    RiskKind.certExpiring ||
    RiskKind.crewCertExpired ||
    RiskKind.crewCertExpiring =>
      t.recCertificate,
    RiskKind.maintenanceOverdue || RiskKind.maintenanceDueSoon => t.recMaintenance,
    RiskKind.requisitionUrgentStalled ||
    RiskKind.requisitionDeliveryOverdue =>
      t.recRequisition,
    RiskKind.portRequirementPending => t.recPortRequirement,
    RiskKind.urgentNotificationOpen ||
    RiskKind.urgentActionOverdue =>
      t.recUrgentNotification,
    RiskKind.dailyTasksOverdue => t.recDailyTasks,
    RiskKind.dataMissingInfo => t.recDataQuality,
  };
}

String severityLabel(AppLocalizations t, RiskSeverity s) => switch (s) {
      RiskSeverity.critical => t.severityCritical,
      RiskSeverity.high => t.severityHigh,
      RiskSeverity.medium => t.severityMedium,
      RiskSeverity.low => t.severityLow,
      RiskSeverity.info => t.severityInfo,
    };

Color severityColor(RiskSeverity s) => switch (s) {
      RiskSeverity.critical => AppColors.statusExpired,
      RiskSeverity.high => AppColors.statusMaintenance,
      RiskSeverity.medium => AppColors.amber400,
      RiskSeverity.low => AppColors.statusPort,
      RiskSeverity.info => AppColors.slate400,
    };

String categoryLabel(AppLocalizations t, RiskCategory c) => switch (c) {
      RiskCategory.defects => t.categoryDefects,
      RiskCategory.maintenance => t.categoryMaintenance,
      RiskCategory.certificates => t.categoryCertificates,
      RiskCategory.requisitions => t.categoryRequisitions,
      RiskCategory.crew => t.categoryCrew,
      RiskCategory.portReadiness => t.categoryPortReadiness,
      RiskCategory.operational => t.categoryOperational,
      RiskCategory.dataQuality => t.categoryDataQuality,
    };

String sourceModuleLabel(AppLocalizations t, String sourceType) =>
    switch (sourceType) {
      'defect' => t.sourceModuleDefect,
      'vesselCert' => t.sourceModuleVesselCert,
      'crewCert' => t.sourceModuleCrewCert,
      'maintenance' => t.sourceModuleMaintenance,
      'requisition' => t.sourceModuleRequisition,
      'portRequirement' => t.sourceModulePortRequirement,
      'urgentNotification' => t.sourceModuleUrgentNotification,
      'dailyTask' => t.sourceModuleDailyTask,
      _ => '',
    };

String bandLabel(AppLocalizations t, HealthBand b) => switch (b) {
      HealthBand.good => t.bandGood,
      HealthBand.attention => t.bandAttention,
      HealthBand.highRisk => t.bandHighRisk,
      HealthBand.critical => t.bandCritical,
    };

Color bandColor(HealthBand b) => switch (b) {
      HealthBand.good => AppColors.statusActive,
      HealthBand.attention => AppColors.amber400,
      HealthBand.highRisk => AppColors.statusMaintenance,
      HealthBand.critical => AppColors.statusExpired,
    };

String priorityLabel(AppLocalizations t, ActionPriority p) => switch (p) {
      ActionPriority.critical => t.priorityCritical,
      ActionPriority.high => t.priorityHigh,
      ActionPriority.medium => t.priorityMedium,
      ActionPriority.low => t.priorityLow,
    };

Color priorityColor(ActionPriority p) => switch (p) {
      ActionPriority.critical => AppColors.statusExpired,
      ActionPriority.high => AppColors.statusMaintenance,
      ActionPriority.medium => AppColors.amber400,
      ActionPriority.low => AppColors.statusPort,
    };

String actionStatusLabel(AppLocalizations t, SuperActionStatus s) =>
    switch (s) {
      SuperActionStatus.open => t.actionStatusOpen,
      SuperActionStatus.inProgress => t.actionStatusInProgress,
      SuperActionStatus.waitingVessel => t.actionStatusWaitingVessel,
      SuperActionStatus.waitingOffice => t.actionStatusWaitingOffice,
      SuperActionStatus.completed => t.actionStatusCompleted,
      SuperActionStatus.cancelled => t.actionStatusCancelled,
    };

/// The severity/priority pill used everywhere in the intelligence layer.
class RiskChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const RiskChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
