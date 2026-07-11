import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment.dart';
import 'supabase_config.dart';

/// Reads and writes attachment bytes to the shared Supabase Storage bucket,
/// with an in-memory cache.
///
/// Records keep only a small storage *path*; the actual file bytes live in
/// Storage, so large PDFs no longer bloat the database rows (which have a
/// realtime/size ceiling) and every user downloads the same file. Legacy
/// attachments that still carry inline base64 keep working unchanged.
class AttachmentStore {
  static const String bucket = 'attachments';
  static final Map<String, Uint8List> _cache = {};

  static SupabaseClient get _sb => SupabaseConfig.client;

  /// Uploads [bytes] under a unique path and returns an [Attachment] that
  /// references the stored object. If the upload fails (offline, etc.), falls
  /// back to an inline base64 attachment so a picked file is never lost.
  static Future<Attachment> upload(String name, Uint8List bytes) async {
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '${DateTime.now().microsecondsSinceEpoch}_$safe';
    try {
      await _sb.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      _cache[path] = bytes;
      return Attachment(name: name, storagePath: path);
    } catch (_) {
      return Attachment(name: name, dataBase64: base64Encode(bytes));
    }
  }

  /// Uploads [bytes] to a fixed, deterministic [path] (overwriting) and returns
  /// an [Attachment] referencing it. Used for idempotent seeding, where the same
  /// path must be reused across devices so re-runs don't create duplicates.
  static Future<Attachment> uploadAt(
      String path, String name, Uint8List bytes) async {
    await _sb.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    _cache[path] = bytes;
    return Attachment(name: name, storagePath: path);
  }

  /// Bytes available synchronously right now: inline attachments decode
  /// instantly; cloud attachments return cached bytes or null if not yet
  /// downloaded.
  static Uint8List? peek(Attachment a) {
    if (!a.isCloud) return base64Decode(a.dataBase64);
    return _cache[a.storagePath!];
  }

  /// Bytes for an attachment, downloading (and caching) from Storage on first
  /// access for cloud attachments.
  static Future<Uint8List> bytes(Attachment a) async {
    if (!a.isCloud) return base64Decode(a.dataBase64);
    final path = a.storagePath!;
    final hit = _cache[path];
    if (hit != null) return hit;
    final data = await _sb.storage.from(bucket).download(path);
    _cache[path] = data;
    return data;
  }
}
