import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crew_member.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed crew lists (Request 6). Records live in the shared Supabase
/// table so every device sees the same roster. An in-memory cache is loaded on
/// login (and refreshed after writes) and exposed synchronously to the UI.
class CrewProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('crew_members');
  List<CrewMember> _all = [];

  CrewProvider() {
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
      _all = maps.map(CrewMember.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  /// Crew currently aboard, sorted by name.
  List<CrewMember> current(String vesselId) {
    final list = _all
        .where((c) => c.vesselId == vesselId && c.status == CrewStatus.current)
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Crew who have signed off, most-recently-off first.
  List<CrewMember> previous(String vesselId) {
    final list = _all
        .where((c) => c.vesselId == vesselId && c.status == CrewStatus.previous)
        .toList();
    list.sort((a, b) {
      final ao = a.signOffDate, bo = b.signOffDate;
      if (ao == null && bo == null) return 0;
      if (ao == null) return 1;
      if (bo == null) return -1;
      return bo.compareTo(ao);
    });
    return list;
  }

  int currentCount(String vesselId) => _all
      .where((c) => c.vesselId == vesselId && c.status == CrewStatus.current)
      .length;

  CrewMember? _byId(String id) {
    for (final c in _all) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _save(CrewMember member) async {
    final idx = _all.indexWhere((c) => c.id == member.id);
    if (idx >= 0) {
      _all[idx] = member;
    } else {
      _all = [..._all, member];
    }
    notifyListeners();
    await _store.put(member.id, member.vesselId, member.toMap());
  }

  Future<void> add({
    required String vesselId,
    required String name,
    String rank = '',
    String nationality = '',
    DateTime? signOnDate,
    String notes = '',
  }) async {
    final now = DateTime.now();
    await _save(CrewMember(
      id: '${vesselId}_${now.microsecondsSinceEpoch}',
      vesselId: vesselId,
      name: name,
      rank: rank,
      nationality: nationality,
      status: CrewStatus.current,
      signOnDate: signOnDate ?? now,
      notes: notes,
      createdAt: now,
    ));
  }

  Future<void> update({
    required String id,
    required String name,
    String rank = '',
    String nationality = '',
    required DateTime signOnDate,
    String notes = '',
  }) async {
    final member = _byId(id);
    if (member == null) return;
    await _save(member.copyWith(
      name: name,
      rank: rank,
      nationality: nationality,
      signOnDate: signOnDate,
      notes: notes,
    ));
  }

  /// Move a member to the Previous list (history), stamping the sign-off date.
  Future<void> signOff(String id, {DateTime? date}) async {
    final member = _byId(id);
    if (member == null) return;
    await _save(member.copyWith(
      status: CrewStatus.previous,
      signOffDate: date ?? DateTime.now(),
    ));
  }

  /// Bring a previously-signed-off member back to the Current list.
  Future<void> reactivate(String id) async {
    final member = _byId(id);
    if (member == null) return;
    await _save(member.copyWith(
      status: CrewStatus.current,
      clearSignOff: true,
    ));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((c) => c.id == id);
    notifyListeners();
    await _store.remove(id);
  }
}
