/// User Model
/// Represents user data including login credentials
class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final String? fullName;
  final String? profileImagePath;
  final String? role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
    this.profileImagePath,
    this.role,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });

  /// Factory constructor for creating User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      fullName: json['full_name'],
      profileImagePath: json['profile_image_path'],
      role: json['role'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'profile_image_path': profileImagePath,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Create a copy of User with modified fields
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? fullName,
    String? profileImagePath,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}
