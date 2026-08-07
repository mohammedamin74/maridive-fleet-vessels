import 'attachment.dart';
import '../services/clock.dart';

enum ActionPriority { critical, high, medium, low }

/// Workflow of a superintendent action item. Waiting states record which
/// side (vessel or office) the ball is with.
enum SuperActionStatus {
  open,
  inProgress,
  waitingVessel,
  waitingOffice,
  completed,
  cancelled,
}

/// Sentinel distinguishing "leave unchanged" from "explicitly clear to null"
/// in [SuperintendentAction.copyWith].
const Object _unset = Object();

/// One actionable task in the Superintendent Action Center — usually created
/// from a detected risk (keeping its source module + record id as evidence),
/// or added manually. Persisted via CloudStore('superintendent_actions').
class SuperintendentAction {
  final String id;
  final String vesselId;
  final String title;
  final String description;
  final String recommendation;
  final ActionPriority priority;
  final SuperActionStatus status;
  final String sourceType; // module slug ('' when created manually)
  final String sourceId;
  final String assignedTo;
  final DateTime? dueDate;
  final String notes;
  final List<Attachment> attachments;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SuperintendentAction({
    required this.id,
    required this.vesselId,
    required this.title,
    this.description = '',
    this.recommendation = '',
    this.priority = ActionPriority.medium,
    this.status = SuperActionStatus.open,
    this.sourceType = '',
    this.sourceId = '',
    this.assignedTo = '',
    this.dueDate,
    this.notes = '',
    this.attachments = const [],
    this.createdBy = '',
    required this.createdAt,
    this.completedAt,
  });

  bool get isOverdue =>
      dueDate != null &&
      status != SuperActionStatus.completed &&
      status != SuperActionStatus.cancelled &&
      dueDate!.isBefore(clockNow());

  SuperintendentAction copyWith({
    String? title,
    String? description,
    String? recommendation,
    ActionPriority? priority,
    SuperActionStatus? status,
    String? assignedTo,
    Object? dueDate = _unset,
    String? notes,
    List<Attachment>? attachments,
    Object? completedAt = _unset,
  }) =>
      SuperintendentAction(
        id: id,
        vesselId: vesselId,
        title: title ?? this.title,
        description: description ?? this.description,
        recommendation: recommendation ?? this.recommendation,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        sourceType: sourceType,
        sourceId: sourceId,
        assignedTo: assignedTo ?? this.assignedTo,
        dueDate: dueDate == _unset ? this.dueDate : dueDate as DateTime?,
        notes: notes ?? this.notes,
        attachments: attachments ?? this.attachments,
        createdBy: createdBy,
        createdAt: createdAt,
        completedAt:
            completedAt == _unset ? this.completedAt : completedAt as DateTime?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'title': title,
        'description': description,
        'recommendation': recommendation,
        'priority': priority.name,
        'status': status.name,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'assignedTo': assignedTo,
        'dueDate': dueDate?.toIso8601String(),
        'notes': notes,
        'attachments': Attachment.listToMap(attachments),
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory SuperintendentAction.fromMap(Map<dynamic, dynamic> map) =>
      SuperintendentAction(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        title: (map['title'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        recommendation: (map['recommendation'] as String?) ?? '',
        priority: ActionPriority.values
                .asNameMap()[(map['priority'] as String?) ?? ''] ??
            ActionPriority.medium,
        status:
            SuperActionStatus.values.asNameMap()[(map['status'] as String?) ?? ''] ??
                SuperActionStatus.open,
        sourceType: (map['sourceType'] as String?) ?? '',
        sourceId: (map['sourceId'] as String?) ?? '',
        assignedTo: (map['assignedTo'] as String?) ?? '',
        dueDate: DateTime.tryParse((map['dueDate'] as String?) ?? ''),
        notes: (map['notes'] as String?) ?? '',
        attachments: Attachment.listFromMap(map),
        createdBy: (map['createdBy'] as String?) ?? '',
        createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        completedAt: DateTime.tryParse((map['completedAt'] as String?) ?? ''),
      );
}
