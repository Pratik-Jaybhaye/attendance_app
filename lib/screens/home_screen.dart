import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'self_attendance_screen.dart';
import 'update_profile_photo_screen.dart';
import 'select_classes_screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // User profile data - should be fetched from backend
  String? userProfileImage; // API: Fetch from /api/user/profile/image
  String userName = 'Srikanth 2'; // API: Fetch from /api/user/profile
  String userID = '60321'; // API: Fetch from /api/user/id

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  /// TODO: Connect to Backend API
  /// Endpoint: GET /api/user/profile
  /// This should fetch:
  /// - User name
  /// - User ID
  /// - Profile image URL
  Future<void> _fetchUserProfile() async {
    try {
      // TODO: Replace with actual API call
      // Example:
      // final response = await http.get(
      //   Uri.parse('$API_BASE_URL/api/user/profile'),
      //   headers: {'Authorization': 'Bearer $authToken'},
      // );
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   setState(() {
      //     userName = data['name'];
      //     userID = data['id'];
      //     userProfileImage = data['profileImage'];
      //     _isLoading = false;
      //   });
      // }

      // Mock delay to simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user profile: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user profile')),
      );
    }
  }

  /// TODO: Connect to Backend API
  /// Endpoint: POST /api/attendance/student
  /// This should handle taking attendance for students
  void _takeStudentAttendance() {
    // TODO: Navigate to student attendance screen
    // and send attendance data to backend
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SelectClassesScreen()),
    );
  }

  /// TODO: Connect to Backend API
  /// Endpoint: POST /api/attendance/self
  /// This should handle taking self attendance
  void _takeSelfAttendance() {
    // Navigate to self attendance screen with camera
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SelfAttendanceScreen()),
    );
  }

  /// TODO: Connect to Backend API
  /// Endpoint: GET /api/attendance/logs
  /// This should fetch attendance history/logs
  void _viewAttendanceLogs() {
    // TODO: Navigate to attendance logs screen
    // and fetch logs from backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance Logs - Coming Soon')),
    );
  }

  void _handleProfileImageEdit() {
    // Navigate to Update Profile Photo Screen
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => UpdateProfilePhotoScreen(
              userName: userName,
              userID: userID,
              currentProfileImage: userProfileImage,
            ),
          ),
        )
        .then((updated) {
          // If profile was updated, refresh the home screen
          if (updated == true) {
            setState(() {
              // Re-fetch user profile to get updated image
              _fetchUserProfile();
            });
          }
        });
  }

  /// TODO: Connect to Backend API
  /// Endpoint: GET /api/about
  /// This should fetch about us information from backend
  void _handleAboutUs() {
    // TODO: Navigate to About Us screen
    // and fetch content from backend
    // Example API structure:
    // GET /api/about
    // Response:
    // {
    //   "title": "About AI-FRAS",
    //   "content": "About us content...",
    //   "version": "1.0.0",
    //   "contactEmail": "support@example.com"
    // }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('About Us - Coming Soon')));
    Navigator.pop(context); // Close drawer
  }

  /// TODO: Connect to Backend API
  /// Endpoint: POST /api/feedback
  /// This should send user feedback to backend
  void _handleFeedback() {
    // TODO: Navigate to Feedback screen
    // and send feedback data to backend
    // Example API structure:
    // POST /api/feedback
    // Request body:
    // {
    //   "userId": user_id,
    //   "feedbackType": "bug|feature|improvement|other",
    //   "message": "feedback message",
    //   "rating": 1-5,
    //   "timestamp": "2024-02-13T12:00:00Z"
    // }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback - Coming Soon')));
    Navigator.pop(context); // Close drawer
  }

  /// TODO: Connect to Backend API
  /// Endpoint: POST /api/auth/logout
  /// This should handle user logout
  void _handleLogout() {
    // TODO: Implement logout functionality
    // Example API structure:
    // POST /api/auth/logout
    // Request body:
    // {
    //   "userId": user_id,
    //   "token": auth_token
    // }
    // Steps:
    // 1. Show confirmation dialog
    // 2. Call logout endpoint
    // 3. Clear stored auth token/session
    // 4. Navigate to login screen

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Call logout API endpoint here
                // await logoutUser();
                Navigator.pop(context); // Close dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Build the navigation drawer with menu items
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header with User Profile
            Container(
              decoration: const BoxDecoration(color: Color(0xFFF5F3F8)),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section in Drawer
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF6B5B95),
                                  width: 3,
                                ),
                                color: Colors.grey[300],
                              ),
                              child: userProfileImage != null
                                  ? Image.network(
                                      userProfileImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Color(0xFF6B5B95),
                                    ),
                            ),
                            // Camera Icon Button
                            GestureDetector(
                              onTap: _handleProfileImageEdit,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF6B5B95),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $userID',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5A5C6E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Menu Items
            _buildDrawerMenuItem(
              icon: Icons.history,
              title: 'Attendance Logs',
              onTap: _viewAttendanceLogs,
            ),
            const SizedBox(height: 8),
            _buildDrawerMenuItem(
              icon: Icons.info_outline,
              title: 'About Us',
              onTap: _handleAboutUs,
            ),
            const SizedBox(height: 8),
            _buildDrawerMenuItem(
              icon: Icons.chat_outlined,
              title: 'Feedback',
              onTap: _handleFeedback,
            ),
            // Spacer to push logout to bottom
            const Spacer(),
            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
            ),
            const SizedBox(height: 8),
            // Logout Button
            _buildDrawerMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _handleLogout,
              isLogout: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build individual drawer menu items
  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLogout
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey[200],
              ),
              child: Icon(
                icon,
                color: isLogout ? Colors.red : const Color(0xFF5A5C6E),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isLogout ? Colors.red : const Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F8),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                color: const Color(0xFFF5F3F8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    // Hamburger Menu - Tap to open drawer (handled by Scaffold)
                    Builder(
                      builder: (context) {
                        return GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: const Icon(
                            Icons.menu,
                            color: Color(0xFF2C2C2C),
                            size: 28,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'My Home',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // User Profile Section
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6B5B95),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DDF7),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      children: [
                        // Profile Image Section
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF6B5B95),
                                  width: 4,
                                ),
                                color: Colors.grey[300],
                              ),
                              child: userProfileImage != null
                                  ? Image.network(
                                      userProfileImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color(0xFF6B5B95),
                                    ),
                            ),
                            // Camera Icon Button
                            GestureDetector(
                              onTap: _handleProfileImageEdit,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF6B5B95),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // User Name
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // User ID Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4D4DB).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ID: $userID',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5A5C6E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Take Student Attendance Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: _takeStudentAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DAB5E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Take Student Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Take Self Attendance Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: OutlinedButton(
                  onPressed: _takeSelfAttendance,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    side: const BorderSide(color: Color(0xFF6B5B95), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF6B5B95),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Take Self Attendance',
                        style: TextStyle(
                          color: Color(0xFF6B5B95),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // View Attendance Logs
              GestureDetector(
                onTap: _viewAttendanceLogs,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history,
                        color: Color(0xFF6B5B95),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'View Attendance Logs',
                        style: TextStyle(
                          color: const Color(0xFF6B5B95),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(
                            0xFF6B5B95,
                          ).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
