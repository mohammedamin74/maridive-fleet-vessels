import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../state/auth_provider.dart';
import '../theme/app_colors.dart';
import 'user_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _changeOwnPassword(BuildContext context, AppLocalizations t) {
    final auth = context.read<AuthProvider>();
    final username = auth.currentUser?.username;
    if (username == null) return;
    final passController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.changePassword,
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              decoration: InputDecoration(labelText: t.newPasswordLabel),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (passController.text.isEmpty) return;
                  auth.changePassword(username, passController.text);
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.passwordChanged)),
                  );
                },
                child: Text(t.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null) ...[
            Text(t.account, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.teal500.withValues(alpha: 0.18),
                  child: Icon(
                      user.isAdmin ? Icons.shield_outlined : Icons.person,
                      color: AppColors.teal600),
                ),
                title: Text(user.displayName),
                subtitle: Text(
                    '@${user.username} · ${user.isAdmin ? t.adminRole : t.userRole}'),
              ),
            ),
            const SizedBox(height: 8),
            if (auth.isAdmin)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const UserManagementScreen()),
                ),
                icon: const Icon(Icons.group_outlined),
                label: Text(t.manageUsers),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _changeOwnPassword(context, t),
              icon: const Icon(Icons.key_outlined),
              label: Text(t.changePassword),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusMaintenance),
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              icon: const Icon(Icons.logout),
              label: Text(t.logOut),
            ),
            const SizedBox(height: 28),
          ],
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
