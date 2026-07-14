import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// One turn in a session-only chat with the help assistant. Never persisted —
/// history lives only in the screen's state for the lifetime of the chat.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// Thrown when the assistant can't answer. [code] is a stable machine code
/// ('not_configured', 'rate_limited', 'ai_failed', ...) the UI maps to a
/// friendly, localized message.
class AssistantException implements Exception {
  final String code;
  AssistantException(this.code);
  @override
  String toString() => 'AssistantException($code)';
}

/// Calls the `assistant` Edge Function: a help-only chatbot answering
/// how-to-use-the-app questions via Gemini (free tier). Only the user's typed
/// messages are sent — never vessel data, readings, or crew/PII.
class AssistantService {
  static Future<String> send(List<ChatMessage> history) async {
    try {
      final res = await SupabaseConfig.client.functions.invoke(
        'assistant',
        body: {'messages': history.map((m) => m.toJson()).toList()},
      );
      final data = res.data;
      if (data is Map && data['text'] is String) {
        return data['text'] as String;
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
}
