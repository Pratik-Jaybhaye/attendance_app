/// Quick Integration Examples
///
/// This file contains copy-paste ready code examples for integrating
/// photo storage and attendance marking into your Flutter UI

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:attendance_app/services/photo_enrollment_service.dart';
import 'package:attendance_app/services/attendance_matching_service.dart';

// ============================================================================
// EXAMPLE 1: Upload and Enroll Student Photo
// ============================================================================

class EnrollmentScreen extends StatefulWidget {
  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _enrollmentService = PhotoEnrollmentService();
  final _imagePicker = ImagePicker();

  late TextEditingController _studentIdController;
  late TextEditingController _studentNameController;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _studentIdController = TextEditingController(text: 'STU001');
    _studentNameController = TextEditingController(text: 'John Doe');
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  String get studentId => _studentIdController.text;
  String get studentName => _studentNameController.text;

  Future<void> _enrollStudentFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isEnrolling = true);

    try {
      // Enroll student with photo
      final result = await _enrollmentService.enrollStudentWithPhoto(
        studentId: studentId,
        studentName: studentName,
        imagePath: pickedFile.path,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isEnrolling = false);
    }
  }

  Future<void> _enrollStudentFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isEnrolling = true);

    try {
      final result = await _enrollmentService.enrollStudentWithPhoto(
        studentId: studentId,
        studentName: studentName,
        imagePath: pickedFile.path,
      );

      if (result['success']) {
        print('✓ Enrollment successful!');
        print('  Photo ID: ${result['photoId']}');
        print('  Embedding Dimension: ${result['embeddingDimension']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student enrolled with face recognition'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('✗ Enrollment failed: ${result['error']}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enroll Student'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Student Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),

          TextField(
            controller: _studentIdController,
            decoration: InputDecoration(
              labelText: 'Student ID',
              hintText: 'e.g., STU001',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12),

          TextField(
            controller: _studentNameController,
            decoration: InputDecoration(
              labelText: 'Student Name',
              hintText: 'e.g., John Doe',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 24),

          Text('Upload Photo', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _isEnrolling ? null : _enrollStudentFromCamera,
            icon: Icon(Icons.camera_alt),
            label: Text('Capture from Camera'),
          ),
          SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _isEnrolling ? null : _enrollStudentFromGallery,
            icon: Icon(Icons.image),
            label: Text('Select from Gallery'),
          ),
          SizedBox(height: 12),

          if (_isEnrolling)
            Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Processing photo and generating embeddings...'),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 2: Mark Attendance from Live Embedding
// ============================================================================

class AttendanceMarkingScreen extends StatefulWidget {
  @override
  State<AttendanceMarkingScreen> createState() =>
      _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  String _matchedStudent = 'None';
  int _similarity = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mark Attendance'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Live Camera Feed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 32),

            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('Camera widget here')),
            ),
            SizedBox(height: 32),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Last Match:', style: TextStyle(fontSize: 12)),
                  Text(
                    _matchedStudent,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Similarity: $_similarity%',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: View Enrollment Statistics
// ============================================================================

class EnrollmentStatsScreen extends StatefulWidget {
  @override
  State<EnrollmentStatsScreen> createState() => _EnrollmentStatsScreenState();
}

class _EnrollmentStatsScreenState extends State<EnrollmentStatsScreen> {
  final _enrollmentService = PhotoEnrollmentService();
  final _attendanceService = AttendanceMatchingService();

  int _enrolledCount = 0;
  int _attendanceCount = 0;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final enrolled = await _enrollmentService.getEnrolledStudents();
    final stats = await _attendanceService.getStatistics();

    setState(() {
      _students = enrolled;
      _enrolledCount = stats['enrolledStudents'] as int;
      _attendanceCount = stats['totalAttendanceRecords'] as int;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enrollment Statistics'), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$_enrolledCount',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text('Enrolled Students'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$_attendanceCount',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text('Attendance Records'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          Text(
            'Enrolled Students',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              return Card(
                child: ListTile(
                  title: Text('Student: ${student['student_id']}'),
                  subtitle: Text('Photos: ${student['photo_count']}'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER: How to integrate into your main.dart
// ============================================================================

/*

In your main.dart, add navigation to these screens:

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance System')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Enroll Student'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EnrollmentScreen()),
            ),
          ),
          ListTile(
            title: Text('Mark Attendance'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AttendanceMarkingScreen()),
            ),
          ),
          ListTile(
            title: Text('View Statistics'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EnrollmentStatsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

*/
