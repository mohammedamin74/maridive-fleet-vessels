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
  }) async {
    await _save(UrgentNotification(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      alertType: alertType,
      location: location,
      description: description,
      timestamp: DateTime.now(),
      escalationStatus: EscalationStatus.notAcknowledged,
    ));
  }

  Future<void> updateStatus(String id, EscalationStatus status) async {
    UrgentNotification? current;
    for (final n in _all) {
      if (n.id == id) {
        current = n;
        break;
      }
    }
    if (current == null) return;
    await _save(current.copyWith(escalationStatus: status));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((n) => n.id == id);
    notifyListeners();
    await _store.remove(id);
  }
}
