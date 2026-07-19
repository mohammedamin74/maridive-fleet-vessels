class TankReading {
  final String vesselId;
  final String tankId;
  final double levelM3;
  final double? temperatureC;
  final DateTime timestamp;

  const TankReading({
    required this.vesselId,
    required this.tankId,
    required this.levelM3,
    this.temperatureC,
    required this.timestamp,
  });

  String get storageKey =>
      '$vesselId|$tankId|${timestamp.microsecondsSinceEpoch}';

  /// Only levelM3/temperatureC are editable — vesselId/tankId/timestamp make
  /// up [storageKey], the row's identity in Storage, so changing them here
  /// would silently create a new row instead of updating this one.
  TankReading copyWith({double? levelM3, double? temperatureC}) => TankReading(
        vesselId: vesselId,
        tankId: tankId,
        levelM3: levelM3 ?? this.levelM3,
        temperatureC: temperatureC ?? this.temperatureC,
        timestamp: timestamp,
      );

  Map<String, dynamic> toMap() => {
        'vesselId': vesselId,
        'tankId': tankId,
        'levelM3': levelM3,
        'temperatureC': temperatureC,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TankReading.fromMap(Map<dynamic, dynamic> map) => TankReading(
        vesselId: map['vesselId'] as String,
        tankId: map['tankId'] as String,
        levelM3: (map['levelM3'] as num).toDouble(),
        temperatureC: (map['temperatureC'] as num?)?.toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
