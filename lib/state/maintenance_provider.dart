import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment.dart';
import '../models/maintenance_record.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed maintenance records. Data lives in the shared Supabase table
/// so every device sees the same jobs. An in-memory cache is loaded on login
/// (and refreshed after writes) and exposed synchronously to the UI.
class MaintenanceProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('maintenance_records');
  List<MaintenanceRecord> _all = [];

  MaintenanceProvider() {
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
      _all = maps.map(MaintenanceRecord.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  List<MaintenanceRecord> forVessel(String vesselId) {
    final list = _all.where((m) => m.vesselId == vesselId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int openCountFor(String vesselId) => _all
      .where((m) =>
          m.vesselId == vesselId && m.status != MaintenanceStatus.completed)
      .length;

  Future<void> _save(MaintenanceRecord record) async {
    final idx = _all.indexWhere((m) => m.id == record.id);
    if (idx >= 0) {
      _all[idx] = record;
    } else {
      _all = [..._all, record];
    }
    notifyListeners();
    await _store.put(record.id, record.vesselId, record.toMap());
  }

  Future<void> add({
    required String vesselId,
    required String title,
    required String description,
    required String performedBy,
    required DateTime dueDate,
    List<Attachment> attachments = const [],
  }) async {
    await _save(MaintenanceRecord(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      title: title,
      description: description,
      performedBy: performedBy,
      dueDate: dueDate,
      status: MaintenanceStatus.planned,
      attachments: attachments,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> updateStatus(String id, MaintenanceStatus status) async {
    final rec = _byId(id);
    if (rec == null) return;
    await _save(rec.copyWith(status: status));
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final rec = _byId(id);
    if (rec == null) return;
    await _save(rec.copyWith(attachments: [...rec.attachments, attachment]));
  }

  Future<void> removeAttachment(String id, int index) async {
    final rec = _byId(id);
    if (rec == null) return;
    final files = [...rec.attachments]..removeAt(index);
    await _save(rec.copyWith(attachments: files));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((m) => m.id == id);
    notifyListeners();
    await _store.remove(id);
  }

  MaintenanceRecord? _byId(String id) {
    for (final m in _all) {
      if (m.id == id) return m;
    }
    return null;
  }
}
