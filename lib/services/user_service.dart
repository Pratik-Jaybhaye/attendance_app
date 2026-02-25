import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import '../models/user.dart';

/// UserService handles user-related operations
/// Provides methods for user registration, login, and management
class UserService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // ==================== REGISTRATION ====================

  /// Register a new user
  /// Returns true if registration successful, false otherwise
  static Future<bool> registerUser({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      print('UserService: Registering user - $username');

      // Check if username already exists
      final usernameExists = await _dbHelper.usernameExists(username);
      if (usernameExists) {
        print('UserService: Username already exists - $username');
        return false;
      }

      // Check if email already exists
      final emailExists = await _dbHelper.emailExists(email);
      if (emailExists) {
        print('UserService: Email already exists - $email');
        return false;
      }

      // Create new user
      final newUser = User(
        id: const Uuid().v4(),
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        createdAt: DateTime.now(),
      );

      // Save to database
      final saved = await _dbHelper.saveUser(newUser);

      if (saved) {
        print('UserService: User registered successfully - $username');
      }

      return saved;
    } catch (e) {
      print('UserService: Error registering user - $e');
      return false;
    }
  }

  // ==================== LOGIN ====================

  /// Login user with username and password
  /// Returns user if login successful, null otherwise
  static Future<User?> loginUser(String username, String password) async {
    try {
      print('UserService: Attempting login - $username');

      // Verify credentials
      final user = await _dbHelper.verifyCredentials(username, password);

      if (user != null) {
        print('UserService: Login successful for user - $username');
      } else {
        print('UserService: Login failed for user - $username');
      }

      return user;
    } catch (e) {
      print('UserService: Error during login - $e');
      return null;
    }
  }

  // ==================== RETRIEVE USER ====================

  /// Get current user by username
  static Future<User?> getUserByUsername(String username) async {
    try {
      print('UserService: Fetching user - $username');
      return await _dbHelper.getUserByUsername(username);
    } catch (e) {
      print('UserService: Error getting user - $e');
      return null;
    }
  }

  /// Get user by email
  static Future<User?> getUserByEmail(String email) async {
    try {
      return await _dbHelper.getUserByEmail(email);
    } catch (e) {
      print('UserService: Error getting user by email - $e');
      return null;
    }
  }

  /// Get user by ID
  static Future<User?> getUserById(String userId) async {
    try {
      return await _dbHelper.getUserById(userId);
    } catch (e) {
      print('UserService: Error getting user by ID - $e');
      return null;
    }
  }

  /// Get all users
  static Future<List<User>> getAllUsers() async {
    try {
      return await _dbHelper.getAllUsers();
    } catch (e) {
      print('UserService: Error getting all users - $e');
      return [];
    }
  }

  // ==================== UPDATE USER ====================

  /// Update user profile information
  static Future<bool> updateUserProfile({
    required String userId,
    String? fullName,
    String? profileImagePath,
  }) async {
    try {
      print('UserService: Updating user profile - $userId');

      // Get existing user
      final user = await _dbHelper.getUserById(userId);

      if (user == null) {
        print('UserService: User not found - $userId');
        return false;
      }

      // Create updated user
      final updatedUser = user.copyWith(
        fullName: fullName ?? user.fullName,
        profileImagePath: profileImagePath ?? user.profileImagePath,
      );

      // Save to database
      final updated = await _dbHelper.updateUser(updatedUser);

      if (updated) {
        print('UserService: User profile updated successfully');
      }

      return updated;
    } catch (e) {
      print('UserService: Error updating user profile - $e');
      return false;
    }
  }

  /// Change user password
  static Future<bool> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      print('UserService: Changing password for user - $userId');

      // Get user
      final user = await _dbHelper.getUserById(userId);

      if (user == null) {
        print('UserService: User not found - $userId');
        return false;
      }

      // Verify old password
      if (user.password != oldPassword) {
        print('UserService: Old password is incorrect');
        return false;
      }

      // Update password
      final updated = await _dbHelper.updateUserPassword(userId, newPassword);

      if (updated) {
        print('UserService: Password changed successfully');
      }

      return updated;
    } catch (e) {
      print('UserService: Error changing password - $e');
      return false;
    }
  }

  // ==================== DELETE USER ====================

  /// Delete user by ID
  static Future<bool> deleteUser(String userId) async {
    try {
      print('UserService: Deleting user - $userId');
      final deleted = await _dbHelper.deleteUser(userId);

      if (deleted) {
        print('UserService: User deleted successfully');
      }

      return deleted;
    } catch (e) {
      print('UserService: Error deleting user - $e');
      return false;
    }
  }

  // ==================== UTILITY ====================

  /// Check if user exists
  static Future<bool> userExists(String username) async {
    try {
      return await _dbHelper.usernameExists(username);
    } catch (e) {
      print('UserService: Error checking user - $e');
      return false;
    }
  }

  /// Get total user count
  static Future<int> getUserCount() async {
    try {
      return await _dbHelper.getTotalUserCount();
    } catch (e) {
      print('UserService: Error getting user count - $e');
      return 0;
    }
  }

  /// Search users by username or email
  static Future<List<User>> searchUsers(String query) async {
    try {
      final allUsers = await _dbHelper.getAllUsers();

      return allUsers
          .where(
            (user) =>
                user.username.toLowerCase().contains(query.toLowerCase()) ||
                user.email.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      print('UserService: Error searching users - $e');
      return [];
    }
  }
}
