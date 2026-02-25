# Username & Password Database Storage - Usage Guide

## Overview
Username and password are now stored locally in SQLite database. Users can register and login locally without needing an API.

---

## Files Created/Modified

### ✅ New Files Created:
1. **`lib/models/user.dart`** - User model with all user data
2. **`lib/services/user_service.dart`** - Easy-to-use user operations service

### ✅ Modified Files:
1. **`lib/services/database_helper.dart`** 
   - Added users table
   - Added 15+ user-related methods
   - Database version updated to 2

2. **`lib/services/auth_service.dart`**
   - Updated login methods to use local DB
   - Updated register methods to save to local DB

---

## Database Schema - Users Table

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  full_name TEXT,
  profile_image_path TEXT,
  role TEXT,
  created_at TEXT NOT NULL,
  last_login TEXT,
  is_active INTEGER DEFAULT 1
)
```

---

## Usage Examples

### 1️⃣ Register New User

```dart
import 'package:attendance_app/services/user_service.dart';

// Method 1: Register with username
final registered = await UserService.registerUser(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'password123',
  fullName: 'John Doe',
);

if (registered) {
  print('Registration successful!');
} else {
  print('Username or email already exists');
}
```

Or use AuthService:
```dart
import 'package:attendance_app/services/auth_service.dart';

final registered = await AuthService.registerWithUsername(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'password123',
  fullName: 'John Doe',
);
```

---

### 2️⃣ Login User

#### Login with Username:
```dart
import 'package:attendance_app/services/auth_service.dart';

final user = await AuthService.loginWithUsername(
  'john_doe',
  'password123',
);

if (user != null) {
  print('Login successful!');
  print('User: ${user.username}');
  print('Email: ${user.email}');
  
  // Navigate to home screen
  Navigator.of(context).pushReplacementNamed('/home');
} else {
  print('Invalid username or password');
}
```

#### Login with Email:
```dart
final user = await AuthService.login(
  'john@example.com',
  'password123',
);

if (user != null) {
  print('Login successful!');
}
```

---

### 3️⃣ Get User Information

```dart
import 'package:attendance_app/services/user_service.dart';

// Get by username
final user = await UserService.getUserByUsername('john_doe');

// Get by email
final user = await UserService.getUserByEmail('john@example.com');

// Get by ID
final user = await UserService.getUserById('user_id_123');

// Get all users
final allUsers = await UserService.getAllUsers();
for (final user in allUsers) {
  print('${user.username} - ${user.email}');
}
```

---

### 4️⃣ Update User Profile

```dart
import 'package:attendance_app/services/user_service.dart';

final updated = await UserService.updateUserProfile(
  userId: 'user_id_123',
  fullName: 'John Doe Updated',
  profileImagePath: '/path/to/image.jpg',
);

if (updated) {
  print('Profile updated successfully');
}
```

---

### 5️⃣ Change Password

```dart
final changed = await UserService.changePassword(
  userId: 'user_id_123',
  oldPassword: 'password123',
  newPassword: 'newPassword456',
);

if (changed) {
  print('Password changed successfully');
} else {
  print('Old password is incorrect');
}
```

---

### 6️⃣ Search Users

```dart
final results = await UserService.searchUsers('john');
// Returns users matching 'john' in username or email
```

---

## Integration with UI - Complete Example

### Registration Screen

```dart
import 'package:flutter/material.dart';
import 'package:attendance_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      final registered = await AuthService.registerWithUsername(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
      );

      if (!mounted) return;

      if (registered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Registration failed - Username or email already exists'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name (Optional)',
                hintText: 'Enter full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    super.dispose();
  }
}
```

---

### Login Screen

```dart
import 'package:flutter/material.dart';
import 'package:attendance_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.loginWithUsername(
        usernameController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      if (user != null) {
        // Login successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Invalid username or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/register'),
              child: const Text("Don't have an account? Register here"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
```

---

## Important Notes

### Security Considerations
⚠️ **Storing plain text passwords is not ideal for production**

For better security:
1. Hash passwords before storing:
```dart
import 'package:crypto/crypto.dart';

// Hash password
String hashedPassword = sha256.convert(utf8.encode(password)).toString();
```

2. Consider using encryption:
```dart
import 'package:pointycastle/export.dart';
// Encrypt sensitive data
```

### Database Backup
- Database is stored at: `/data/data/com.example.attendance_app/databases/`
- Users data persists across app restarts
- Consider implementing backup functionality

---

## All Available Methods

### UserService Methods

| Method | Purpose |
|--------|---------|
| `registerUser()` | Create new user |
| `loginUser()` | Verify credentials and login |
| `getUserByUsername()` | Fetch user by username |
| `getUserByEmail()` | Fetch user by email |
| `getUserById()` | Fetch user by ID |
| `getAllUsers()` | Get all registered users |
| `updateUserProfile()` | Update user info |
| `changePassword()` | Update password |
| `deleteUser()` | Delete user account |
| `userExists()` | Check if user exists |
| `getUserCount()` | Count total users |
| `searchUsers()` | Search by username/email |

---

## Testing Your Implementation

```dart
// Test registration
void testRegistration() async {
  final success = await UserService.registerUser(
    username: 'testuser',
    email: 'test@example.com',
    password: 'test123',
    fullName: 'Test User',
  );
  print('Registration: ${success ? "PASS" : "FAIL"}');
}

// Test login
void testLogin() async {
  final user = await UserService.loginUser('testuser', 'test123');
  print('Login: ${user != null ? "PASS" : "FAIL"}');
}

// Test duplicate
void testDuplicate() async {
  final first = await UserService.registerUser(
    username: 'duplicate',
    email: 'dup@example.com',
    password: 'test123',
  );
  final second = await UserService.registerUser(
    username: 'duplicate', // Same username
    email: 'dup2@example.com',
    password: 'test123',
  );
  print('Duplicate prevention: ${!second && first ? "PASS" : "FAIL"}');
}
```

---

## Next Steps

1. ✅ Build app: `flutter run`
2. ✅ Register a test user
3. ✅ Login with that user
4. ✅ Verify user data is saved in database
5. ✅ Check if data persists after app restart

Username and password storage is now **fully implemented and ready to use!** 🎉
