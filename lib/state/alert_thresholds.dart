/// Default fill-level thresholds used to flag tanks needing attention.
/// A tank with no reading yet is treated as "no data", not as critical —
/// zero readings shouldn't be confused with an actually empty tank.
class AlertThresholds {
  AlertThresholds._();

  static const double lowCritical = 0.15;
  static const double lowWarning = 0.30;
  static const double highWarning = 0.90;
  static const double highCritical = 0.97;
}

enum TankLevelStatus {
  noData,
  critical,
  warning,
  normal,
  highWarning,
  highCritical
}

TankLevelStatus levelStatusFor(
    {required bool hasReading, required double percent}) {
  if (!hasReading) return TankLevelStatus.noData;
  if (percent < AlertThresholds.lowCritical) return TankLevelStatus.critical;
  if (percent < AlertThresholds.lowWarning) return TankLevelStatus.warning;
  if (percent >= AlertThresholds.highCritical) {
    return TankLevelStatus.highCritical;
  }
  if (percent >= AlertThresholds.highWarning) {
    return TankLevelStatus.highWarning;
  }
  return TankLevelStatus.normal;
}
