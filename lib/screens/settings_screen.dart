import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(t.english)),
              ButtonSegment(value: 'ar', label: Text(t.arabic)),
            ],
            selected: {appState.locale.languageCode},
            onSelectionChanged: (selected) {
              context.read<AppState>().setLocale(Locale(selected.first));
            },
          ),
          const SizedBox(height: 28),
          Text(t.theme, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark)),
              ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight)),
            ],
            selected: {appState.themeMode},
            onSelectionChanged: (selected) {
              context.read<AppState>().setThemeMode(selected.first);
            },
          ),
          const SizedBox(height: 32),
          Text(t.about, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(t.aboutBody, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
