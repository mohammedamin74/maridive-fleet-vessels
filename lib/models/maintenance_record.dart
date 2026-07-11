import 'attachment.dart';

enum MaintenanceStatus { planned, inProgress, completed }

/// A maintenance job logged against a vessel — planned, in-progress, or
/// completed work — with any-format file evidence (reports, photos, PDFs,
/// spreadsheets, …) attached.
class MaintenanceRecord {
  final String id;
  final String vesselId;
  final String title;
  final String description;
  final String performedBy;
  final DateTime dueDate;
  final MaintenanceStatus status;
  final List<Attachment> attachments;
  final DateTime createdAt;

  const MaintenanceRecord({
    required this.id,
    required this.vesselId,
    required this.title,
    required this.description,
    required this.performedBy,
    required this.dueDate,
    required this.status,
    required this.attachments,
    required this.createdAt,
  });

  MaintenanceRecord copyWith({
    MaintenanceStatus? status,
    List<Attachment>? attachments,
  }) =>
      MaintenanceRecord(
        id: id,
        vesselId: vesselId,
        title: title,
        description: description,
        performedBy: performedBy,
        dueDate: dueDate,
        status: status ?? this.status,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'title': title,
        'description': description,
        'performedBy': performedBy,
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'attachments': Attachment.listToMap(attachments),
        'createdAt': createdAt.toIso8601String(),
      };

  factory MaintenanceRecord.fromMap(Map<dynamic, dynamic> map) =>
      MaintenanceRecord(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        title: map['title'] as String,
        description: (map['description'] as String?) ?? '',
        performedBy: (map['performedBy'] as String?) ?? '',
        dueDate: DateTime.parse(map['dueDate'] as String),
        status: MaintenanceStatus.values
            .byName((map['status'] as String?) ?? 'planned'),
        attachments: Attachment.listFromMap(map),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
