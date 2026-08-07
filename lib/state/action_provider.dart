import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment.dart';
import '../models/fleet_intelligence.dart';
import '../models/superintendent_action.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed Superintendent Action Center. Actions are the bridge between
/// detected risk and human follow-up: created from a risk (keeping its source
/// record as evidence) or manually, then worked through a status flow.
///
/// Same CloudStore pattern as every other module, so offline creates and
/// edits queue in SyncQueue and flush when the connection returns.
class ActionProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('superintendent_actions');
  List<SuperintendentAction> _all = [];

  ActionProvider() {
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
      _all = maps.map(SuperintendentAction.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  List<SuperintendentAction> get all => List.unmodifiable(_all);

  static const _liveStatuses = {
    SuperActionStatus.open,
    SuperActionStatus.inProgress,
    SuperActionStatus.waitingVessel,
    SuperActionStatus.waitingOffice,
  };

  /// Still needing work: everything not completed or cancelled.
  List<SuperintendentAction> get open =>
      _sorted(_all.where((a) => _liveStatuses.contains(a.status)));

  List<SuperintendentAction> forVessel(String vesselId) =>
      _sorted(_all.where((a) => a.vesselId == vesselId));

  /// Open actions assigned to (or raised by) the signed-in user.
  List<SuperintendentAction> mine(String user) {
    final key = user.trim().toLowerCase();
    if (key.isEmpty) return const [];
    return _sorted(_all.where((a) =>
        _liveStatuses.contains(a.status) &&
        (a.assignedTo.trim().toLowerCase() == key ||
            a.createdBy.trim().toLowerCase() == key)));
  }

  List<SuperintendentAction> get overdue =>
      _sorted(_all.where((a) => a.isOverdue));

  List<SuperintendentAction> get critical => _sorted(_all.where((a) =>
      _liveStatuses.contains(a.status) &&
      a.priority == ActionPriority.critical));

  int get openCount => _all.where((a) => _liveStatuses.contains(a.status)).length;

  int get overdueCount => _all.where((a) => a.isOverdue).length;

  /// True when a risk already has an action, so the UI can offer "open" in
  /// place of "create" and the same risk isn't logged twice.
  bool hasActionFor(RiskEvent risk) => _all.any((a) =>
      a.sourceId == risk.sourceId &&
      a.sourceType == risk.sourceType &&
      _liveStatuses.contains(a.status));

  /// Priority ordering, then due date (undated last), then newest first.
  List<SuperintendentAction> _sorted(Iterable<SuperintendentAction> items) {
    final list = items.toList()
      ..sort((a, b) {
        final byPriority = a.priority.index.compareTo(b.priority.index);
        if (byPriority != 0) return byPriority;
        final ad = a.dueDate, bd = b.dueDate;
        if (ad != null && bd != null) return ad.compareTo(bd);
        if (ad != null) return -1;
        if (bd != null) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return list;
  }

  Future<void> _save(SuperintendentAction action) async {
    final idx = _all.indexWhere((a) => a.id == action.id);
    if (idx >= 0) {
      _all[idx] = action;
    } else {
      _all = [..._all, action];
    }
    notifyListeners();
    await _store.put(action.id, action.vesselId, action.toMap());
  }

  Future<void> add({
    required String vesselId,
    required String title,
    String description = '',
    String recommendation = '',
    ActionPriority priority = ActionPriority.medium,
    String sourceType = '',
    String sourceId = '',
    String assignedTo = '',
    DateTime? dueDate,
    String notes = '',
    String createdBy = '',
  }) async {
    await _save(SuperintendentAction(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      title: title,
      description: description,
      recommendation: recommendation,
      priority: priority,
      sourceType: sourceType,
      sourceId: sourceId,
      assignedTo: assignedTo,
      dueDate: dueDate,
      notes: notes,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    ));
  }

  /// Full-form edit: every field is supplied by the edit sheet, so a null
  /// [dueDate] means the user cleared it rather than "leave unchanged".
  Future<void> update({
    required String id,
    required String title,
    required String description,
    required String recommendation,
    required ActionPriority priority,
    required String assignedTo,
    required DateTime? dueDate,
    required String notes,
  }) async {
    final action = _byId(id);
    if (action == null) return;
    await _save(action.copyWith(
      title: title,
      description: description,
      recommendation: recommendation,
      priority: priority,
      assignedTo: assignedTo,
      dueDate: dueDate,
      notes: notes,
    ));
  }

  /// Status changes stamp (or clear) the completion date so "when was this
  /// closed?" is always answerable from the record itself.
  Future<void> setStatus(String id, SuperActionStatus status) async {
    final action = _byId(id);
    if (action == null || action.status == status) return;
    await _save(action.copyWith(
      status: status,
      completedAt:
          status == SuperActionStatus.completed ? DateTime.now() : null,
    ));
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final action = _byId(id);
    if (action == null) return;
    await _save(
        action.copyWith(attachments: [...action.attachments, attachment]));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((a) => a.id == id);
    notifyListeners();
    await _store.remove(id);
  }

  SuperintendentAction? _byId(String id) {
    for (final a in _all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
