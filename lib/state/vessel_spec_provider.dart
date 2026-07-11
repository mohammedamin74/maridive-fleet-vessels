import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/vessel_specs_seed.dart';
import '../models/attachment.dart';
import '../models/vessel_spec.dart';
import '../services/attachment_store.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed vessel specification documents. Records live in the shared
/// Supabase table and the spec PDFs live in shared Supabase Storage (the record
/// keeps only a small storage path), so every device sees the same document
/// library. The bundled manufacturer PDFs are uploaded once, idempotently, on
/// first authenticated load.
class VesselSpecProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('vessel_specs');
  List<VesselSpec> _all = [];
  bool _seeding = false;

  VesselSpecProvider() {
    _init();
    SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
          _init();
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

  Future<void> _init() async {
    await _load();
    await _ensureSeeded();
  }

  Future<void> _load() async {
    try {
      final maps = await _store.fetchAll();
      _all = maps.map(VesselSpec.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  /// Uploads each bundled spec PDF to shared Storage and inserts its record,
  /// but only for vessels that don't already have their seed spec in the cloud.
  /// Deterministic ids/paths mean concurrent devices converge on the same rows
  /// instead of creating duplicates.
  Future<void> _ensureSeeded() async {
    if (_seeding) return;
    if (SupabaseConfig.client.auth.currentSession == null) return;
    final missing =
        vesselSpecSeeds.where((s) => !_all.any((x) => x.id == s.specId));
    if (missing.isEmpty) return;
    _seeding = true;
    try {
      for (final s in missing) {
        try {
          final data = await rootBundle.load(s.asset);
          final bytes = data.buffer
              .asUint8List(data.offsetInBytes, data.lengthInBytes);
          final attachment =
              await AttachmentStore.uploadAt(s.storagePath, s.file, bytes);
          final spec = VesselSpec(
            id: s.specId,
            vesselId: s.vesselId,
            title: 'Vessel Specification',
            notes: 'Manufacturer specification sheet.',
            attachments: [attachment],
            createdAt: DateTime.now(),
          );
          _all = [..._all, spec];
          await _store.put(spec.id, spec.vesselId, spec.toMap());
        } catch (_) {
          // A missing/unreadable asset or a failed upload shouldn't block the
          // rest of the seed; skip it and continue.
        }
      }
      notifyListeners();
    } finally {
      _seeding = false;
    }
  }

  Future<void> refresh() => _load();

  List<VesselSpec> forVessel(String vesselId) {
    final list = _all.where((s) => s.vesselId == vesselId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int countFor(String vesselId) =>
      _all.where((s) => s.vesselId == vesselId).length;

  Future<void> _save(VesselSpec spec) async {
    final idx = _all.indexWhere((s) => s.id == spec.id);
    if (idx >= 0) {
      _all[idx] = spec;
    } else {
      _all = [..._all, spec];
    }
    notifyListeners();
    await _store.put(spec.id, spec.vesselId, spec.toMap());
  }

  VesselSpec? _byId(String id) {
    for (final s in _all) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> add({
    required String vesselId,
    required String title,
    required String notes,
    List<Attachment> attachments = const [],
  }) async {
    await _save(VesselSpec(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      title: title,
      notes: notes,
      attachments: attachments,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final spec = _byId(id);
    if (spec == null) return;
    await _save(spec.copyWith(attachments: [...spec.attachments, attachment]));
  }

  Future<void> removeAttachment(String id, int index) async {
    final spec = _byId(id);
    if (spec == null) return;
    final files = [...spec.attachments]..removeAt(index);
    await _save(spec.copyWith(attachments: files));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((s) => s.id == id);
    notifyListeners();
    await _store.remove(id);
  }
}
