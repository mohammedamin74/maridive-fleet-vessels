import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/gen/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class MaridiveFleetApp extends StatelessWidget {
  const MaridiveFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: appState.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const DashboardScreen(),
    );
  }
}
