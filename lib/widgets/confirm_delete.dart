import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';

/// Shared confirmation gate for every destructive delete in the app.
/// Previously every delete icon called the provider straight away — one
/// mis-tap, no confirmation, no way back. Await this before deleting
/// anything; only proceed if it resolves true.
Future<bool> confirmDelete(BuildContext context, {required String itemName}) async {
  final t = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.confirmDeleteTitle),
      content: Text(t.confirmDeleteMessage(itemName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.delete),
        ),
      ],
    ),
  );
  return result ?? false;
}
