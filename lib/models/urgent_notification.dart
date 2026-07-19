import '../services/clock.dart';

enum AlertType { fire, flooding, engineFailure, routing, other }

enum EscalationStatus { notAcknowledged, acknowledged, resolved }

/// Workflow state for a notification that has been turned into an assigned
/// management action (Request 9). Ordinary alerts leave this at [pending].
enum ActionStatus { pending, inProgress, completed }

class UrgentNotification {
  final String id;
  final String vesselId;
  final AlertType alertType;
  final String location;
  final String description;
  final DateTime timestamp;
  final EscalationStatus escalationStatus;

  // --- Assigned-action fields (Request 9). All optional so existing rows,
  // which never wrote these keys, still parse unchanged. ---

  /// When true this alert is also a task assigned to management, tracked with
  /// [assignee], [actionStatus] and [dueDate].
  final bool isAction;

  /// Who is responsible for the action (username or free-text name).
  final String? assignee;

  /// Task workflow state; only meaningful when [isAction] is true.
  final ActionStatus actionStatus;

  /// Optional deadline for the action.
  final DateTime? dueDate;

  /// Stamped when [actionStatus] becomes [ActionStatus.completed].
  final DateTime? completedAt;

  const UrgentNotification({
    required this.id,
    required this.vesselId,
    required this.alertType,
    required this.location,
    required this.description,
    required this.timestamp,
    required this.escalationStatus,
    this.isAction = false,
    this.assignee,
    this.actionStatus = ActionStatus.pending,
    this.dueDate,
    this.completedAt,
  });

  /// True when the action has a due date that has passed and is not yet done.
  bool get isOverdue =>
      isAction &&
      actionStatus != ActionStatus.completed &&
      dueDate != null &&
      dueDate!.isBefore(clockNow());

  UrgentNotification copyWith({
    AlertType? alertType,
    String? location,
    String? description,
    EscalationStatus? escalationStatus,
    bool? isAction,
    String? assignee,
    ActionStatus? actionStatus,
    DateTime? dueDate,
    DateTime? completedAt,
  }) =>
      UrgentNotification(
        id: id,
        vesselId: vesselId,
        alertType: alertType ?? this.alertType,
        location: location ?? this.location,
        description: description ?? this.description,
        timestamp: timestamp,
        escalationStatus: escalationStatus ?? this.escalationStatus,
        isAction: isAction ?? this.isAction,
        assignee: assignee ?? this.assignee,
        actionStatus: actionStatus ?? this.actionStatus,
        dueDate: dueDate ?? this.dueDate,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'alertType': alertType.name,
        'location': location,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'escalationStatus': escalationStatus.name,
        'isAction': isAction,
        if (assignee != null) 'assignee': assignee,
        'actionStatus': actionStatus.name,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  factory UrgentNotification.fromMap(Map<dynamic, dynamic> map) =>
      UrgentNotification(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        alertType:
            AlertType.values.byName((map['alertType'] as String?) ?? 'other'),
        location: (map['location'] as String?) ?? '',
        description: map['description'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        escalationStatus: EscalationStatus.values
            .byName((map['escalationStatus'] as String?) ?? 'notAcknowledged'),
        isAction: (map['isAction'] as bool?) ?? false,
        assignee: map['assignee'] as String?,
        actionStatus: ActionStatus.values
            .byName((map['actionStatus'] as String?) ?? 'pending'),
        dueDate: (map['dueDate'] as String?) != null
            ? DateTime.tryParse(map['dueDate'] as String)
            : null,
        completedAt: (map['completedAt'] as String?) != null
            ? DateTime.tryParse(map['completedAt'] as String)
            : null,
      );
}
