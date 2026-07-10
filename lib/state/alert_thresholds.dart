/// Default fill-level thresholds used to flag tanks needing attention.
/// A tank with no reading yet is treated as "no data", not as critical —
/// zero readings shouldn't be confused with an actually empty tank.
class AlertThresholds {
  AlertThresholds._();

  static const double critical = 0.15;
  static const double warning = 0.30;
}

enum TankLevelStatus { noData, critical, warning, normal }

TankLevelStatus levelStatusFor({required bool hasReading, required double percent}) {
  if (!hasReading) return TankLevelStatus.noData;
  if (percent < AlertThresholds.critical) return TankLevelStatus.critical;
  if (percent < AlertThresholds.warning) return TankLevelStatus.warning;
  return TankLevelStatus.normal;
}
