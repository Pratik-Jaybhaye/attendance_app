/// AuthService handles user authentication operations
/// Provides methods for login and registration
import 'user_service.dart';
import '../models/user.dart';

class AuthService {
  // TODO: Replace with your actual API base URL
  static const String apiBaseUrl = 'https://api.example.com';

  /// Login user with username and password
  /// Attempts to authenticate against local database first
  /// Returns user object if successful, null otherwise
  static Future<User?> loginWithUsername(
    String username,
    String password,
  ) async {
    try {
      print('AuthService: Attempting login with username - $username');

      // Try to login with local database first
      final user = await UserService.loginUser(username, password);

      if (user != null) {
        print('AuthService: Login successful - $username');
        return user;
      }

      // TODO: If local login fails, try API endpoint:
      // final response = await http.post(
      //   Uri.parse('$apiBaseUrl/api/auth/login'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'username': username,
      //     'password': password,
      //   }),
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   return data['token'];
      // } else if (response.statusCode == 401) {
      //   print('AuthService: Invalid credentials');
      //   return null;
      // } else {
      //   throw Exception('Login failed: ${response.statusCode}');
      // }

      print('AuthService: Login failed - Invalid credentials');
      return null;
    } catch (e) {
      print('AuthService: Login error - $e');
      return null;
    }
  }

  /// Login user with username and password
  /// Username can be email, mobile number, or any unique identifier
  /// Returns user object if successful, null otherwise
  static Future<User?> login(String username, String password) async {
    try {
      print('AuthService: Attempting login for username - $username');

      // Validate input
      if (username.isEmpty || password.isEmpty) {
        print('AuthService: Username or password is empty');
        return null;
      }

      // Try to login with local database
      final user = await UserService.loginUser(username, password);

      if (user != null) {
        print('AuthService: Login successful - $username');
        return user;
      }

      print('AuthService: Login failed - Invalid credentials');
      return null;
    } catch (e) {
      print('AuthService: Login error - $e');
      return null;
    }
  }

  /// Register new user with username, email and password
  /// Saves user to local database
  /// Returns true if registration successful, false otherwise
  ///
  /// API Endpoint: POST /api/auth/register
  /// Request body:
  /// {
  ///   "username": "username",
  ///   "email": "user@example.com",
  ///   "password": "password123",
  ///   "name": "User Name" (optional)
  /// }
  ///
  /// Response body:
  /// {
  ///   "success": true,
  ///   "message": "User registered successfully",
  ///   "userId": "user_id_here"
  /// }
  static Future<bool> registerWithUsername({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      print('AuthService: Attempting registration for $username');

      // Register user in local database
      final registered = await UserService.registerUser(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );

      if (registered) {
        print('AuthService: User registered successfully - $username');
        return true;
      }

      // TODO: Replace with actual API endpoint
      // For now, this is a mock implementation
      // Uncomment the code below when API is ready:

      // final response = await http.post(
      //   Uri.parse('$apiBaseUrl/api/auth/register'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'username': username,
      //     'email': email,
      //     'password': password,
      //     'fullName': fullName,
      //   }),
      // );
      //
      // if (response.statusCode == 201) {
      //   print('AuthService: Registration successful');
      //   return true;
      // } else if (response.statusCode == 409) {
      //   print('AuthService: Username or email already exists');
      //   return false;
      // } else {
      //   throw Exception('Registration failed: ${response.statusCode}');
      // }

      return false;
    } catch (e) {
      print('AuthService: Registration error - $e');
      return false;
    }
  }

  /// Register new user with username and password
  /// Username can be email (user@gmail.com), mobile number (9876543210), or any unique identifier
  /// Saves user to local database
  /// Returns true if registration successful, false otherwise
  ///
  /// Parameters:
  /// - username: Can be email, mobile number, or any unique identifier
  /// - password: Minimum 6 characters
  /// - fullName: Optional full name of user
  static Future<bool> register({
    required String username,
    required String password,
    String? fullName,
  }) async {
    try {
      print('AuthService: Attempting registration for username - $username');

      // Validate input
      if (username.isEmpty || password.isEmpty) {
        print('AuthService: Username or password is empty');
        return false;
      }

      if (password.length < 6) {
        print('AuthService: Password must be at least 6 characters');
        return false;
      }

      // Register user in local database
      // Generate email from username if not already an email
      String email = username;
      if (!username.contains('@')) {
        // If username is mobile or other format, use it as email field too
        email = '$username@app.local';
      }

      final registered = await UserService.registerUser(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );

      if (registered) {
        print('AuthService: User registered successfully - $username');
        return true;
      }

      print('AuthService: Registration failed');
      return false;
    } catch (e) {
      print('AuthService: Registration error - $e');
      return false;
    }
  }

  /// Logout user
  /// Clears authentication token/session
  ///
  /// API Endpoint: POST /api/auth/logout
  /// Headers: Authorization: Bearer {token}
  static Future<bool> logout(String? token) async {
    try {
      // TODO: Implement actual logout API call
      // Example:
      // final response = await http.post(
      //   Uri.parse('$apiBaseUrl/api/auth/logout'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //   },
      // );
      // return response.statusCode == 200;

      // Mock implementation
      print('AuthService: User logged out');
      return true;
    } catch (e) {
      print('AuthService: Logout error - $e');
      return false;
    }
  }
}
