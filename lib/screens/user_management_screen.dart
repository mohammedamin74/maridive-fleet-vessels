import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/app_user.dart';
import '../state/auth_provider.dart';
import '../theme/app_colors.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final users = auth.users;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.manageUsers),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => _showAddUserSheet(context, t),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = users[index];
          final isSelf = user.username == auth.currentUser?.username;
          final locked = user.username == 'admin' || isSelf;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (user.isAdmin
                        ? AppColors.teal500
                        : AppColors.navy500)
                    .withValues(alpha: 0.18),
                child: Icon(
                  user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
                  color: user.isAdmin ? AppColors.teal600 : AppColors.navy500,
                ),
              ),
              title: Text(user.displayName),
              subtitle: Text(
                  '@${user.username} · ${user.isAdmin ? t.adminRole : t.userRole}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: t.changePassword,
                    icon: const Icon(Icons.key_outlined),
                    onPressed: () =>
                        _showChangePasswordSheet(context, t, user.username),
                  ),
                  IconButton(
                    tooltip: t.delete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: locked
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.25)
                          : AppColors.statusMaintenance,
                    ),
                    onPressed: locked
                        ? null
                        : () => context
                            .read<AuthProvider>()
                            .removeUser(user.username),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddUserSheet(BuildContext context, AppLocalizations t) {
    final userController = TextEditingController();
    final nameController = TextEditingController();
    final passController = TextEditingController();
    bool isAdmin = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Padding(
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
                  Text(t.addUser,
                      style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userController,
                    decoration: InputDecoration(labelText: t.usernameLabel),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: t.displayNameLabel),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passController,
                    decoration: InputDecoration(labelText: t.passwordLabel),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.makeAdmin),
                    value: isAdmin,
                    onChanged: (v) => setState(() => isAdmin = v),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 4),
                    Text(error!,
                        style: const TextStyle(
                            color: AppColors.statusMaintenance)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final res = context.read<AuthProvider>().addUser(
                              username: userController.text,
                              displayName: nameController.text,
                              password: passController.text,
                              isAdmin: isAdmin,
                            );
                        if (res == 'userExists') {
                          setState(() => error = t.userExists);
                        } else if (res == 'required') {
                          setState(() => error = t.fieldsRequired);
                        } else {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: Text(t.save),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordSheet(
      BuildContext context, AppLocalizations t, String username) {
    final passController = TextEditingController();
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Padding(
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
                  Text('${t.changePassword} · @$username',
                      style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    decoration: InputDecoration(labelText: t.newPasswordLabel),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!,
                        style: const TextStyle(
                            color: AppColors.statusMaintenance)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final res = context
                            .read<AuthProvider>()
                            .changePassword(username, passController.text);
                        if (res == 'required') {
                          setState(() => error = t.fieldsRequired);
                        } else {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.passwordChanged)),
                          );
                        }
                      },
                      child: Text(t.save),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
