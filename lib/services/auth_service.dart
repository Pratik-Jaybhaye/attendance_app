/// AuthService handles user authentication operations
/// Provides methods for login and registration
class AuthService {
  // TODO: Replace with your actual API base URL
  static const String apiBaseUrl = 'https://api.example.com';

  /// Login user with email and password
  /// Returns authentication token if successful, null otherwise
  ///
  /// API Endpoint: POST /api/auth/login
  /// Request body:
  /// {
  ///   "email": "user@example.com",
  ///   "password": "password123"
  /// }
  ///
  /// Response body:
  /// {
  ///   "token": "jwt_token_here",
  ///   "userId": "user_id_here"
  /// }
  static Future<String?> login(String email, String password) async {
    try {
      print('AuthService: Attempting login for $email');

      // TODO: Replace with actual API endpoint
      // For now, this is a mock implementation
      // Uncomment the code below when API is ready:

      // final response = await http.post(
      //   Uri.parse('$apiBaseUrl/api/auth/login'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'email': email,
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

      // MOCK IMPLEMENTATION: Remove when API is ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock successful login for demo purposes
      // Replace with actual API call
      if (email.isNotEmpty && password.isNotEmpty) {
        print('AuthService: Mock login successful');
        return 'mock_token_${email.hashCode}';
      }

      return null;
    } catch (e) {
      print('AuthService: Login error - $e');
      return null;
    }
  }

  /// Register new user with email and password
  /// Returns true if registration successful, false otherwise
  ///
  /// API Endpoint: POST /api/auth/register
  /// Request body:
  /// {
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
  static Future<bool> register(String email, String password) async {
    try {
      print('AuthService: Attempting registration for $email');

      // TODO: Replace with actual API endpoint
      // For now, this is a mock implementation
      // Uncomment the code below when API is ready:

      // final response = await http.post(
      //   Uri.parse('$apiBaseUrl/api/auth/register'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'email': email,
      //     'password': password,
      //   }),
      // );
      //
      // if (response.statusCode == 201) {
      //   print('AuthService: Registration successful');
      //   return true;
      // } else if (response.statusCode == 409) {
      //   print('AuthService: Email already exists');
      //   return false;
      // } else {
      //   throw Exception('Registration failed: ${response.statusCode}');
      // }

      // MOCK IMPLEMENTATION: Remove when API is ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock successful registration for demo purposes
      // Replace with actual API call
      if (email.isNotEmpty && password.isNotEmpty && password.length >= 6) {
        print('AuthService: Mock registration successful');
        return true;
      }

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
