enum TankCategory { fuelOil, brineMud, lubeHydraulic, other }

class Tank {
  final String id;
  final String name;
  final TankCategory category;
  final double capacityM3;
  final double currentM3;

  const Tank({
    required this.id,
    required this.name,
    required this.category,
    required this.capacityM3,
    required this.currentM3,
  });

  /// Simple linear sounding table: level(cm) -> volume(m3), derived from
  /// capacity assuming a 250cm tall tank profile. Good enough to demo the
  /// sounding-table feature without hardware-specific calibration data.
  List<({int levelCm, double volumeM3})> soundingTable() {
    const maxHeightCm = 250;
    const steps = 10;
    return List.generate(steps + 1, (i) {
      final levelCm = (maxHeightCm / steps * i).round();
      final volume = capacityM3 * (levelCm / maxHeightCm);
      return (
        levelCm: levelCm,
        volumeM3: double.parse(volume.toStringAsFixed(1))
      );
    });
  }
}
