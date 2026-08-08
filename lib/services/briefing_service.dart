import '../models/fleet_intelligence.dart';
import '../models/superintendent_action.dart';
import 'clock.dart';
import 'fleet_intel.dart';

/// One line of the briefing, carrying the risk (or action) behind it so the
/// UI can show evidence and the superintendent can drill down.
class BriefingItem {
  final String vesselName;
  final RiskEvent? risk;
  final SuperintendentAction? action;

  const BriefingItem({required this.vesselName, this.risk, this.action});
}

/// The Superintendent Daily Briefing: what is confirmed, what needs doing
/// today, what is coming, and what is fine.
///
/// Built deterministically from the fleet's own records, so it is available
/// offline and every line is traceable. An optional AI narrative can be
/// requested separately and is always labelled as such — the facts here
/// never come from a model.
class DailyBriefing {
  final DateTime generatedAt;
  final int vesselCount;
  final int healthyCount;
  final int attentionCount;
  final int highRiskCount;
  final int criticalCount;

  /// Confirmed critical conditions — act now.
  final List<BriefingItem> critical;

  /// High-severity items to follow up today.
  final List<BriefingItem> highPriority;

  /// Medium/low items that need preparation, not panic.
  final List<BriefingItem> upcoming;

  /// Vessels with nothing above LOW — worth stating, so a quiet vessel
  /// reads as verified-quiet rather than forgotten.
  final List<String> positive;

  /// Open actions already tracked, overdue first.
  final List<BriefingItem> openActions;
  final int overdueActionCount;

  const DailyBriefing({
    required this.generatedAt,
    required this.vesselCount,
    required this.healthyCount,
    required this.attentionCount,
    required this.highRiskCount,
    required this.criticalCount,
    required this.critical,
    required this.highPriority,
    required this.upcoming,
    required this.positive,
    required this.openActions,
    required this.overdueActionCount,
  });

  bool get isAllClear =>
      critical.isEmpty && highPriority.isEmpty && upcoming.isEmpty;
}

class BriefingService {
  const BriefingService._();

  /// Cap per section so the briefing stays a briefing. The counts above the
  /// lists remain exact, so nothing is silently hidden.
  static const int maxPerSection = 8;

  static DailyBriefing build({
    required FleetIntel intel,
    required List<SuperintendentAction> openActions,
  }) {
    final names = {
      for (final v in intel.vessels)
        v.vessel.id: v.vessel.name.replaceFirst('Maridive ', '')
    };

    List<BriefingItem> pick(bool Function(RiskEvent) test) => [
          for (final v in intel.vessels)
            for (final r in v.risks)
              if (test(r))
                BriefingItem(
                    vesselName: names[v.vessel.id] ?? v.vessel.id, risk: r)
        ].take(maxPerSection).toList();

    final positive = [
      for (final v in intel.vessels)
        if (!v.risks.any((r) =>
            r.severity == RiskSeverity.critical ||
            r.severity == RiskSeverity.high ||
            r.severity == RiskSeverity.medium))
          names[v.vessel.id] ?? v.vessel.id
    ];

    final actions = [...openActions]..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        return a.priority.index.compareTo(b.priority.index);
      });

    return DailyBriefing(
      generatedAt: clockNow(),
      vesselCount: intel.vessels.length,
      healthyCount: intel.countInBand(HealthBand.good),
      attentionCount: intel.countInBand(HealthBand.attention),
      highRiskCount: intel.countInBand(HealthBand.highRisk),
      criticalCount: intel.countInBand(HealthBand.critical),
      critical: pick((r) => r.severity == RiskSeverity.critical),
      highPriority: pick((r) => r.severity == RiskSeverity.high),
      upcoming: pick((r) =>
          r.severity == RiskSeverity.medium || r.severity == RiskSeverity.low),
      positive: positive,
      openActions: [
        for (final a in actions.take(maxPerSection))
          BriefingItem(
              vesselName: names[a.vesselId] ?? a.vesselId, action: a)
      ],
      overdueActionCount: openActions.where((a) => a.isOverdue).length,
    );
  }

  /// Compact, non-sensitive structured snapshot handed to the fleet AI as
  /// its only source of truth. Deliberately minimal: counts, severities and
  /// short subjects — no crew PII, no costs, no attachments, no record ids.
  static Map<String, dynamic> aiContext({
    required FleetIntel intel,
    required List<SuperintendentAction> openActions,
  }) {
    return {
      'fleet': {
        'vessels': intel.vessels.length,
        'healthy': intel.countInBand(HealthBand.good),
        'attention': intel.countInBand(HealthBand.attention),
        'highRisk': intel.countInBand(HealthBand.highRisk),
        'critical': intel.countInBand(HealthBand.critical),
        'openActions': openActions.length,
        'overdueActions': openActions.where((a) => a.isOverdue).length,
      },
      'vessels': [
        for (final v in intel.vessels)
          {
            'name': v.vessel.name,
            'healthScore': v.health.score,
            'band': v.health.band.name,
            'portReadinessPercent': v.portReadinessPercent,
            'risks': [
              for (final r in v.risks.take(20))
                {
                  'severity': r.severity.name,
                  'category': r.category.name,
                  'rule': r.kind.name,
                  'subject': r.subject.length > 90
                      ? '${r.subject.substring(0, 90)}…'
                      : r.subject,
                  if (r.days != null) 'days': r.days,
                  if (r.count != null) 'count': r.count,
                }
            ],
          }
      ],
    };
  }
}
