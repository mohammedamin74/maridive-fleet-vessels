import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment.dart';
import '../models/port_requirement.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed port-arrival requirements (Request 8). Records live in the
/// shared Supabase table so every device sees the same list. An in-memory cache
/// is loaded on login (and refreshed after writes) and exposed synchronously.
class PortRequirementProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('port_requirements');
  List<PortRequirement> _all = [];

  PortRequirementProvider() {
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
      _all = maps.map(PortRequirement.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  List<PortRequirement> forVessel(String vesselId) {
    final list = _all.where((r) => r.vesselId == vesselId).toList();
    // Pending first, then most-recent.
    list.sort((a, b) {
      if (a.status != b.status) {
        return a.status == RequirementStatus.pending ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  int pendingCount(String vesselId) => _all
      .where((r) =>
          r.vesselId == vesselId && r.status == RequirementStatus.pending)
      .length;

  PortRequirement? _byId(String id) {
    for (final r in _all) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> _save(PortRequirement req) async {
    final idx = _all.indexWhere((r) => r.id == req.id);
    if (idx >= 0) {
      _all[idx] = req;
    } else {
      _all = [..._all, req];
    }
    notifyListeners();
    await _store.put(req.id, req.vesselId, req.toMap());
  }

  Future<void> add({
    required String vesselId,
    required String title,
    String portName = '',
    RequirementCategory category = RequirementCategory.documents,
    String notes = '',
    List<Attachment> attachments = const [],
  }) async {
    await _save(PortRequirement(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      title: title,
      portName: portName,
      category: category,
      status: RequirementStatus.pending,
      notes: notes,
      attachments: attachments,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> update({
    required String id,
    required String title,
    String portName = '',
    RequirementCategory category = RequirementCategory.documents,
    String notes = '',
  }) async {
    final req = _byId(id);
    if (req == null) return;
    await _save(req.copyWith(
      title: title,
      portName: portName,
      category: category,
      notes: notes,
    ));
  }

  Future<void> updateStatus(String id, RequirementStatus status) async {
    final req = _byId(id);
    if (req == null) return;
    await _save(req.copyWith(status: status));
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final req = _byId(id);
    if (req == null) return;
    await _save(req.copyWith(attachments: [...req.attachments, attachment]));
  }

  Future<void> removeAttachment(String id, int index) async {
    final req = _byId(id);
    if (req == null) return;
    final files = [...req.attachments]..removeAt(index);
    await _save(req.copyWith(attachments: files));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((r) => r.id == id);
    notifyListeners();
    await _store.remove(id);
  }
}
