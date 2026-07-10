import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/urgent_notification.dart';

class UrgentNotificationProvider extends ChangeNotifier {
  final Box box;
  UrgentNotificationProvider({required this.box});

  List<UrgentNotification> forVessel(String vesselId) {
    final list = box.values
        .map((e) => UrgentNotification.fromMap(e as Map))
        .where((n) => n.vesselId == vesselId)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<UrgentNotification> unacknowledgedFleetWide(List<String> vesselIds) {
    final list = box.values
        .map((e) => UrgentNotification.fromMap(e as Map))
        .where((n) =>
            vesselIds.contains(n.vesselId) &&
            n.escalationStatus == EscalationStatus.notAcknowledged)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> add({
    required String vesselId,
    required AlertType alertType,
    required String location,
    required String description,
  }) async {
    final notification = UrgentNotification(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      alertType: alertType,
      location: location,
      description: description,
      timestamp: DateTime.now(),
      escalationStatus: EscalationStatus.notAcknowledged,
    );
    await box.put(notification.id, notification.toMap());
    notifyListeners();
  }

  Future<void> updateStatus(String id, EscalationStatus status) async {
    final raw = box.get(id);
    if (raw == null) return;
    final notification = UrgentNotification.fromMap(raw as Map)
        .copyWith(escalationStatus: status);
    await box.put(id, notification.toMap());
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await box.delete(id);
    notifyListeners();
  }
}
