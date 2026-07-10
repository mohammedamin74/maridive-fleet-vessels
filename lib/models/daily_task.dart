import 'checklist_item.dart';

enum TaskCategory {
  engineRoomRounds,
  deckRounds,
  safetyEquipmentChecks,
  navigationEquipmentTests,
  galleyHygieneInspections
}

enum TaskFrequency { daily, everyWatch, weekly }

enum TaskStatus { pending, inProgress, completed }

class DailyTask {
  final String id;
  final String vesselId;
  final TaskCategory category;
  final String title;
  final String assignedTo;
  final TaskFrequency frequency;
  final DateTime scheduledTime;
  final TaskStatus status;
  final List<ChecklistItem> checklistItems;
  final List<String> photosBase64;
  final DateTime createdAt;

  const DailyTask({
    required this.id,
    required this.vesselId,
    required this.category,
    required this.title,
    required this.assignedTo,
    required this.frequency,
    required this.scheduledTime,
    required this.status,
    required this.checklistItems,
    required this.photosBase64,
    required this.createdAt,
  });

  /// Overdue is derived rather than stored: a task that's still pending or
  /// in progress after its scheduled time has passed is overdue. This
  /// avoids needing a background job to flip a stored status.
  bool get isOverdue =>
      status != TaskStatus.completed && DateTime.now().isAfter(scheduledTime);

  DailyTask copyWith({
    TaskStatus? status,
    List<ChecklistItem>? checklistItems,
    List<String>? photosBase64,
  }) =>
      DailyTask(
        id: id,
        vesselId: vesselId,
        category: category,
        title: title,
        assignedTo: assignedTo,
        frequency: frequency,
        scheduledTime: scheduledTime,
        status: status ?? this.status,
        checklistItems: checklistItems ?? this.checklistItems,
        photosBase64: photosBase64 ?? this.photosBase64,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'category': category.name,
        'title': title,
        'assignedTo': assignedTo,
        'frequency': frequency.name,
        'scheduledTime': scheduledTime.toIso8601String(),
        'status': status.name,
        'checklistItems': checklistItems.map((c) => c.toMap()).toList(),
        'photosBase64': photosBase64,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DailyTask.fromMap(Map<dynamic, dynamic> map) => DailyTask(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        category: TaskCategory.values
            .byName((map['category'] as String?) ?? 'engineRoomRounds'),
        title: map['title'] as String,
        assignedTo: (map['assignedTo'] as String?) ?? '',
        frequency: TaskFrequency.values
            .byName((map['frequency'] as String?) ?? 'daily'),
        scheduledTime: DateTime.parse(map['scheduledTime'] as String),
        status:
            TaskStatus.values.byName((map['status'] as String?) ?? 'pending'),
        checklistItems: ((map['checklistItems'] as List?) ?? [])
            .map((e) => ChecklistItem.fromMap(e as Map))
            .toList(),
        photosBase64: ((map['photosBase64'] as List?) ?? []).cast<String>(),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
