import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../services/extraction_service.dart';
import 'attachment_picker.dart';

/// Everything a completed AI extraction hands back to a module screen: the
/// structured result plus the uploaded source file, so the reviewed record
/// can keep the original document attached as evidence.
class AiFillOutcome {
  final ExtractionResult result;
  final Attachment file;
  const AiFillOutcome({required this.result, required this.file});
}

/// Shared plumbing for "AI fill from file" across every module: pick a file,
/// upload it to Storage, show a blocking progress dialog while the `extract`
/// Edge Function reads it, and surface errors as snackbars. Returns null when
/// the user cancels or extraction fails (after telling the user why).
///
/// The AI output is NEVER saved by this helper — callers open their normal
/// add/edit sheet pre-filled with [AiFillOutcome.result] so a human reviews
/// and edits every field before anything persists.
Future<AiFillOutcome?> pickAndExtract(
  BuildContext context,
  AppLocalizations t, {
  required String kind,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final picked = await pickAttachment();
  if (picked == null) return null;
  if (!picked.isCloud) {
    messenger.showSnackBar(SnackBar(content: Text(t.extractionFailed)));
    return null;
  }
  if (!context.mounted) return null;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ExtractingDialog(message: t.extractingFile),
  );

  try {
    final result = await ExtractionService.extractFor(
        storagePath: picked.storagePath!, kind: kind);
    navigator.pop(); // dismiss the loading dialog
    if (result.isList && result.items!.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(t.extractionFailed)));
      return null;
    }
    return AiFillOutcome(result: result, file: picked);
  } on ExtractionException catch (e) {
    navigator.pop();
    final msg = e.code == 'not_configured'
        ? t.extractionNotConfigured
        : e.code == 'quota_exhausted'
            ? t.extractionQuotaExhausted
            : t.extractionFailed;
    messenger.showSnackBar(SnackBar(content: Text(msg)));
    return null;
  } catch (_) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(t.extractionFailed)));
    return null;
  }
}

/// The standard app-bar entry point for AI-assisted entry, identical on
/// every module screen.
class AiFillAction extends StatelessWidget {
  final VoidCallback onPressed;
  const AiFillAction({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.document_scanner_outlined),
      tooltip: t.extractFromFile,
      onPressed: onPressed,
    );
  }
}

// ---------------------------------------------------------------------------
// Lenient mapping helpers — extracted values arrive as loosely-typed JSON
// from a free-tier model, so every read tolerates nulls and wrong types.
// ---------------------------------------------------------------------------

String aiStr(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  return v == null ? '' : v.toString();
}

String aiStrOr(Map<String, dynamic>? m, String key, String fallback) {
  final s = aiStr(m, key);
  return s.isEmpty ? fallback : s;
}

String aiNumStr(Map<String, dynamic>? m, String key, String fallback) {
  final v = m?[key];
  if (v is num) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }
  return fallback;
}

double? aiNum(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool aiBool(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true' || v.toLowerCase() == 'yes';
  return false;
}

DateTime? aiDate(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v);
}

/// Like [aiDate] but clamped into [first]..[last] — screens that feed the
/// value to a bounded showDatePicker would otherwise crash on an
/// out-of-range extracted date.
DateTime? aiDateIn(
    Map<String, dynamic>? m, String key, DateTime first, DateTime last) {
  final d = aiDate(m, key);
  if (d == null) return null;
  if (d.isBefore(first)) return first;
  if (d.isAfter(last)) return last;
  return d;
}

T aiEnum<T extends Enum>(
    Map<String, dynamic>? m, String key, List<T> values, T fallback) {
  final name = aiStr(m, key);
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Small modal shown while the AI reads an uploaded file.
class _ExtractingDialog extends StatelessWidget {
  final String message;
  const _ExtractingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
