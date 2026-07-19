import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'supabase_config.dart';

/// Persists writes that couldn't reach Supabase (offline, timed out, or any
/// other failure) so they survive an app restart and retry automatically
/// once connectivity returns. Keyed by `table::id`, so repeated offline
/// edits to the same record collapse into the latest write instead of
/// growing the queue unbounded.
///
/// [CloudStore] consults this queue on every read (to overlay unsynced
/// writes so they stay visible) and every write (to fall back into it on
/// failure), so every provider gets offline durability for free.
class SyncQueue {
  SyncQueue._();
  static final SyncQueue instance = SyncQueue._();

  static const _boxName = 'pending_sync';
  Box? _box;
  Timer? _timer;
  bool _flushing = false;

  /// Number of writes waiting to reach Supabase. UI can watch this to show
  /// an honest "N changes not yet synced" indicator instead of pretending
  /// everything is saved.
  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    pendingCount.value = _box!.length;
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => flush());
    unawaited(flush());
  }

  Box get _b {
    final box = _box;
    if (box == null) {
      throw StateError('SyncQueue.init() must run before use');
    }
    return box;
  }

  String _key(String table, String id) => '$table::$id';

  void enqueuePut(
      String table, String id, String? vesselId, Map<String, dynamic> data) {
    _b.put(_key(table, id), {
      'op': 'put',
      'table': table,
      'id': id,
      'vesselId': vesselId,
      'data': data,
    });
    pendingCount.value = _b.length;
  }

  void enqueueRemove(String table, String id) {
    _b.put(_key(table, id), {
      'op': 'remove',
      'table': table,
      'id': id,
    });
    pendingCount.value = _b.length;
  }

  /// Not-yet-synced writes for [table], keyed by record id — overlaid onto
  /// the remote rows by [CloudStore.fetchAll] so an offline edit remains
  /// visible (and survives a restart) until it reaches the cloud.
  Map<String, Map<String, dynamic>> pendingFor(String table) {
    final puts = <String, Map<String, dynamic>>{};
    for (final entry in _b.values) {
      final map = Map<String, dynamic>.from(entry as Map);
      if (map['table'] == table && map['op'] == 'put') {
        puts[map['id'] as String] = Map<String, dynamic>.from(map['data'] as Map);
      }
    }
    return puts;
  }

  Set<String> pendingRemovedIds(String table) {
    final ids = <String>{};
    for (final entry in _b.values) {
      final map = Map<String, dynamic>.from(entry as Map);
      if (map['table'] == table && map['op'] == 'remove') {
        ids.add(map['id'] as String);
      }
    }
    return ids;
  }

  /// Retries every queued write in order. Stops at the first failure (still
  /// offline, or the failure persists) and leaves the rest queued for the
  /// next timer tick — avoids a tight retry loop against a dead network.
  Future<void> flush() async {
    final box = _box;
    if (box == null || _flushing || box.isEmpty) return;
    _flushing = true;
    try {
      final sb = SupabaseConfig.client;
      for (final key in box.keys.toList()) {
        final entry = box.get(key);
        if (entry == null) continue;
        final map = Map<String, dynamic>.from(entry as Map);
        try {
          if (map['op'] == 'put') {
            await sb.from(map['table'] as String).upsert({
              'id': map['id'],
              'vessel_id': map['vesselId'],
              'data': map['data'],
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            });
          } else {
            await sb
                .from(map['table'] as String)
                .delete()
                .eq('id', map['id'] as String);
          }
          await box.delete(key);
          pendingCount.value = box.length;
        } catch (_) {
          break;
        }
      }
    } catch (_) {
      // Supabase client not ready yet — try again on the next timer tick.
    } finally {
      _flushing = false;
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
