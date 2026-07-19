// Content-hash dedup is the primitive IngestionBatchProvider.addFiles uses
// to reject a byte-identical re-upload within a batch before spending a
// Storage upload or an extraction call on it. addFiles itself needs a live
// Supabase client (like SyncQueue.flush(), per sync_queue_test.dart) and is
// exercised manually — this pins the hash equality/inequality it relies on.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identical bytes produce the same content hash', () {
    final a = utf8.encode('same file contents');
    final b = utf8.encode('same file contents');
    expect(sha256.convert(a).toString(), sha256.convert(b).toString());
  });

  test('a single differing byte produces a different hash', () {
    final a = utf8.encode('same file contents');
    final b = utf8.encode('same file contentz');
    expect(sha256.convert(a).toString(), isNot(sha256.convert(b).toString()));
  });

  test('a seen-hashes set correctly flags a repeat within a batch', () {
    final seen = <String>{};
    bool isDuplicate(List<int> bytes) {
      final hash = sha256.convert(bytes).toString();
      if (seen.contains(hash)) return true;
      seen.add(hash);
      return false;
    }

    expect(isDuplicate(utf8.encode('report.pdf-bytes')), isFalse);
    expect(isDuplicate(utf8.encode('another.pdf-bytes')), isFalse);
    expect(isDuplicate(utf8.encode('report.pdf-bytes')), isTrue);
  });
}
