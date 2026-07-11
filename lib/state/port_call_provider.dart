import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment.dart';
import '../models/checklist_item.dart';
import '../models/port_call.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed port calls. Records live in the shared Supabase table so every
/// device sees the same logistics. An in-memory cache is loaded on login (and
/// refreshed after writes) and exposed synchronously to the UI.
class PortCallProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('port_calls');
  List<PortCall> _all = [];

  PortCallProvider() {
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
      _all = maps.map(PortCall.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  List<PortCall> forVessel(String vesselId) {
    final list = _all.where((p) => p.vesselId == vesselId).toList();
    list.sort((a, b) => a.arrivalEta.compareTo(b.arrivalEta));
    return list;
  }

  Future<void> _save(PortCall call) async {
    final idx = _all.indexWhere((p) => p.id == call.id);
    if (idx >= 0) {
      _all[idx] = call;
    } else {
      _all = [..._all, call];
    }
    notifyListeners();
    await _store.put(call.id, call.vesselId, call.toMap());
  }

  PortCall? _byId(String id) {
    for (final p in _all) {
      if (p.id == id) return p;
    }
    return null;
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
    await _save(PortCall(
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
    ));
  }

  Future<void> toggleChecklistItem(String id, int index, bool checked) async {
    final call = _byId(id);
    if (call == null) return;
    final updated = List<ChecklistItem>.from(call.customsChecklist);
    updated[index] = updated[index].copyWith(checked: checked);
    await _save(call.copyWith(customsChecklist: updated));
  }

  Future<void> updateStatus(String id, PortCallStatus status) async {
    final call = _byId(id);
    if (call == null) return;
    await _save(call.copyWith(status: status));
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final call = _byId(id);
    if (call == null) return;
    await _save(call.copyWith(attachments: [...call.attachments, attachment]));
  }

  Future<void> removeAttachment(String id, int index) async {
    final call = _byId(id);
    if (call == null) return;
    final files = [...call.attachments]..removeAt(index);
    await _save(call.copyWith(attachments: files));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((p) => p.id == id);
    notifyListeners();
    await _store.remove(id);
  }
}
