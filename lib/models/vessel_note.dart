import 'attachment.dart';

class VesselNote {
  final String id;
  final String vesselId;
  final String text;
  final List<Attachment> attachments;
  final DateTime timestamp;

  const VesselNote({
    required this.id,
    required this.vesselId,
    required this.text,
    this.attachments = const [],
    required this.timestamp,
  });

  VesselNote copyWith({List<Attachment>? attachments}) => VesselNote(
        id: id,
        vesselId: vesselId,
        text: text,
        attachments: attachments ?? this.attachments,
        timestamp: timestamp,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'text': text,
        'attachments': Attachment.listToMap(attachments),
        'timestamp': timestamp.toIso8601String(),
      };

  factory VesselNote.fromMap(Map<dynamic, dynamic> map) => VesselNote(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        text: map['text'] as String,
        attachments: Attachment.listFromMap(map),
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
