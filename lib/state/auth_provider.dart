import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/app_user.dart';

/// Local, offline authentication. Accounts live in a Hive box; the signed-in
/// user is held in memory only, so the app requires a fresh login on every
/// launch. Passwords are stored as a per-user salt plus a SHA-256 hash, never
/// in plain text.
class AuthProvider extends ChangeNotifier {
  final Box box;
  AppUser? _current;

  AuthProvider({required this.box}) {
    _seedDefaultAdmin();
  }

  AppUser? get currentUser => _current;
  bool get isAuthenticated => _current != null;
  bool get isAdmin => _current?.isAdmin ?? false;

  List<AppUser> get users {
    final list = box.values.map((e) => AppUser.fromMap(e as Map)).toList();
    list.sort((a, b) => a.username.compareTo(b.username));
    return list;
  }

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  static String _newSalt() {
    final r = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  void _seedDefaultAdmin() {
    if (box.isEmpty) {
      final salt = _newSalt();
      box.put(
        'admin',
        AppUser(
          username: 'admin',
          displayName: 'Administrator',
          salt: salt,
          passwordHash: _hash(salt, 'Maridive@2026'),
          isAdmin: true,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    }
  }

  /// Returns null on success, or an error code ('invalidCredentials').
  String? login(String username, String password) {
    final key = username.trim().toLowerCase();
    final raw = box.get(key);
    if (raw == null) return 'invalidCredentials';
    final user = AppUser.fromMap(raw as Map);
    if (_hash(user.salt, password) != user.passwordHash) {
      return 'invalidCredentials';
    }
    _current = user;
    notifyListeners();
    return null;
  }

  void logout() {
    _current = null;
    notifyListeners();
  }

  /// Returns null on success, or an error code ('required' | 'userExists').
  String? addUser({
    required String username,
    required String displayName,
    required String password,
    bool isAdmin = false,
  }) {
    final key = username.trim().toLowerCase();
    if (key.isEmpty || password.isEmpty) return 'required';
    if (box.containsKey(key)) return 'userExists';
    final salt = _newSalt();
    box.put(
      key,
      AppUser(
        username: key,
        displayName:
            displayName.trim().isEmpty ? username.trim() : displayName.trim(),
        salt: salt,
        passwordHash: _hash(salt, password),
        isAdmin: isAdmin,
        createdAt: DateTime.now(),
      ).toMap(),
    );
    notifyListeners();
    return null;
  }

  Future<void> removeUser(String username) async {
    final key = username.toLowerCase();
    // Never delete the built-in admin or the account currently signed in.
    if (key == 'admin' || key == _current?.username) return;
    await box.delete(key);
    notifyListeners();
  }

  /// Returns null on success, or an error code ('required' | 'notFound').
  String? changePassword(String username, String newPassword) {
    final key = username.toLowerCase();
    if (newPassword.isEmpty) return 'required';
    final raw = box.get(key);
    if (raw == null) return 'notFound';
    final user = AppUser.fromMap(raw as Map);
    final salt = _newSalt();
    box.put(
      key,
      AppUser(
        username: user.username,
        displayName: user.displayName,
        salt: salt,
        passwordHash: _hash(salt, newPassword),
        isAdmin: user.isAdmin,
        createdAt: user.createdAt,
      ).toMap(),
    );
    if (_current?.username == key) {
      _current = AppUser.fromMap(box.get(key) as Map);
    }
    notifyListeners();
    return null;
  }
}
