class TankReading {
  final String vesselId;
  final String tankId;
  final double levelM3;
  final DateTime timestamp;

  const TankReading({
    required this.vesselId,
    required this.tankId,
    required this.levelM3,
    required this.timestamp,
  });

  String get storageKey => '$vesselId|$tankId|${timestamp.microsecondsSinceEpoch}';

  Map<String, dynamic> toMap() => {
        'vesselId': vesselId,
        'tankId': tankId,
        'levelM3': levelM3,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TankReading.fromMap(Map<dynamic, dynamic> map) => TankReading(
        vesselId: map['vesselId'] as String,
        tankId: map['tankId'] as String,
        levelM3: (map['levelM3'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
