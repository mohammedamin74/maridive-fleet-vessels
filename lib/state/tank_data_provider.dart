import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/defect.dart';
import '../models/requisition.dart';
import '../models/tank.dart';
import '../models/tank_reading.dart';
import '../models/vessel.dart';
import '../models/vessel_note.dart';
import 'alert_thresholds.dart';

class TankAlert {
  final Vessel vessel;
  final Tank tank;
  final double percent;
  final TankLevelStatus status;

  const TankAlert({
    required this.vessel,
    required this.tank,
    required this.percent,
    required this.status,
  });
}

/// Wraps the Hive-backed readings/notes/defects/requisitions boxes and
/// derives live tank levels. Tank current levels are NOT stored on the
/// static [Tank] catalog — they are always the most recent [TankReading]
/// for that vessel+tank pair, so there is one source of truth for
/// "current level" and "history".
class TankDataProvider extends ChangeNotifier {
  final Box readingsBox;
  final Box notesBox;
  final Box defectsBox;
  final Box requisitionsBox;

  TankDataProvider({
    required this.readingsBox,
    required this.notesBox,
    required this.defectsBox,
    required this.requisitionsBox,
  });

  List<TankReading> readingsFor(String vesselId, String tankId) {
    final list = readingsBox.values
        .map((e) => TankReading.fromMap(e as Map))
        .where((r) => r.vesselId == vesselId && r.tankId == tankId)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  bool hasReading(String vesselId, String tankId) =>
      readingsBox.values.any((e) {
        final m = e as Map;
        return m['vesselId'] == vesselId && m['tankId'] == tankId;
      });

  double currentLevel(String vesselId, String tankId) {
    final readings = readingsFor(vesselId, tankId);
    return readings.isEmpty ? 0 : readings.first.levelM3;
  }

  double percentFor(String vesselId, Tank tank) {
    final current = currentLevel(vesselId, tank.id);
    if (tank.capacityM3 <= 0) return 0;
    return (current / tank.capacityM3).clamp(0, 1);
  }

  TankLevelStatus statusFor(String vesselId, Tank tank) {
    return levelStatusFor(
      hasReading: hasReading(vesselId, tank.id),
      percent: percentFor(vesselId, tank),
    );
  }

  Future<void> addReading(String vesselId, String tankId, double levelM3,
      {double? temperatureC}) async {
    final reading = TankReading(
      vesselId: vesselId,
      tankId: tankId,
      levelM3: levelM3,
      temperatureC: temperatureC,
      timestamp: DateTime.now(),
    );
    await readingsBox.put(reading.storageKey, reading.toMap());
    notifyListeners();
  }

  double avgFuelPercent(Vessel vessel) {
    final fuelTanks = vessel.tanksOf(TankCategory.fuelOil);
    if (fuelTanks.isEmpty) return 0;
    final total =
        fuelTanks.fold<double>(0, (sum, t) => sum + percentFor(vessel.id, t));
    return total / fuelTanks.length;
  }

  List<TankAlert> alertsFor(List<Vessel> vessels) {
    final alerts = <TankAlert>[];
    for (final vessel in vessels) {
      for (final tank in vessel.tanks) {
        final status = statusFor(vessel.id, tank);
        if (status == TankLevelStatus.critical ||
            status == TankLevelStatus.warning ||
            status == TankLevelStatus.highWarning ||
            status == TankLevelStatus.highCritical) {
          alerts.add(TankAlert(
            vessel: vessel,
            tank: tank,
            percent: percentFor(vessel.id, tank),
            status: status,
          ));
        }
      }
    }
    alerts.sort((a, b) => a.percent.compareTo(b.percent));
    return alerts;
  }

  List<VesselNote> notesFor(String vesselId) {
    final list = notesBox.values
        .map((e) => VesselNote.fromMap(e as Map))
        .where((n) => n.vesselId == vesselId)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> addNote(String vesselId, String text) async {
    final note = VesselNote(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      text: text,
      timestamp: DateTime.now(),
    );
    await notesBox.put(note.id, note.toMap());
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    await notesBox.delete(noteId);
    notifyListeners();
  }

  // --- Defects ---

  List<Defect> defectsFor(String vesselId) {
    final list = defectsBox.values
        .map((e) => Defect.fromMap(e as Map))
        .where((d) => d.vesselId == vesselId)
        .toList();
    list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return list;
  }

  List<Defect> criticalOpenDefects(List<Vessel> vessels) {
    final vesselIds = vessels.map((v) => v.id).toSet();
    final list = defectsBox.values
        .map((e) => Defect.fromMap(e as Map))
        .where((d) =>
            vesselIds.contains(d.vesselId) &&
            d.status != DefectStatus.closed &&
            (d.priority == DefectPriority.critical ||
                d.priority == DefectPriority.high))
        .toList();
    list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return list;
  }

  Future<void> addDefect({
    required String vesselId,
    required String title,
    required String description,
    required DefectLocation location,
    required DefectPriority priority,
    String assignedOfficer = '',
    String requiredSpareParts = '',
  }) async {
    final defect = Defect(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      title: title,
      description: description,
      location: location,
      priority: priority,
      status: DefectStatus.open,
      assignedOfficer: assignedOfficer,
      requiredSpareParts: requiredSpareParts,
      actionTaken: '',
      photosBase64: const [],
      reportedAt: DateTime.now(),
    );
    await defectsBox.put(defect.id, defect.toMap());
    notifyListeners();
  }

  Future<void> updateDefectStatus(String id, DefectStatus status) async {
    final raw = defectsBox.get(id);
    if (raw == null) return;
    final defect = Defect.fromMap(raw as Map).copyWith(status: status);
    await defectsBox.put(id, defect.toMap());
    notifyListeners();
  }

  Future<void> updateDefectActionTaken(String id, String actionTaken) async {
    final raw = defectsBox.get(id);
    if (raw == null) return;
    final defect =
        Defect.fromMap(raw as Map).copyWith(actionTaken: actionTaken);
    await defectsBox.put(id, defect.toMap());
    notifyListeners();
  }

  Future<void> addDefectPhoto(String id, String photoBase64) async {
    final raw = defectsBox.get(id);
    if (raw == null) return;
    final defect = Defect.fromMap(raw as Map);
    await defectsBox.put(
        id,
        defect.copyWith(
            photosBase64: [...defect.photosBase64, photoBase64]).toMap());
    notifyListeners();
  }

  Future<void> removeDefectPhoto(String id, int index) async {
    final raw = defectsBox.get(id);
    if (raw == null) return;
    final defect = Defect.fromMap(raw as Map);
    final photos = [...defect.photosBase64]..removeAt(index);
    await defectsBox.put(id, defect.copyWith(photosBase64: photos).toMap());
    notifyListeners();
  }

  Future<void> deleteDefect(String id) async {
    await defectsBox.delete(id);
    notifyListeners();
  }

  // --- Requisitions ---

  List<Requisition> requisitionsFor(String vesselId) {
    final list = requisitionsBox.values
        .map((e) => Requisition.fromMap(e as Map))
        .where((r) => r.vesselId == vesselId)
        .toList();
    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return list;
  }

  Future<void> addRequisition({
    required String vesselId,
    required String vesselName,
    required String itemName,
    required String partNumber,
    required String oemManufacturer,
    required double quantity,
    required double quantityInStock,
    required String unit,
    required double unitPrice,
    required RequisitionDepartment department,
    required RequisitionPriority priority,
    DateTime? requiredDeliveryDate,
    String notes = '',
  }) async {
    final seq = requisitionsBox.values
            .map((e) => Requisition.fromMap(e as Map))
            .where((r) => r.vesselId == vesselId)
            .length +
        1;
    final requisitionNumber =
        'REQ-${vesselName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}-${seq.toString().padLeft(4, '0')}';
    final requisition = Requisition(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      requisitionNumber: requisitionNumber,
      itemName: itemName,
      partNumber: partNumber,
      oemManufacturer: oemManufacturer,
      quantity: quantity,
      quantityInStock: quantityInStock,
      unit: unit,
      unitPrice: unitPrice,
      department: department,
      priority: priority,
      status: RequisitionStatus.pending,
      requiredDeliveryDate: requiredDeliveryDate,
      notes: notes,
      photosBase64: const [],
      requestedAt: DateTime.now(),
    );
    await requisitionsBox.put(requisition.id, requisition.toMap());
    notifyListeners();
  }

  Future<void> updateRequisitionStatus(
      String id, RequisitionStatus status) async {
    final raw = requisitionsBox.get(id);
    if (raw == null) return;
    final requisition =
        Requisition.fromMap(raw as Map).copyWith(status: status);
    await requisitionsBox.put(id, requisition.toMap());
    notifyListeners();
  }

  Future<void> addRequisitionPhoto(String id, String photoBase64) async {
    final raw = requisitionsBox.get(id);
    if (raw == null) return;
    final requisition = Requisition.fromMap(raw as Map);
    await requisitionsBox.put(
        id,
        requisition.copyWith(
            photosBase64: [...requisition.photosBase64, photoBase64]).toMap());
    notifyListeners();
  }

  Future<void> removeRequisitionPhoto(String id, int index) async {
    final raw = requisitionsBox.get(id);
    if (raw == null) return;
    final requisition = Requisition.fromMap(raw as Map);
    final photos = [...requisition.photosBase64]..removeAt(index);
    await requisitionsBox.put(
        id, requisition.copyWith(photosBase64: photos).toMap());
    notifyListeners();
  }

  Future<void> deleteRequisition(String id) async {
    await requisitionsBox.delete(id);
    notifyListeners();
  }
}
