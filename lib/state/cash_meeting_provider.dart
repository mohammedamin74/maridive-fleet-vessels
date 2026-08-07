import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment.dart';
import '../models/cash_item.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed cash meeting ledger. Data lives in the shared Supabase table
/// so the office and every vessel see the same purchase lines. An in-memory
/// cache is loaded on login (and refreshed after writes) and exposed
/// synchronously to the UI.
class CashMeetingProvider extends ChangeNotifier {
  final CloudStore _store = const CloudStore('cash_items');
  List<CashItem> _all = [];

  CashMeetingProvider() {
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
      _all = maps.map(CashItem.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _load();

  /// Rolling ledger view: newest first within each status.
  List<CashItem> byStatus(CashItemStatus status, {String? vesselId}) {
    final list = _all
        .where((c) =>
            c.status == status &&
            (vesselId == null || c.vesselId == vesselId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int get pendingCount =>
      _all.where((c) => c.status == CashItemStatus.pending).length;

  /// Amounts grouped per currency — different currencies are never summed
  /// into one number.
  Map<CashCurrency, double> subtotals(List<CashItem> items) {
    final totals = <CashCurrency, double>{};
    for (final c in items) {
      totals[c.currency] = (totals[c.currency] ?? 0) + c.cost;
    }
    return totals;
  }

  Future<void> _save(CashItem item) async {
    final idx = _all.indexWhere((c) => c.id == item.id);
    if (idx >= 0) {
      _all[idx] = item;
    } else {
      _all = [..._all, item];
    }
    notifyListeners();
    await _store.put(item.id, item.vesselId, item.toMap());
  }

  Future<void> add({
    required String vesselId,
    required String operation,
    required String description,
    required String prNumber,
    required double cost,
    required CashCurrency currency,
    required String supplier,
    required String poNumber,
    String notes = '',
    List<Attachment> attachments = const [],
  }) async {
    await _save(CashItem(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      operation: operation,
      description: description,
      prNumber: prNumber,
      cost: cost,
      currency: currency,
      supplier: supplier,
      poNumber: poNumber,
      status: CashItemStatus.pending,
      decidedAt: null,
      notes: notes,
      attachments: attachments,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> update({
    required String id,
    required String vesselId,
    required String operation,
    required String description,
    required String prNumber,
    required double cost,
    required CashCurrency currency,
    required String supplier,
    required String poNumber,
    required String notes,
  }) async {
    final item = _byId(id);
    if (item == null) return;
    await _save(item.copyWith(
      vesselId: vesselId,
      operation: operation,
      description: description,
      prNumber: prNumber,
      cost: cost,
      currency: currency,
      supplier: supplier,
      poNumber: poNumber,
      notes: notes,
    ));
  }

  /// The entire approval workflow: one toggle, stamped with the decision
  /// date. Reverting to pending clears the stamp.
  Future<void> setStatus(String id, CashItemStatus status) async {
    final item = _byId(id);
    if (item == null || item.status == status) return;
    await _save(CashItem(
      id: item.id,
      vesselId: item.vesselId,
      operation: item.operation,
      description: item.description,
      prNumber: item.prNumber,
      cost: item.cost,
      currency: item.currency,
      supplier: item.supplier,
      poNumber: item.poNumber,
      status: status,
      decidedAt: status == CashItemStatus.approved ? DateTime.now() : null,
      notes: item.notes,
      attachments: item.attachments,
      createdAt: item.createdAt,
    ));
  }

  Future<void> addAttachment(String id, Attachment attachment) async {
    final item = _byId(id);
    if (item == null) return;
    await _save(item.copyWith(attachments: [...item.attachments, attachment]));
  }

  Future<void> delete(String id) async {
    _all.removeWhere((c) => c.id == id);
    notifyListeners();
    await _store.remove(id);
  }

  CashItem? _byId(String id) {
    for (final c in _all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
