import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Thin wrapper over a Supabase table that stores each record as
/// `{ id, vessel_id, data (jsonb) }`. Providers keep an in-memory cache built
/// from [fetchAll] and write through [put] / [remove], so the whole fleet
/// shares one source of truth in the cloud.
class CloudStore {
  final String table;
  const CloudStore(this.table);

  SupabaseClient get _sb => SupabaseConfig.client;

  /// Returns every record's `data` map. Row-level security limits this to
  /// signed-in users; called again after login to populate the cache.
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final rows = await _sb.from(table).select('data');
    return (rows as List)
        .map((r) => Map<String, dynamic>.from((r as Map)['data'] as Map))
        .toList();
  }

  Future<void> put(
      String id, String? vesselId, Map<String, dynamic> data) async {
    await _sb.from(table).upsert({
      'id': id,
      'vessel_id': vesselId,
      'data': data,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> remove(String id) async {
    await _sb.from(table).delete().eq('id', id);
  }
}
