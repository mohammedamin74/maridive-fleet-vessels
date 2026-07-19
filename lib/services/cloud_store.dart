import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'sync_queue.dart';

/// Thin wrapper over a Supabase table that stores each record as
/// `{ id, vessel_id, data (jsonb) }`. Providers keep an in-memory cache built
/// from [fetchAll] and write through [put] / [remove], so the whole fleet
/// shares one source of truth in the cloud.
///
/// Reads and writes are resilient to being offline: [put]/[remove] fall back
/// into [SyncQueue] on failure instead of throwing, and [fetchAll] overlays
/// anything still queued so an offline edit stays visible — and survives an
/// app restart — until it reaches Supabase.
class CloudStore {
  final String table;
  const CloudStore(this.table);

  SupabaseClient get _sb => SupabaseConfig.client;

  /// Returns every record's `data` map, keyed internally by row id so
  /// pending local writes can overlay the matching remote row. Paginates
  /// past PostgREST's default 1000-row response cap and orders by
  /// `updated_at` so results are stable and complete however large a
  /// table grows.
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final remote = <String, Map<String, dynamic>>{};
    const pageSize = 1000;
    var from = 0;
    while (true) {
      final rows = await _sb
          .from(table)
          .select('id, data')
          .order('updated_at', ascending: true)
          .range(from, from + pageSize - 1);
      final page = rows as List;
      for (final r in page) {
        final row = r as Map;
        remote[row['id'] as String] =
            Map<String, dynamic>.from(row['data'] as Map);
      }
      if (page.length < pageSize) break;
      from += pageSize;
    }

    SyncQueue.instance.pendingFor(table).forEach((id, data) {
      remote[id] = data;
    });
    for (final id in SyncQueue.instance.pendingRemovedIds(table)) {
      remote.remove(id);
    }
    return remote.values.toList();
  }

  Future<void> put(
      String id, String? vesselId, Map<String, dynamic> data) async {
    try {
      await _sb.from(table).upsert({
        'id': id,
        'vessel_id': vesselId,
        'data': data,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      SyncQueue.instance.enqueuePut(table, id, vesselId, data);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _sb.from(table).delete().eq('id', id);
    } catch (_) {
      SyncQueue.instance.enqueueRemove(table, id);
    }
  }
}
