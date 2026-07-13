import 'attachment.dart';

/// Workflow state of a single port-arrival requirement.
enum RequirementStatus { pending, ready }

/// Grouping for a requirement, used for filtering and labelling.
enum RequirementCategory {
  documents,
  customs,
  health,
  security,
  provisions,
  other,
}

/// A single "Vessel Requirement Upon Arriving at Port" (Request 8): a titled,
/// categorised item — usually with one or more attached files (PDF, Word, …) —
/// that must be ready before the vessel arrives at a given port.
class PortRequirement {
  final String id;
  final String vesselId;
  final String title;
  final String portName; // optional; '' when general
  final RequirementCategory category;
  final RequirementStatus status;
  final String notes;
  final List<Attachment> attachments;
  final DateTime createdAt;

  const PortRequirement({
    required this.id,
    required this.vesselId,
    required this.title,
    this.portName = '',
    this.category = RequirementCategory.documents,
    this.status = RequirementStatus.pending,
    this.notes = '',
    this.attachments = const [],
    required this.createdAt,
  });

  PortRequirement copyWith({
    String? title,
    String? portName,
    RequirementCategory? category,
    RequirementStatus? status,
    String? notes,
    List<Attachment>? attachments,
  }) =>
      PortRequirement(
        id: id,
        vesselId: vesselId,
        title: title ?? this.title,
        portName: portName ?? this.portName,
        category: category ?? this.category,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'title': title,
        'portName': portName,
        'category': category.name,
        'status': status.name,
        'notes': notes,
        'attachments': Attachment.listToMap(attachments),
        'createdAt': createdAt.toIso8601String(),
      };

  factory PortRequirement.fromMap(Map<dynamic, dynamic> map) => PortRequirement(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        title: (map['title'] as String?) ?? '',
        portName: (map['portName'] as String?) ?? '',
        category: RequirementCategory.values
            .byName((map['category'] as String?) ?? 'documents'),
        status: RequirementStatus.values
            .byName((map['status'] as String?) ?? 'pending'),
        notes: (map['notes'] as String?) ?? '',
        attachments: Attachment.listFromMap(map),
        createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
