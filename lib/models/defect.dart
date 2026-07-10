enum DefectSeverity { minor, major, critical }

enum DefectStatus { open, inProgress, closed }

class Defect {
  final String id;
  final String vesselId;
  final String title;
  final String description;
  final DefectSeverity severity;
  final DefectStatus status;
  final DateTime reportedAt;

  const Defect({
    required this.id,
    required this.vesselId,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.reportedAt,
  });

  Defect copyWith({DefectStatus? status}) => Defect(
        id: id,
        vesselId: vesselId,
        title: title,
        description: description,
        severity: severity,
        status: status ?? this.status,
        reportedAt: reportedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'title': title,
        'description': description,
        'severity': severity.name,
        'status': status.name,
        'reportedAt': reportedAt.toIso8601String(),
      };

  factory Defect.fromMap(Map<dynamic, dynamic> map) => Defect(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        severity: DefectSeverity.values.byName(map['severity'] as String),
        status: DefectStatus.values.byName(map['status'] as String),
        reportedAt: DateTime.parse(map['reportedAt'] as String),
      );
}
