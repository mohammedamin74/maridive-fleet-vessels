import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/checklist_item.dart';
import '../models/daily_task.dart';

class DailyTasksProvider extends ChangeNotifier {
  final Box box;
  DailyTasksProvider({required this.box});

  List<DailyTask> forVessel(String vesselId) {
    final list = box.values
        .map((e) => DailyTask.fromMap(e as Map))
        .where((t) => t.vesselId == vesselId)
        .toList();
    list.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return list;
  }

  int overdueCountFor(String vesselId) =>
      forVessel(vesselId).where((t) => t.isOverdue).length;

  Future<void> add({
    required String vesselId,
    required TaskCategory category,
    required String title,
    required String assignedTo,
    required TaskFrequency frequency,
    required DateTime scheduledTime,
    required List<String> checklistLabels,
  }) async {
    final task = DailyTask(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      category: category,
      title: title,
      assignedTo: assignedTo,
      frequency: frequency,
      scheduledTime: scheduledTime,
      status: TaskStatus.pending,
      checklistItems:
          checklistLabels.map((l) => ChecklistItem(label: l)).toList(),
      photosBase64: const [],
      createdAt: DateTime.now(),
    );
    await box.put(task.id, task.toMap());
    notifyListeners();
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    final raw = box.get(id);
    if (raw == null) return;
    final task = DailyTask.fromMap(raw as Map).copyWith(status: status);
    await box.put(id, task.toMap());
    notifyListeners();
  }

  Future<void> toggleChecklistItem(String id, int index, bool checked) async {
    final raw = box.get(id);
    if (raw == null) return;
    final task = DailyTask.fromMap(raw as Map);
    final updated = List<ChecklistItem>.from(task.checklistItems);
    updated[index] = updated[index].copyWith(checked: checked);
    await box.put(id, task.copyWith(checklistItems: updated).toMap());
    notifyListeners();
  }

  Future<void> setChecklistComment(String id, int index, String comment) async {
    final raw = box.get(id);
    if (raw == null) return;
    final task = DailyTask.fromMap(raw as Map);
    final updated = List<ChecklistItem>.from(task.checklistItems);
    updated[index] = updated[index].copyWith(comment: comment);
    await box.put(id, task.copyWith(checklistItems: updated).toMap());
    notifyListeners();
  }

  Future<void> addPhoto(String id, String photoBase64) async {
    final raw = box.get(id);
    if (raw == null) return;
    final task = DailyTask.fromMap(raw as Map);
    final updated = List<String>.from(task.photosBase64)..add(photoBase64);
    await box.put(id, task.copyWith(photosBase64: updated).toMap());
    notifyListeners();
  }

  Future<void> removePhoto(String id, int index) async {
    final raw = box.get(id);
    if (raw == null) return;
    final task = DailyTask.fromMap(raw as Map);
    final updated = List<String>.from(task.photosBase64)..removeAt(index);
    await box.put(id, task.copyWith(photosBase64: updated).toMap());
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await box.delete(id);
    notifyListeners();
  }
}
