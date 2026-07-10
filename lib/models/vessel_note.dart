class VesselNote {
  final String id;
  final String vesselId;
  final String text;
  final DateTime timestamp;

  const VesselNote({
    required this.id,
    required this.vesselId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory VesselNote.fromMap(Map<dynamic, dynamic> map) => VesselNote(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        text: map['text'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
