import 'attachment.dart';

/// A vessel specification document entry — a titled record holding one or
/// more uploaded spec files of any format (general arrangement, capacity
/// plan, stability booklet, class drawings, technical manuals, …). Acts as
/// the vessel's specifications document library.
class VesselSpec {
  final String id;
  final String vesselId;
  final String title;
  final String notes;
  final List<Attachment> attachments;
  final DateTime createdAt;

  const VesselSpec({
    required this.id,
    required this.vesselId,
    required this.title,
    required this.notes,
    required this.attachments,
    required this.createdAt,
  });

  VesselSpec copyWith(
          {String? title, String? notes, List<Attachment>? attachments}) =>
      VesselSpec(
        id: id,
        vesselId: vesselId,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'title': title,
        'notes': notes,
        'attachments': Attachment.listToMap(attachments),
        'createdAt': createdAt.toIso8601String(),
      };

  factory VesselSpec.fromMap(Map<dynamic, dynamic> map) => VesselSpec(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        title: map['title'] as String,
        notes: (map['notes'] as String?) ?? '',
        attachments: Attachment.listFromMap(map),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
