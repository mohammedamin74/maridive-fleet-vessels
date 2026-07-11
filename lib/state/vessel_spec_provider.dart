import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/attachment.dart';
import '../models/vessel_spec.dart';

class VesselSpecProvider extends ChangeNotifier {
  final Box box;
  VesselSpecProvider({required this.box});

  List<VesselSpec> forVessel(String vesselId) {
    final list = box.values
        .map((e) => VesselSpec.fromMap(e as Map))
        .where((s) => s.vesselId == vesselId)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int countFor(String vesselId) =>
      box.values.where((e) => (e as Map)['vesselId'] == vesselId).length;

  Future<void> add({
    required String vesselId,
    required String title,
    required String notes,
    List<Attachment> attachments = const [],
  }) async {
    final spec = VesselSpec(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      title: title,
      notes: notes,
      attachments: attachments,
      createdAt: DateTime.now(),
    );
    await box.put(spec.id, spec.toMap());
    notifyListeners();
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final raw = box.get(id);
    if (raw == null) return;
    final spec = VesselSpec.fromMap(raw as Map);
    await box.put(id,
        spec.copyWith(attachments: [...spec.attachments, attachment]).toMap());
    notifyListeners();
  }

  Future<void> removeAttachment(String id, int index) async {
    final raw = box.get(id);
    if (raw == null) return;
    final spec = VesselSpec.fromMap(raw as Map);
    final files = [...spec.attachments]..removeAt(index);
    await box.put(id, spec.copyWith(attachments: files).toMap());
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await box.delete(id);
    notifyListeners();
  }
}
