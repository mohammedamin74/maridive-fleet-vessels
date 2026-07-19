import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/auth_provider.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final t = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await context
        .read<AuthProvider>()
        .login(_userController.text, _passController.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = switch (result) {
        null => null,
        'networkError' => t.networkError,
        _ => t.invalidCredentials,
      };
    });
    // On success the AuthGate rebuilds automatically into the dashboard.
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 96,
                      width: 96,
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppColors.slate200),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy900.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/branding/mos-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.signInPrompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _userController,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      labelText: t.usernameLabel,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passController,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: t.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        tooltip: _obscure ? t.showPassword : t.hidePassword,
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.statusMaintenance, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: AppColors.statusMaintenance),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(t.loginButton),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.offlineAuthNote,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
