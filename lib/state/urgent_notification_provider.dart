import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/urgent_notification.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed urgent notifications. Records live in the shared Supabase table
/// so every device sees the same alerts. An in-memory cache is loaded on login
/// (and refreshed after writes) and exposed synchronously to the UI.
class UrgentNotificationProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('urgent_notifications');
  List<UrgentNotification> _all = [];

  UrgentNotificationProvider() {
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
      _all = maps.map(UrgentNotification.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  List<UrgentNotification> forVessel(String vesselId) {
    final list = _all.where((n) => n.vesselId == vesselId).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<UrgentNotification> unacknowledgedFleetWide(List<String> vesselIds) {
    final list = _all
        .where((n) =>
            vesselIds.contains(n.vesselId) &&
            n.escalationStatus == EscalationStatus.notAcknowledged)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> _save(UrgentNotification notification) async {
    final idx = _all.indexWhere((n) => n.id == notification.id);
    if (idx >= 0) {
      _all[idx] = notification;
    } else {
      _all = [..._all, notification];
    }
    notifyListeners();
    await _store.put(notification.id, notification.vesselId, notification.toMap());
  }

  Future<void> add({
    required String vesselId,
    required AlertType alertType,
    required String location,
    required String description,
    bool isAction = false,
    String? assignee,
    DateTime? dueDate,
  }) async {
    await _save(UrgentNotification(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      alertType: alertType,
      location: location,
      description: description,
      timestamp: DateTime.now(),
      escalationStatus: EscalationStatus.notAcknowledged,
      isAction: isAction,
      assignee: assignee,
      actionStatus: ActionStatus.pending,
      dueDate: dueDate,
    ));
  }

  UrgentNotification? _byId(String id) {
    for (final n in _all) {
      if (n.id == id) return n;
    }
    return null;
  }

  Future<void> update({
    required String id,
    required AlertType alertType,
    required String location,
    required String description,
    bool isAction = false,
    String? assignee,
    DateTime? dueDate,
  }) async {
    final current = _byId(id);
    if (current == null) return;
    await _save(current.copyWith(
      alertType: alertType,
      location: location,
      description: description,
      isAction: isAction,
      assignee: assignee,
      dueDate: dueDate,
    ));
  }

  Future<void> updateStatus(String id, EscalationStatus status) async {
    final current = _byId(id);
    if (current == null) return;
    await _save(current.copyWith(escalationStatus: status));
  }

  /// Transition an assigned action's workflow state, stamping [completedAt]
  /// when it is marked completed.
  Future<void> updateActionStatus(String id, ActionStatus status) async {
    final current = _byId(id);
    if (current == null) return;
    await _save(current.copyWith(
      actionStatus: status,
      completedAt:
          status == ActionStatus.completed ? DateTime.now() : current.completedAt,
    ));
  }

  /// Assign (or re-assign) an alert as a management action.
  Future<void> assignAction(String id,
      {required String assignee, DateTime? dueDate}) async {
    final current = _byId(id);
    if (current == null) return;
    await _save(current.copyWith(
      isAction: true,
      assignee: assignee,
      dueDate: dueDate,
    ));
  }

  /// All management actions for a vessel, most recent first.
  List<UrgentNotification> actionsForVessel(String vesselId) {
    final list =
        _all.where((n) => n.vesselId == vesselId && n.isAction).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Fleet-wide open actions assigned to [assignee] ("My Tasks").
  List<UrgentNotification> myTasks(String assignee, List<String> vesselIds) {
    final list = _all
        .where((n) =>
            n.isAction &&
            n.assignee == assignee &&
            vesselIds.contains(n.vesselId) &&
            n.actionStatus != ActionStatus.completed)
        .toList();
    list.sort((a, b) {
      // Overdue and soonest-due first; undated actions last.
      final ad = a.dueDate, bd = b.dueDate;
      if (ad == null && bd == null) return b.timestamp.compareTo(a.timestamp);
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return list;
  }

  /// Count of overdue actions across the given vessels (for badges).
  int overdueCount(List<String> vesselIds) => _all
      .where((n) => vesselIds.contains(n.vesselId) && n.isOverdue)
      .length;

  Future<void> delete(String id) async {
    _all.removeWhere((n) => n.id == id);
    notifyListeners();
    await _store.remove(id);
  }
}
