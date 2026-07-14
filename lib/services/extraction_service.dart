import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Thrown when AI extraction can't complete. [code] is a stable machine code
/// (e.g. 'not_configured', 'download_failed', 'ai_failed') the UI maps to a
/// friendly, localized message.
class ExtractionException implements Exception {
  final String code;
  ExtractionException(this.code);
  @override
  String toString() => 'ExtractionException($code)';
}

/// Calls the `extract` Edge Function, which reads an already-uploaded file from
/// Storage and returns structured defect/requisition fields via Gemini. The
/// file must already live in Storage (an [Attachment] with a storagePath).
class ExtractionService {
  /// [kind] is 'defect' or 'requisition'. Returns the extracted field map (the
  /// caller shows it in an editable review sheet before saving anything).
  static Future<Map<String, dynamic>> extract({
    required String storagePath,
    required String kind,
  }) async {
    try {
      final res = await SupabaseConfig.client.functions
          .invoke('extract', body: {'path': storagePath, 'kind': kind})
          .timeout(const Duration(seconds: 45));
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      throw ExtractionException('unexpected');
    } on FunctionException catch (e) {
      final details = e.details;
      final code = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : 'request_failed';
      throw ExtractionException(code);
    } on TimeoutException {
      throw ExtractionException('timeout');
    }
  }

  /// Same as [extract], but for kinds (currently 'requisition') that return a
  /// list of items — e.g. every row of an uploaded parts list — instead of a
  /// single object. Each entry is still reviewed individually before saving.
  static Future<List<Map<String, dynamic>>> extractList({
    required String storagePath,
    required String kind,
  }) async {
    try {
      final res = await SupabaseConfig.client.functions
          .invoke('extract', body: {'path': storagePath, 'kind': kind})
          .timeout(const Duration(seconds: 45));
      final data = res.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      throw ExtractionException('unexpected');
    } on FunctionException catch (e) {
      final details = e.details;
      final code = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : 'request_failed';
      throw ExtractionException(code);
    } on TimeoutException {
      throw ExtractionException('timeout');
    }
  }
}
