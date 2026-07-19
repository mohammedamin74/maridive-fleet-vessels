import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/gen/app_localizations.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_state.dart';
import 'state/auth_provider.dart';
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
      home: const _AuthGate(),
    );
  }
}

/// Shows the login screen until a user signs in, then the adaptive shell
/// (rail/bar + tabs). Because the signed-in user is held in memory, every
/// app launch starts here.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return auth.isAuthenticated ? const HomeShell() : const LoginScreen();
  }
}
