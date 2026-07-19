import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';

/// Runs a PDF export and reports success/failure via a snackbar. The export
/// itself now opens a native Save As dialog rather than the OS share sheet,
/// so callers need their own feedback instead of relying on the share
/// sheet's UI for confirmation.
Future<void> exportPdfWithFeedback(BuildContext context, AppLocalizations t,
    Future<void> Function() export) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await export();
    messenger.showSnackBar(SnackBar(content: Text(t.fileSaved)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(t.downloadFailed)));
  }
}
