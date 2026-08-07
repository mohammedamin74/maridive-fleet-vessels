import '../models/fleet_intelligence.dart';
import 'clock.dart';

/// Turns detected risks into an explainable 0-100 vessel health score.
///
/// Deliberately *not* an average of raw record counts: each component starts
/// at 100 and loses points per risk by severity, the components are combined
/// with the spec's weights, and any CRITICAL risk caps the overall score so a
/// critical condition can never hide inside a healthy-looking average.
class VesselHealthService {
  const VesselHealthService._();

  /// Component weights (spec §5). Must sum to 100.
  static const Map<RiskCategory, int> weights = {
    RiskCategory.defects: 20,
    RiskCategory.maintenance: 20,
    RiskCategory.certificates: 15,
    RiskCategory.operational: 15,
    RiskCategory.requisitions: 10,
    RiskCategory.crew: 10,
    RiskCategory.portReadiness: 10,
  };

  /// Points removed from a component per risk of each severity. INFO risks
  /// (data quality) are surfaced to the user but never cost points.
  static const Map<RiskSeverity, int> penalties = {
    RiskSeverity.critical: 45,
    RiskSeverity.high: 25,
    RiskSeverity.medium: 12,
    RiskSeverity.low: 5,
    RiskSeverity.info: 0,
  };

  /// A vessel with any CRITICAL risk can never score above this.
  static const int criticalCap = 55;

  /// Each critical risk beyond the first lowers the cap further, so several
  /// vessels carrying criticals still rank against each other instead of all
  /// flattening onto the cap.
  static const int criticalCapStep = 4;

  /// However bad it gets, a capped score stays above zero — 0 would read as
  /// "no data" rather than "worst in the fleet".
  static const int criticalCapFloor = 8;

  static const int goodThreshold = 80;
  static const int attentionThreshold = 60;
  static const int highRiskThreshold = 40;

  static HealthBand bandFor(int score) {
    if (score >= goodThreshold) return HealthBand.good;
    if (score >= attentionThreshold) return HealthBand.attention;
    if (score >= highRiskThreshold) return HealthBand.highRisk;
    return HealthBand.critical;
  }

  static VesselHealth calculate({
    required String vesselId,
    required List<RiskEvent> risks,
  }) {
    // Each weighted component starts perfect and loses points per risk.
    final componentScores = <RiskCategory, int>{
      for (final category in weights.keys) category: 100,
    };
    for (final risk in risks) {
      final current = componentScores[risk.category];
      if (current == null) continue; // dataQuality is not weighted
      final penalty = penalties[risk.severity] ?? 0;
      componentScores[risk.category] = (current - penalty).clamp(0, 100);
    }

    var weighted = 0.0;
    for (final entry in weights.entries) {
      weighted += (componentScores[entry.key] ?? 100) * entry.value / 100;
    }
    var score = weighted.round().clamp(0, 100);

    final criticalCount =
        risks.where((r) => r.severity == RiskSeverity.critical).length;
    if (criticalCount > 0) {
      final cap = (criticalCap - criticalCapStep * (criticalCount - 1))
          .clamp(criticalCapFloor, criticalCap);
      if (score > cap) score = cap;
    }

    // Explanation: how many points each risk actually cost the overall
    // score, biggest first. A component already floored at 0 stops costing,
    // so deductions are attributed in severity order and capped at the real
    // total lost — the numbers shown always add up to 100 - score.
    final deductions = _explain(risks, score);

    return VesselHealth(
      vesselId: vesselId,
      score: score,
      band: bandFor(score),
      componentScores: componentScores,
      deductions: deductions,
      calculatedAt: clockNow(),
    );
  }

  static List<HealthDeduction> _explain(List<RiskEvent> risks, int score) {
    final scoring = risks
        .where((r) => (penalties[r.severity] ?? 0) > 0)
        .toList()
      ..sort((a, b) => a.severity.index.compareTo(b.severity.index));
    if (scoring.isEmpty) return const [];

    var remaining = 100 - score;
    final out = <HealthDeduction>[];
    for (final risk in scoring) {
      if (remaining <= 0) break;
      final weight = weights[risk.category] ?? 0;
      final raw = ((penalties[risk.severity] ?? 0) * weight / 100).round();
      final points = raw.clamp(1, remaining);
      out.add(HealthDeduction(points, risk));
      remaining -= points;
    }
    return out;
  }
}
