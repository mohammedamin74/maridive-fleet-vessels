import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../services/supabase_config.dart';

/// Cloud authentication backed by Supabase. Team members share one account
/// list; the signed-in session is persisted by Supabase (so users stay logged
/// in across launches until they log out). Usernames are mapped to hidden
/// `username@maridive.app` addresses, so the team only ever types a username.
///
/// Creating, deleting, and password-resetting *other* users requires admin
/// privileges and is done server-side by the `admin-users` Edge Function.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _sb = SupabaseConfig.client;
  AppUser? _current;
  List<AppUser> _users = [];
  bool _loading = true;

  AuthProvider() {
    _restore();
  }

  AppUser? get currentUser => _current;
  bool get isAuthenticated => _current != null;
  bool get isAdmin => _current?.isAdmin ?? false;
  bool get loading => _loading;
  List<AppUser> get users => _users;

  static const String _emailDomain = '@maridive.app';
  static String _emailFor(String username) =>
      '${username.trim().toLowerCase()}$_emailDomain';

  Future<void> _restore() async {
    try {
      if (_sb.auth.currentUser != null) {
        await _loadProfile();
      }
    } catch (_) {
      // Ignore restore errors; user just lands on the login screen.
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      _current = null;
      return;
    }
    final row = await _sb
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    _current = row != null ? AppUser.fromProfile(row) : null;
  }

  /// Returns null on success, or an error code: 'invalidCredentials' (the
  /// username/password really are wrong) or 'networkError' (the request
  /// never reached the server — offline, timeout, DNS — so the credentials
  /// were never actually checked). Conflating the two used to tell an
  /// offline mariner their password was wrong.
  Future<String?> login(String username, String password) async {
    try {
      await _sb.auth.signInWithPassword(
        email: _emailFor(username),
        password: password,
      );
      await _loadProfile();
      notifyListeners();
      return _current == null ? 'invalidCredentials' : null;
    } on AuthException {
      // The server responded — it rejected the credentials.
      return 'invalidCredentials';
    } catch (_) {
      // No response reached us at all: connectivity, not credentials.
      return 'networkError';
    }
  }

  Future<void> logout() async {
    await _sb.auth.signOut();
    _current = null;
    _users = [];
    notifyListeners();
  }

  Future<void> refreshUsers() async {
    try {
      final rows = await _sb.from('profiles').select();
      _users = (rows as List)
          .map((r) => AppUser.fromProfile(r as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.username.compareTo(b.username));
      notifyListeners();
    } catch (_) {
      // Leave the existing list on failure.
    }
  }

  /// Calls the admin-users Edge Function. Returns null on success or an error
  /// message. Requires the function to be deployed and the caller to be admin.
  Future<String?> _adminAction(Map<String, dynamic> body) async {
    try {
      final res = await _sb.functions.invoke('admin-users', body: body);
      final data = res.data;
      if (res.status == 200) {
        await refreshUsers();
        return null;
      }
      if (data is Map && data['error'] != null) return data['error'].toString();
      return 'requestFailed';
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] != null) {
        return details['error'].toString();
      }
      return 'requestFailed';
    } catch (_) {
      return 'requestFailed';
    }
  }

  Future<String?> addUser({
    required String username,
    required String displayName,
    required String password,
    bool isAdmin = false,
  }) {
    if (username.trim().isEmpty || password.isEmpty) {
      return Future.value('required');
    }
    return _adminAction({
      'action': 'create',
      'username': username.trim().toLowerCase(),
      'displayName': displayName.trim(),
      'password': password,
      'isAdmin': isAdmin,
    });
  }

  Future<String?> removeUser(String username) {
    if (username == 'admin' || username == _current?.username) {
      return Future.value(null);
    }
    return _adminAction({'action': 'delete', 'username': username});
  }

  Future<String?> changePassword(String username, String newPassword) async {
    if (newPassword.isEmpty) return 'required';
    // Changing your own password can go straight through the client session.
    if (username == _current?.username) {
      try {
        await _sb.auth.updateUser(UserAttributes(password: newPassword));
        return null;
      } catch (_) {
        return 'requestFailed';
      }
    }
    return _adminAction({
      'action': 'reset',
      'username': username,
      'password': newPassword,
    });
  }
}
