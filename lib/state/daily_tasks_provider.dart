import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment.dart';
import '../models/checklist_item.dart';
import '../models/daily_task.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed daily tasks. Records live in the shared Supabase table so every
/// device sees the same tasks. An in-memory cache is loaded on login (and
/// refreshed after writes) and exposed synchronously to the UI.
class DailyTasksProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('daily_tasks');
  List<DailyTask> _all = [];

  DailyTasksProvider() {
    _load();
    SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
          _load();
          break;
        case AuthChangeEvent.signedOut:
          _all = [];
          notifyListeners();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _load() async {
    try {
      final maps = await _store.fetchAll();
      _all = maps.map(DailyTask.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  List<DailyTask> forVessel(String vesselId) {
    final list = _all.where((t) => t.vesselId == vesselId).toList();
    list.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return list;
  }

  int overdueCountFor(String vesselId) =>
      forVessel(vesselId).where((t) => t.isOverdue).length;

  Future<void> _save(DailyTask task) async {
    final idx = _all.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      _all[idx] = task;
    } else {
      _all = [..._all, task];
    }
    notifyListeners();
    await _store.put(task.id, task.vesselId, task.toMap());
  }

  DailyTask? _byId(String id) {
    for (final t in _all) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> add({
    required String vesselId,
    required TaskCategory category,
    required String title,
    required String assignedTo,
    required TaskFrequency frequency,
    required DateTime scheduledTime,
    required List<String> checklistLabels,
  }) async {
    await _save(DailyTask(
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
      attachments: const [],
      createdAt: DateTime.now(),
    ));
  }

  Future<void> update({
    required String id,
    required TaskCategory category,
    required String title,
    required String assignedTo,
    required TaskFrequency frequency,
    required DateTime scheduledTime,
  }) async {
    final task = _byId(id);
    if (task == null) return;
    await _save(task.copyWith(
      category: category,
      title: title,
      assignedTo: assignedTo,
      frequency: frequency,
      scheduledTime: scheduledTime,
    ));
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    final task = _byId(id);
    if (task == null) return;
    await _save(task.copyWith(status: status));
  }

  Future<void> toggleChecklistItem(String id, int index, bool checked) async {
    final task = _byId(id);
    if (task == null) return;
    final updated = List<ChecklistItem>.from(task.checklistItems);
    updated[index] = updated[index].copyWith(checked: checked);
    await _save(task.copyWith(checklistItems: updated));
  }

  Future<void> setChecklistComment(String id, int index, String comment) async {
    final task = _byId(id);
    if (task == null) return;
    final updated = List<ChecklistItem>.from(task.checklistItems);
    updated[index] = updated[index].copyWith(comment: comment);
    await _save(task.copyWith(checklistItems: updated));
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final task = _byId(id);
    if (task == null) return;
    final updated = List<Attachment>.from(task.attachments)..add(attachment);
    await _save(task.copyWith(attachments: updated));
  }

  Future<void> removeAttachment(String id, int index) async {
    final task = _byId(id);
    if (task == null) return;
    final updated = List<Attachment>.from(task.attachments)..removeAt(index);
    await _save(task.copyWith(attachments: updated));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((t) => t.id == id);
    notifyListeners();
    await _store.remove(id);
  }
}
