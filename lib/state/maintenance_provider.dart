import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/attachment.dart';
import '../models/maintenance_record.dart';

class MaintenanceProvider extends ChangeNotifier {
  final Box box;
  MaintenanceProvider({required this.box});

  List<MaintenanceRecord> forVessel(String vesselId) {
    final list = box.values
        .map((e) => MaintenanceRecord.fromMap(e as Map))
        .where((m) => m.vesselId == vesselId)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int openCountFor(String vesselId) => forVessel(vesselId)
      .where((m) => m.status != MaintenanceStatus.completed)
      .length;

  Future<void> add({
    required String vesselId,
    required String title,
    required String description,
    required String performedBy,
    required DateTime dueDate,
    List<Attachment> attachments = const [],
  }) async {
    final record = MaintenanceRecord(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      title: title,
      description: description,
      performedBy: performedBy,
      dueDate: dueDate,
      status: MaintenanceStatus.planned,
      attachments: attachments,
      createdAt: DateTime.now(),
    );
    await box.put(record.id, record.toMap());
    notifyListeners();
  }

  Future<void> updateStatus(String id, MaintenanceStatus status) async {
    final raw = box.get(id);
    if (raw == null) return;
    final record = MaintenanceRecord.fromMap(raw as Map).copyWith(status: status);
    await box.put(id, record.toMap());
    notifyListeners();
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final raw = box.get(id);
    if (raw == null) return;
    final record = MaintenanceRecord.fromMap(raw as Map);
    await box.put(
        id,
        record.copyWith(
            attachments: [...record.attachments, attachment]).toMap());
    notifyListeners();
  }

  Future<void> removeAttachment(String id, int index) async {
    final raw = box.get(id);
    if (raw == null) return;
    final record = MaintenanceRecord.fromMap(raw as Map);
    final files = [...record.attachments]..removeAt(index);
    await box.put(id, record.copyWith(attachments: files).toMap());
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await box.delete(id);
    notifyListeners();
  }
}
