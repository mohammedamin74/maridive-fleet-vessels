import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vessel.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed user edits to otherwise-static vessel fields (operational
/// status and IMO number), keyed by vessel id and applied on top of the
/// catalog [Vessel] via [resolve]. Overrides live in the shared Supabase table
/// so switching a vessel off-hire, or setting its IMO manually, is seen by the
/// whole fleet without mutating the fixed catalog data.
class VesselProfileProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('vessel_profiles');
  // Keyed by vessel id → { vesselId, status, imo }.
  Map<String, Map<String, dynamic>> _overrides = {};

  VesselProfileProvider() {
    _load();
    SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
          _load();
          break;
        case AuthChangeEvent.signedOut:
          _overrides = {};
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
      final next = <String, Map<String, dynamic>>{};
      for (final m in maps) {
        final vesselId = m['vesselId'] as String?;
        if (vesselId != null) next[vesselId] = m;
      }
      _overrides = next;
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  Vessel resolve(Vessel v) {
    final m = _overrides[v.id];
    if (m == null) return v;
    final statusName = m['status'] as String?;
    final imo = m['imo'] as String?;
    return v.copyWith(
      status:
          statusName != null ? VesselStatus.values.byName(statusName) : null,
      imo: (imo != null && imo.trim().isNotEmpty) ? imo.trim() : null,
    );
  }

  Future<void> _save(String vesselId, Map<String, dynamic> data) async {
    data['vesselId'] = vesselId;
    _overrides = {..._overrides, vesselId: data};
    notifyListeners();
    await _store.put(vesselId, vesselId, data);
  }

  Future<void> setStatus(String vesselId, VesselStatus status) async {
    final m = Map<String, dynamic>.from(_overrides[vesselId] ?? {});
    m['status'] = status.name;
    await _save(vesselId, m);
  }

  Future<void> setImo(String vesselId, String imo) async {
    final m = Map<String, dynamic>.from(_overrides[vesselId] ?? {});
    m['imo'] = imo.trim();
    await _save(vesselId, m);
  }
}
