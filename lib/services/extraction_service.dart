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

/// Result of a generic extraction. Exactly one of [fields]/[items] is
/// populated, depending on the kind's server-side mode: single-record kinds
/// (defect, port_call, handover, …) fill [fields]; row-per-item kinds
/// (requisition, tank_reading, certificates, crew, …) fill [items].
class ExtractionResult {
  final String kind;
  final Map<String, dynamic>? fields;
  final List<Map<String, dynamic>>? items;
  const ExtractionResult({required this.kind, this.fields, this.items});

  bool get isList => items != null;
}

/// Calls the `extract` Edge Function, which reads an already-uploaded file
/// from Storage and returns structured fields for any registered module kind.
/// The file must already live in Storage (an [Attachment] with a storagePath).
/// AI output is NEVER saved directly — every caller shows it in an editable
/// review sheet first.
class ExtractionService {
  // Cold boots plus free-tier model latency were measured at ~50-90s for a
  // real parts list, and the server walks a fallback chain of free models
  // with a 135s internal deadline — shorter timeouts made the client give
  // up on good requests. (Free models are a hard project constraint.)
  static const Duration _timeout = Duration(seconds: 150);

  /// Generic entry point: works for every kind registered in the edge
  /// function's KINDS map (defect, requisition, tank_reading, logbook,
  /// maintenance, port_call, port_requirement, vessel_certificate,
  /// crew_certificate, crew, daily_task, urgent_notification, handover).
  static Future<ExtractionResult> extractFor({
    required String storagePath,
    required String kind,
  }) async {
    final data = await _invoke(storagePath, kind);
    final payload = data['data'];
    if (payload is List) {
      return ExtractionResult(
        kind: kind,
        items: payload
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(),
      );
    }
    if (payload is Map) {
      return ExtractionResult(
        kind: kind,
        fields: Map<String, dynamic>.from(payload),
      );
    }
    throw ExtractionException('unexpected');
  }

  /// [kind] is a fields-mode kind (e.g. 'defect'). Returns the extracted
  /// field map (the caller shows it in an editable review sheet before
  /// saving anything).
  static Future<Map<String, dynamic>> extract({
    required String storagePath,
    required String kind,
  }) async {
    final res = await extractFor(storagePath: storagePath, kind: kind);
    final fields = res.fields;
    if (fields == null) throw ExtractionException('unexpected');
    return fields;
  }

  /// Same as [extract], but for list-mode kinds (e.g. 'requisition') that
  /// return one entry per document row. Each entry is still reviewed
  /// individually before saving.
  static Future<List<Map<String, dynamic>>> extractList({
    required String storagePath,
    required String kind,
  }) async {
    final res = await extractFor(storagePath: storagePath, kind: kind);
    final items = res.items;
    if (items == null) throw ExtractionException('unexpected');
    return items;
  }

  static Future<Map> _invoke(String storagePath, String kind) async {
    try {
      final res = await SupabaseConfig.client.functions
          .invoke('extract', body: {'path': storagePath, 'kind': kind})
          .timeout(_timeout);
      final data = res.data;
      if (data is Map) return data;
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
