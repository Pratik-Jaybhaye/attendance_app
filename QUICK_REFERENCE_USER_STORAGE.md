# Quick Reference - Username & Password Storage

## 3 Steps to Implement

### Step 1: Register User
```dart
import 'package:attendance_app/services/auth_service.dart';

final success = await AuthService.registerWithUsername(
  username: 'john_doe',
  email: 'john@example.com',
  password: 'password123',
  fullName: 'John Doe',
);
```

### Step 2: Login User
```dart
final user = await AuthService.loginWithUsername('john_doe', 'password123');

if (user != null) {
  print('Login successful: ${user.username}');
}
```

### Step 3: Access User Data
```dart
print('Username: ${user.username}');
print('Email: ${user.email}');
print('Full Name: ${user.fullName}');
print('Created: ${user.createdAt}');
print('Last Login: ${user.lastLogin}');
```

---

## Common Operations

### Register
```dart
await AuthService.registerWithUsername(
  username: 'user123',
  email: 'user@example.com',
  password: 'pass123',
  fullName: 'User Name',
);
```

### Login
```dart
final user = await AuthService.loginWithUsername('user123', 'pass123');
```

### Get User by Email
```dart
final user = await UserService.getUserByEmail('user@example.com');
```

### Update Profile
```dart
await UserService.updateUserProfile(
  userId: user.id,
  fullName: 'New Name',
  profileImagePath: '/path/to/image.jpg',
);
```

### Change Password
```dart
await UserService.changePassword(
  userId: user.id,
  oldPassword: 'oldpass',
  newPassword: 'newpass',
);
```

### Check if Username Exists
```dart
bool exists = await UserService.userExists('john_doe');
```

### Search Users
```dart
final results = await UserService.searchUsers('john');
```

### Delete User
```dart
await UserService.deleteUser(user.id);
```

---

## Database Tables

### users table
```
id              - Unique user ID
username        - Login username (UNIQUE)
email           - User email (UNIQUE)
password        - User password (stored as plain text*)
full_name       - User's full name
profile_image_path - Path to profile photo
role            - User role (admin, teacher, etc.)
created_at      - Registration timestamp
last_login      - Last login timestamp
is_active       - Active status (1=active, 0=inactive)
```

*Consider hashing passwords in production

---

## Complete Flow Example

```dart
// Registration
final registered = await AuthService.registerWithUsername(
  username: 'newuser',
  email: 'new@example.com',
  password: 'password123',
  fullName: 'New User',
);

if (registered) {
  // Navigate to login
}

// Login
final user = await AuthService.loginWithUsername('newuser', 'password123');

if (user != null) {
  // Store user in provider/state management
  Provider.of<UserProvider>(context, listen: false).setUser(user);
  
  // Navigate to home
  Navigator.of(context).pushReplacementNamed('/home');
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Invalid credentials')),
  );
}

// Access user anywhere
final currentUser = Provider.of<UserProvider>(context).user;
print('Current user: ${currentUser.username}');
```

---

## Files Added/Modified

✅ **New:**
- `lib/models/user.dart` - User model
- `lib/services/user_service.dart` - User operations

✅ **Modified:**
- `lib/services/database_helper.dart` - Added users table & methods
- `lib/services/auth_service.dart` - Updated to use local database

---

## Run Your App

```bash
flutter clean
flutter pub get
flutter run
```

After running, the database will be created automatically on first launch.

---

## Check Database (Advanced)

Extract database from emulator:
```bash
adb pull /data/data/com.example.attendance_app/databases/attendance_app.db
```

Open with **DB Browser for SQLite** to view tables and data.

---

## Data is Persisted

- Data stays even after app closes
- Each user is stored uniquely  
- Passwords stored (⚠️ consider hashing)
- Last login tracked

**Ready to use!** 🚀
