import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment.dart';
import '../models/defect.dart';
import '../models/requisition.dart';
import '../models/tank.dart';
import '../models/tank_reading.dart';
import '../models/vessel.dart';
import '../models/vessel_note.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';
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

/// Cloud-backed tank readings / logbook notes / defects / requisitions.
///
/// Each of the four datasets lives in its own shared Supabase table; the
/// provider keeps an in-memory cache of each (loaded on login and refreshed
/// after writes) so the whole fleet shares one source of truth. Tank current
/// levels are NOT stored on the static [Tank] catalog — they are always the
/// most recent [TankReading] for that vessel+tank pair.
class TankDataProvider extends ChangeNotifier {
  final CloudStore _readings = const CloudStore('readings');
  final CloudStore _notes = const CloudStore('notes');
  final CloudStore _defects = const CloudStore('defects');
  final CloudStore _requisitions = const CloudStore('requisitions');

  List<TankReading> _readingsCache = [];
  List<VesselNote> _notesCache = [];
  List<Defect> _defectsCache = [];
  List<Requisition> _requisitionsCache = [];

  TankDataProvider() {
    _loadAll();
    SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
          _loadAll();
          break;
        case AuthChangeEvent.signedOut:
          _readingsCache = [];
          _notesCache = [];
          _defectsCache = [];
          _requisitionsCache = [];
          notifyListeners();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        _readings.fetchAll(),
        _notes.fetchAll(),
        _defects.fetchAll(),
        _requisitions.fetchAll(),
      ]);
      _readingsCache = results[0].map(TankReading.fromMap).toList();
      _notesCache = results[1].map(VesselNote.fromMap).toList();
      _defectsCache = results[2].map(Defect.fromMap).toList();
      _requisitionsCache = results[3].map(Requisition.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _loadAll();

  // --- Tank readings ---

  List<TankReading> readingsFor(String vesselId, String tankId) {
    final list = _readingsCache
        .where((r) => r.vesselId == vesselId && r.tankId == tankId)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  bool hasReading(String vesselId, String tankId) => _readingsCache
      .any((r) => r.vesselId == vesselId && r.tankId == tankId);

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
    _readingsCache = [..._readingsCache, reading];
    notifyListeners();
    await _readings.put(reading.storageKey, reading.vesselId, reading.toMap());
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

  // --- Logbook notes ---

  List<VesselNote> notesFor(String vesselId) {
    final list = _notesCache.where((n) => n.vesselId == vesselId).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> _saveNote(VesselNote note) async {
    final idx = _notesCache.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      _notesCache[idx] = note;
    } else {
      _notesCache = [..._notesCache, note];
    }
    notifyListeners();
    await _notes.put(note.id, note.vesselId, note.toMap());
  }

  VesselNote? _noteById(String id) {
    for (final n in _notesCache) {
      if (n.id == id) return n;
    }
    return null;
  }

  Future<void> addNote(String vesselId, String text,
      {List<Attachment> attachments = const []}) async {
    await _saveNote(VesselNote(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      text: text,
      attachments: attachments,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> addNoteAttachment(String noteId, Attachment attachment) async {
    final note = _noteById(noteId);
    if (note == null) return;
    await _saveNote(
        note.copyWith(attachments: [...note.attachments, attachment]));
  }

  Future<void> removeNoteAttachment(String noteId, int index) async {
    final note = _noteById(noteId);
    if (note == null) return;
    final files = [...note.attachments]..removeAt(index);
    await _saveNote(note.copyWith(attachments: files));
  }

  Future<void> deleteNote(String noteId) async {
    _notesCache.removeWhere((n) => n.id == noteId);
    notifyListeners();
    await _notes.remove(noteId);
  }

  // --- Defects ---

  List<Defect> defectsFor(String vesselId) {
    final list = _defectsCache.where((d) => d.vesselId == vesselId).toList();
    list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return list;
  }

  List<Defect> criticalOpenDefects(List<Vessel> vessels) {
    final vesselIds = vessels.map((v) => v.id).toSet();
    final list = _defectsCache
        .where((d) =>
            vesselIds.contains(d.vesselId) &&
            d.status != DefectStatus.closed &&
            (d.priority == DefectPriority.critical ||
                d.priority == DefectPriority.high))
        .toList();
    list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return list;
  }

  Future<void> _saveDefect(Defect defect) async {
    final idx = _defectsCache.indexWhere((d) => d.id == defect.id);
    if (idx >= 0) {
      _defectsCache[idx] = defect;
    } else {
      _defectsCache = [..._defectsCache, defect];
    }
    notifyListeners();
    await _defects.put(defect.id, defect.vesselId, defect.toMap());
  }

  Defect? _defectById(String id) {
    for (final d in _defectsCache) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> addDefect({
    required String vesselId,
    required String title,
    required String description,
    required DefectLocation location,
    required DefectPriority priority,
    String assignedOfficer = '',
    String requiredSpareParts = '',
    List<Attachment> attachments = const [],
  }) async {
    await _saveDefect(Defect(
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
      attachments: attachments,
      reportedAt: DateTime.now(),
    ));
  }

  Future<void> updateDefectStatus(String id, DefectStatus status) async {
    final defect = _defectById(id);
    if (defect == null) return;
    await _saveDefect(defect.copyWith(status: status));
  }

  Future<void> updateDefectActionTaken(String id, String actionTaken) async {
    final defect = _defectById(id);
    if (defect == null) return;
    await _saveDefect(defect.copyWith(actionTaken: actionTaken));
  }

  Future<void> addDefectAttachment(String id, Attachment attachment) async {
    final defect = _defectById(id);
    if (defect == null) return;
    await _saveDefect(
        defect.copyWith(attachments: [...defect.attachments, attachment]));
  }

  Future<void> removeDefectAttachment(String id, int index) async {
    final defect = _defectById(id);
    if (defect == null) return;
    final files = [...defect.attachments]..removeAt(index);
    await _saveDefect(defect.copyWith(attachments: files));
  }

  Future<void> deleteDefect(String id) async {
    _defectsCache.removeWhere((d) => d.id == id);
    notifyListeners();
    await _defects.remove(id);
  }

  // --- Requisitions ---

  List<Requisition> requisitionsFor(String vesselId) {
    final list =
        _requisitionsCache.where((r) => r.vesselId == vesselId).toList();
    list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return list;
  }

  Future<void> _saveRequisition(Requisition requisition) async {
    final idx =
        _requisitionsCache.indexWhere((r) => r.id == requisition.id);
    if (idx >= 0) {
      _requisitionsCache[idx] = requisition;
    } else {
      _requisitionsCache = [..._requisitionsCache, requisition];
    }
    notifyListeners();
    await _requisitions.put(
        requisition.id, requisition.vesselId, requisition.toMap());
  }

  Requisition? _requisitionById(String id) {
    for (final r in _requisitionsCache) {
      if (r.id == id) return r;
    }
    return null;
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
    List<Attachment> attachments = const [],
  }) async {
    final seq =
        _requisitionsCache.where((r) => r.vesselId == vesselId).length + 1;
    final requisitionNumber =
        'REQ-${vesselName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}-${seq.toString().padLeft(4, '0')}';
    await _saveRequisition(Requisition(
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
      attachments: attachments,
      requestedAt: DateTime.now(),
    ));
  }

  Future<void> updateRequisitionStatus(
      String id, RequisitionStatus status) async {
    final requisition = _requisitionById(id);
    if (requisition == null) return;
    await _saveRequisition(requisition.copyWith(status: status));
  }

  /// Full field edit for an existing requisition (item details, quantities,
  /// department/priority, delivery date, notes) — separate from
  /// [updateRequisitionStatus], which only advances the approval chain.
  Future<void> updateRequisition({
    required String id,
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
    final requisition = _requisitionById(id);
    if (requisition == null) return;
    await _saveRequisition(requisition.copyWith(
      itemName: itemName,
      partNumber: partNumber,
      oemManufacturer: oemManufacturer,
      quantity: quantity,
      quantityInStock: quantityInStock,
      unit: unit,
      unitPrice: unitPrice,
      department: department,
      priority: priority,
      requiredDeliveryDate: requiredDeliveryDate,
      notes: notes,
    ));
  }

  Future<void> addRequisitionAttachment(
      String id, Attachment attachment) async {
    final requisition = _requisitionById(id);
    if (requisition == null) return;
    await _saveRequisition(requisition
        .copyWith(attachments: [...requisition.attachments, attachment]));
  }

  Future<void> removeRequisitionAttachment(String id, int index) async {
    final requisition = _requisitionById(id);
    if (requisition == null) return;
    final files = [...requisition.attachments]..removeAt(index);
    await _saveRequisition(requisition.copyWith(attachments: files));
  }

  Future<void> deleteRequisition(String id) async {
    _requisitionsCache.removeWhere((r) => r.id == id);
    notifyListeners();
    await _requisitions.remove(id);
  }
}
