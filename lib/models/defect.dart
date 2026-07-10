enum DefectPriority { low, medium, high, critical }

enum DefectStatus { open, inProgress, closed }

enum DefectLocation { engineRoom, deck, bridge, accommodation, galley, other }

class Defect {
  final String id;
  final String vesselId;
  final String title;
  final String description;
  final DefectLocation location;
  final DefectPriority priority;
  final DefectStatus status;
  final String assignedOfficer;
  final String requiredSpareParts;
  final String actionTaken;
  final List<String> photosBase64;
  final DateTime reportedAt;

  const Defect({
    required this.id,
    required this.vesselId,
    required this.title,
    required this.description,
    required this.location,
    required this.priority,
    required this.status,
    required this.assignedOfficer,
    required this.requiredSpareParts,
    required this.actionTaken,
    required this.photosBase64,
    required this.reportedAt,
  });

  Defect copyWith(
          {DefectStatus? status,
          String? actionTaken,
          List<String>? photosBase64}) =>
      Defect(
        id: id,
        vesselId: vesselId,
        title: title,
        description: description,
        location: location,
        priority: priority,
        status: status ?? this.status,
        assignedOfficer: assignedOfficer,
        requiredSpareParts: requiredSpareParts,
        actionTaken: actionTaken ?? this.actionTaken,
        photosBase64: photosBase64 ?? this.photosBase64,
        reportedAt: reportedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'title': title,
        'description': description,
        'location': location.name,
        'priority': priority.name,
        'status': status.name,
        'assignedOfficer': assignedOfficer,
        'requiredSpareParts': requiredSpareParts,
        'actionTaken': actionTaken,
        'photosBase64': photosBase64,
        'reportedAt': reportedAt.toIso8601String(),
      };

  factory Defect.fromMap(Map<dynamic, dynamic> map) => Defect(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        location: DefectLocation.values
            .byName((map['location'] as String?) ?? 'other'),
        priority:
            DefectPriority.values.byName((map['priority'] as String?) ?? 'low'),
        status: DefectStatus.values.byName(map['status'] as String),
        assignedOfficer: (map['assignedOfficer'] as String?) ?? '',
        requiredSpareParts: (map['requiredSpareParts'] as String?) ?? '',
        actionTaken: (map['actionTaken'] as String?) ?? '',
        photosBase64: ((map['photosBase64'] as List?) ?? []).cast<String>(),
        reportedAt: DateTime.parse(map['reportedAt'] as String),
      );
}
