import 'package:supabase_flutter/supabase_flutter.dart';

import 'assistant_service.dart' show AssistantException, ChatMessage;
import 'supabase_config.dart';

/// Calls the `fleet-ai` Edge Function: fleet questions answered from a
/// minimal structured snapshot this client builds from data it already read
/// under RLS. The function has no database access of its own, so the model
/// can never see more than the signed-in user can.
///
/// Answers are advisory and must be presented as AI output for human review —
/// see [BriefingService.aiContext] for exactly what is (and is not) sent.
class FleetAiService {
  static Future<String> ask({
    required List<ChatMessage> history,
    required Map<String, dynamic> context,
  }) async {
    try {
      final res = await SupabaseConfig.client.functions.invoke(
        'fleet-ai',
        body: {
          'messages': history.map((m) => m.toJson()).toList(),
          'context': context,
        },
      );
      final data = res.data;
      if (data is Map && data['text'] is String) {
        return _plainText(data['text'] as String);
      }
      throw AssistantException('unexpected');
    } on FunctionException catch (e) {
      final details = e.details;
      final code = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : 'request_failed';
      throw AssistantException(code);
    }
  }

  /// Models habitually answer in Markdown, which the app renders as plain
  /// text (and prints into PDFs) — so `**bold**` would show up as literal
  /// asterisks. Strip the few markers they actually use rather than pulling
  /// in a Markdown renderer for one label.
  static String _plainText(String raw) => raw
      .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*', dotAll: true), (m) => m[1]!)
      // Single asterisks only when they wrap a word — "5 * 3" stays intact.
      .replaceAllMapped(
          RegExp(r'(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])', dotAll: true),
          (m) => m[1]!)
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '• ')
      .trim();
}
