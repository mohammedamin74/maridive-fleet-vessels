// Pure queue-manipulation coverage for the offline-write repair: an
// enqueued put must overlay a table's cached rows, an enqueued remove must
// exclude one, and repeated writes to the same record must collapse
// instead of growing the queue unbounded. flush() itself needs a live
// Supabase client and is exercised manually (airplane-mode test), not here.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:maridive_fleet_vessels/services/sync_queue.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_queue_test');
    Hive.init(tempDir.path);
    await SyncQueue.instance.init();
  });

  tearDown(() async {
    SyncQueue.instance.dispose();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('enqueuePut overlays the record for its table', () {
    SyncQueue.instance.enqueuePut('defects', 'd1', 'v1', {'title': 'Crack'});

    expect(SyncQueue.instance.pendingFor('defects'), {
      'd1': {'title': 'Crack'},
    });
    expect(SyncQueue.instance.pendingFor('requisitions'), isEmpty);
    expect(SyncQueue.instance.pendingCount.value, 1);
  });

  test('a second offline edit to the same record collapses, not grows', () {
    SyncQueue.instance.enqueuePut('defects', 'd1', 'v1', {'title': 'Crack'});
    SyncQueue.instance
        .enqueuePut('defects', 'd1', 'v1', {'title': 'Crack — widening'});

    expect(SyncQueue.instance.pendingCount.value, 1);
    expect(SyncQueue.instance.pendingFor('defects')['d1']!['title'],
        'Crack — widening');
  });

  test('enqueueRemove marks the id as pending-removed', () {
    SyncQueue.instance.enqueuePut('defects', 'd1', 'v1', {'title': 'Crack'});
    SyncQueue.instance.enqueueRemove('defects', 'd1');

    // The remove op replaced the put op under the same table::id key.
    expect(SyncQueue.instance.pendingCount.value, 1);
    expect(SyncQueue.instance.pendingFor('defects'), isEmpty);
    expect(SyncQueue.instance.pendingRemovedIds('defects'), {'d1'});
  });

  test('queued writes survive re-opening the same Hive box (app restart)',
      () async {
    SyncQueue.instance.enqueuePut('readings', 'r1', 'v1', {'levelM3': 12.5});

    // Simulate an app restart: re-run init() against the same on-disk box.
    await SyncQueue.instance.init();

    expect(SyncQueue.instance.pendingCount.value, 1);
    expect(SyncQueue.instance.pendingFor('readings')['r1'], {'levelM3': 12.5});
  });
}
