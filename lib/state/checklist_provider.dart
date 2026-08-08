import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment.dart';
import '../models/checklist_run.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed monthly runs of the engine department's controlled forms.
/// One record per vessel per form per month, ticked through the month by the
/// vessel and signed off by the Chief Engineer.
///
/// Same CloudStore pattern as every other module, so ticks made at sea queue
/// offline and flush when the vessel is back in coverage.
class ChecklistProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('checklist_runs');
  List<ChecklistRun> _all = [];

  ChecklistProvider() {
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
      _all = maps.map(ChecklistRun.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  List<ChecklistRun> forVessel(String vesselId) {
    final list = _all.where((r) => r.vesselId == vesselId).toList()
      ..sort((a, b) {
        final byYear = b.year.compareTo(a.year);
        return byYear != 0 ? byYear : b.month.compareTo(a.month);
      });
    return list;
  }

  ChecklistRun? find({
    required String vesselId,
    required String templateCode,
    required int year,
    required int month,
  }) {
    for (final r in _all) {
      if (r.vesselId == vesselId &&
          r.templateCode == templateCode &&
          r.year == year &&
          r.month == month) {
        return r;
      }
    }
    return null;
  }

  /// Returns the existing sheet for this vessel/form/month, creating an empty
  /// one if the month hasn't been started yet — the vessel should never have
  /// to "create" a form that the office already mandates.
  Future<ChecklistRun> ensureRun({
    required String vesselId,
    required String templateCode,
    required int year,
    required int month,
  }) async {
    final existing =
        find(vesselId: vesselId, templateCode: templateCode, year: year, month: month);
    if (existing != null) return existing;

    final run = ChecklistRun(
      id: '${vesselId}_${templateCode}_${year}_$month',
      vesselId: vesselId,
      templateCode: templateCode,
      year: year,
      month: month,
      createdAt: DateTime.now(),
    );
    await _save(run);
    return run;
  }

  Future<void> _save(ChecklistRun run) async {
    final idx = _all.indexWhere((r) => r.id == run.id);
    if (idx >= 0) {
      _all[idx] = run;
    } else {
      _all = [..._all, run];
    }
    notifyListeners();
    await _store.put(run.id, run.vesselId, run.toMap());
  }

  /// Ticks one slot. Passing the same result again clears it back to pending,
  /// so a mis-tap is undone with a second tap rather than needing an edit
  /// mode — these sheets are filled in on a moving vessel.
  Future<void> setSlot({
    required String runId,
    required String itemKey,
    required int slot,
    required SlotResult result,
  }) async {
    final run = _byId(runId);
    if (run == null) return;

    final results = {
      for (final e in run.results.entries) e.key: {...e.value},
    };
    final item = results.putIfAbsent(itemKey, () => {});
    if (item[slot] == result) {
      item.remove(slot);
    } else {
      item[slot] = result;
    }
    await _save(run.copyWith(results: results));
  }

  /// Records the dates a check was carried out this month. Free text on
  /// purpose — the paper form takes "4-11-18-25", and forcing a date picker
  /// would make a four-date weekly entry impossible.
  Future<void> setDate(String runId, String itemKey, String text) async {
    final run = _byId(runId);
    if (run == null) return;
    final dates = {...run.dates};
    if (text.trim().isEmpty) {
      dates.remove(itemKey);
    } else {
      dates[itemKey] = text.trim();
    }
    await _save(run.copyWith(dates: dates));
  }

  Future<void> setRemark(String runId, String itemKey, String text) async {
    final run = _byId(runId);
    if (run == null) return;
    final remarks = {...run.remarks};
    if (text.trim().isEmpty) {
      remarks.remove(itemKey);
    } else {
      remarks[itemKey] = text.trim();
    }
    await _save(run.copyWith(remarks: remarks));
  }

  /// Signing off stamps the submission; re-opening clears it so a corrected
  /// sheet is never silently passed off as the originally signed one.
  Future<void> submit(String runId, String chiefEngineer) async {
    final run = _byId(runId);
    if (run == null) return;
    await _save(run.copyWith(
        chiefEngineer: chiefEngineer, submittedAt: DateTime.now()));
  }

  Future<void> reopen(String runId) async {
    final run = _byId(runId);
    if (run == null) return;
    await _save(run.copyWith(clearSubmitted: true));
  }

  Future<void> addAttachment(String runId, Attachment attachment) async {
    final run = _byId(runId);
    if (run == null) return;
    await _save(run.copyWith(attachments: [...run.attachments, attachment]));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((r) => r.id == id);
    notifyListeners();
    await _store.remove(id);
  }

  ChecklistRun? _byId(String id) {
    for (final r in _all) {
      if (r.id == id) return r;
    }
    return null;
  }
}
