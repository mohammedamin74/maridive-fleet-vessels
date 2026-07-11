import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/attachment.dart';
import '../models/checklist_item.dart';
import '../models/port_call.dart';

class PortCallProvider extends ChangeNotifier {
  final Box box;
  PortCallProvider({required this.box});

  List<PortCall> forVessel(String vesselId) {
    final list = box.values
        .map((e) => PortCall.fromMap(e as Map))
        .where((p) => p.vesselId == vesselId)
        .toList();
    list.sort((a, b) => a.arrivalEta.compareTo(b.arrivalEta));
    return list;
  }

  Future<void> add({
    required String vesselId,
    required String portName,
    required DateTime arrivalEta,
    DateTime? pilotBoardingTime,
    String agentName = '',
    String agentContact = '',
    double bunkersMgoRequired = 0,
    double bunkersHfoRequired = 0,
    double freshWaterRequired = 0,
    String provisionsRequired = '',
    bool sludgeDisposalRequired = false,
    double sludgeQuantity = 0,
  }) async {
    final call = PortCall(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      portName: portName,
      arrivalEta: arrivalEta,
      pilotBoardingTime: pilotBoardingTime,
      agentName: agentName,
      agentContact: agentContact,
      bunkersMgoRequired: bunkersMgoRequired,
      bunkersHfoRequired: bunkersHfoRequired,
      freshWaterRequired: freshWaterRequired,
      provisionsRequired: provisionsRequired,
      sludgeDisposalRequired: sludgeDisposalRequired,
      sludgeQuantity: sludgeQuantity,
      customsChecklist: defaultCustomsChecklistLabels
          .map((l) => ChecklistItem(label: l))
          .toList(),
      status: PortCallStatus.upcoming,
      createdAt: DateTime.now(),
    );
    await box.put(call.id, call.toMap());
    notifyListeners();
  }

  Future<void> toggleChecklistItem(String id, int index, bool checked) async {
    final raw = box.get(id);
    if (raw == null) return;
    final call = PortCall.fromMap(raw as Map);
    final updated = List<ChecklistItem>.from(call.customsChecklist);
    updated[index] = updated[index].copyWith(checked: checked);
    await box.put(id, call.copyWith(customsChecklist: updated).toMap());
    notifyListeners();
  }

  Future<void> updateStatus(String id, PortCallStatus status) async {
    final raw = box.get(id);
    if (raw == null) return;
    final call = PortCall.fromMap(raw as Map).copyWith(status: status);
    await box.put(id, call.toMap());
    notifyListeners();
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final raw = box.get(id);
    if (raw == null) return;
    final call = PortCall.fromMap(raw as Map);
    await box.put(id,
        call.copyWith(attachments: [...call.attachments, attachment]).toMap());
    notifyListeners();
  }

  Future<void> removeAttachment(String id, int index) async {
    final raw = box.get(id);
    if (raw == null) return;
    final call = PortCall.fromMap(raw as Map);
    final files = [...call.attachments]..removeAt(index);
    await box.put(id, call.copyWith(attachments: files).toMap());
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await box.delete(id);
    notifyListeners();
  }
}
