/// A local application user account. Passwords are never stored directly —
/// only a per-user random [salt] and the SHA-256 hash of salt+password.
class AppUser {
  final String username;
  final String displayName;
  final String passwordHash;
  final String salt;
  final bool isAdmin;
  final DateTime createdAt;

  const AppUser({
    required this.username,
    required this.displayName,
    required this.passwordHash,
    required this.salt,
    required this.isAdmin,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'displayName': displayName,
        'passwordHash': passwordHash,
        'salt': salt,
        'isAdmin': isAdmin,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
        username: map['username'] as String,
        displayName: (map['displayName'] as String?) ?? (map['username'] as String),
        passwordHash: map['passwordHash'] as String,
        salt: (map['salt'] as String?) ?? '',
        isAdmin: (map['isAdmin'] as bool?) ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
