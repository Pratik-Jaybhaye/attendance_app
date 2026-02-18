## Implementation Examples & Code Snippets

This document contains practical code examples for implementing key features.

---

## 1. HTTP Service for API Communication

Create a new file: `lib/services/http_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

/// HTTP Service for backend communication
/// Handles all API requests with authentication and error handling
class HttpService {
  static const String BASE_URL = 'https://your-api-domain.com/api/v1';
  
  /// Authentication token (get from login)
  static String? _authToken;
  
  /// Device HTTP client with timeout configuration
  static final client = http.Client();
  
  /// Set authentication token
  static void setAuthToken(String token) {
    _authToken = token;
  }
  
  /// Get request headers with authentication
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }
  
  /// Perform GET request
  static Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('$BASE_URL$endpoint');
      final response = await client.get(
        uri,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  /// Perform POST request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$BASE_URL$endpoint');
      final response = await client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  /// Handle HTTP response
  static dynamic _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Token expired');
      } else if (response.statusCode == 404) {
        throw Exception('Not found');
      } else {
        final message = data['message'] ?? 'Unknown error';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error parsing response: $e');
    }
  }
}
```

---

## 2. Class Repository Service

Create a new file: `lib/services/class_repository.dart`

```dart
import '../models/class.dart';
import '../models/student.dart';
import 'http_service.dart';

/// Repository for class-related operations
class ClassRepository {
  
  /// Fetch all available classes
  Future<List<ClassModel>> getAllClasses() async {
    try {
      final response = await HttpService.get('/classes');
      
      if (response['status'] == 'success') {
        final classes = (response['data'] as List)
            .map((json) => ClassModel.fromJson(json))
            .toList();
        return classes;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch classes');
      }
    } catch (e) {
      throw Exception('Error fetching classes: $e');
    }
  }
  
  /// Fetch specific class with students
  Future<ClassModel> getClassWithStudents(String classId) async {
    try {
      final response = await HttpService.get('/classes/$classId');
      
      if (response['status'] == 'success') {
        return ClassModel.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch class');
      }
    } catch (e) {
      throw Exception('Error fetching class: $e');
    }
  }

  /// Update student enrollment status
  Future<void> updateStudentEnrollmentStatus(
    String studentId,
    String status, // 'enrolled', 'pending', 'no_photo'
  ) async {
    try {
      final response = await HttpService.post(
        '/students/$studentId/enrollment',
        {'status': status},
      );
      
      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }
}
```

---

## 3. Attendance Service

Create a new file: `lib/services/attendance_service.dart`

```dart
import '../models/class.dart';
import '../models/period.dart';
import '../models/attendance_record.dart';
import 'http_service.dart';

/// Service for attendance operations
class AttendanceService {
  
  /// Start an attendance session
  Future<String> startAttendanceSession({
    required List<String> classIds,
    required String periodId,
    required String remarks,
  }) async {
    try {
      final response = await HttpService.post(
        '/attendance/session/start',
        {
          'classIds': classIds,
          'periodId': periodId,
          'remarks': remarks,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (response['status'] == 'success') {
        return response['data']['sessionId'];
      } else {
        throw Exception(response['message'] ?? 'Failed to start session');
      }
    } catch (e) {
      throw Exception('Error starting attendance session: $e');
    }
  }
  
  /// Record a detected student
  Future<bool> recordStudentDetection({
    required String sessionId,
    required String studentId,
    required String classId,
    required double confidence,
  }) async {
    try {
      final response = await HttpService.post(
        '/attendance/student-detected',
        {
          'sessionId': sessionId,
          'studentId': studentId,
          'classId': classId,
          'confidence': confidence,
          'detectionTime': DateTime.now().toIso8601String(),
        },
      );
      
      return response['status'] == 'success';
    } catch (e) {
      print('Error recording student detection: $e');
      return false;
    }
  }
  
  /// Submit final attendance
  Future<bool> submitAttendance({
    required String sessionId,
    required List<String> classIds,
    required String periodId,
    required String remarks,
    required Map<String, Map<String, bool>> studentAttendance,
  }) async {
    try {
      final response = await HttpService.post(
        '/attendance/submit',
        {
          'sessionId': sessionId,
          'classIds': classIds,
          'periodId': periodId,
          'remarks': remarks,
          'studentAttendance': studentAttendance,
          'submissionTime': DateTime.now().toIso8601String(),
        },
      );
      
      if (response['status'] == 'success') {
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to submit attendance');
      }
    } catch (e) {
      throw Exception('Error submitting attendance: $e');
    }
  }
  
  /// Get attendance history for a class
  Future<List<AttendanceRecord>> getAttendanceHistory({
    required String classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = {
        'classId': classId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };
      
      final queryString = params.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      
      final response = await HttpService.get('/attendance/history?$queryString');
      
      if (response['status'] == 'success') {
        return (response['data'] as List)
            .map((json) => AttendanceRecord.fromJson(json))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch history');
      }
    } catch (e) {
      throw Exception('Error fetching attendance history: $e');
    }
  }
}
```

---

## 4. Period Service

Create a new file: `lib/services/period_service.dart`

```dart
import '../models/period.dart';
import 'http_service.dart';

/// Service for period/time slot operations
class PeriodService {
  
  /// Fetch all available periods
  Future<List<Period>> getAllPeriods() async {
    try {
      final response = await HttpService.get('/periods');
      
      if (response['status'] == 'success') {
        return (response['data'] as List)
            .map((json) => Period.fromJson(json))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch periods');
      }
    } catch (e) {
      throw Exception('Error fetching periods: $e');
    }
  }
  
  /// Get period by ID
  Future<Period> getPeriodById(String periodId) async {
    try {
      final response = await HttpService.get('/periods/$periodId');
      
      if (response['status'] == 'success') {
        return Period.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch period');
      }
    } catch (e) {
      throw Exception('Error fetching period: $e');
    }
  }
}
```

---

## 5. Using Services in Screens

Example: Update `select_classes_screen.dart` to use HTTP service

```dart
import '../services/class_repository.dart';

class SelectClassesScreen extends StatefulWidget {
  // ...
}

class _SelectClassesScreenState extends State<SelectClassesScreen> {
  final ClassRepository _classRepository = ClassRepository();
  List<ClassModel> _availableClasses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  /// Load classes from backend
  Future<void> _loadClasses() async {
    try {
      setState(() => _isLoading = true);
      
      final classes = await _classRepository.getAllClasses();
      
      setState(() {
        _availableClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading classes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Classes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Classes')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadClasses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // ... rest of the UI with _availableClasses
    );
  }
}
```

---

## 6. Enhanced Take Attendance Screen with API

```dart
import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/period.dart';
import '../services/attendance_service.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final List<ClassModel> selectedClasses;
  final Period selectedPeriod;

  const TakeAttendanceScreen({
    super.key,
    required this.selectedClasses,
    required this.selectedPeriod,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  
  late Map<String, Set<String>> _presentStudents;
  String? _sessionId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializePresentStudentsMap();
    _startAttendanceSession();
  }

  /// Initialize attendance tracking
  void _initializePresentStudentsMap() {
    _presentStudents = {};
    for (var classModel in widget.selectedClasses) {
      _presentStudents[classModel.id] = {};
    }
  }

  /// Start attendance session on backend
  Future<void> _startAttendanceSession() async {
    try {
      final sessionId = await _attendanceService.startAttendanceSession(
        classIds: widget.selectedClasses.map((c) => c.id).toList(),
        periodId: widget.selectedPeriod.id,
        remarks: widget.selectedPeriod.remarks,
      );
      
      setState(() => _sessionId = sessionId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting session: $e')),
        );
      }
    }
  }

  /// Mark student as present and send to backend
  void _markStudentPresent(String classId, String studentId) async {
    if (_sessionId == null) return;
    
    setState(() {
      _presentStudents[classId]?.add(studentId);
    });

    // Send to backend
    await _attendanceService.recordStudentDetection(
      sessionId: _sessionId!,
      studentId: studentId,
      classId: classId,
      confidence: 0.95,
    );
  }

  /// Submit attendance to backend
  void _submitAttendance() async {
    if (_sessionId == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Prepare attendance data
      final studentAttendance = <String, Map<String, bool>>{};
      
      for (final classModel in widget.selectedClasses) {
        final classAttendance = <String, bool>{};
        
        for (final student in classModel.students) {
          final isPresent = _presentStudents[classModel.id]!
              .contains(student.id);
          classAttendance[student.id] = isPresent;
        }
        
        studentAttendance[classModel.id] = classAttendance;
      }

      // Submit to backend
      final success = await _attendanceService.submitAttendance(
        sessionId: _sessionId!,
        classIds: widget.selectedClasses.map((c) => c.id).toList(),
        periodId: widget.selectedPeriod.id,
        remarks: widget.selectedPeriod.remarks,
        studentAttendance: studentAttendance,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting attendance: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ... rest of the build method
}
```

---

## 7. Error Handling Helper

Create a new file: `lib/utils/error_handler.dart`

```dart
import 'package:flutter/material.dart';

/// Centralized error handling
class ErrorHandler {
  
  /// Parse exception and return user-friendly message
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Unauthorized')) {
        return 'Your session has expired. Please login again.';
      } else if (message.contains('Network error')) {
        return 'Network error. Please check your connection.';
      } else if (message.contains('404')) {
        return 'Resource not found.';
      } else if (message.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
      return message.replaceAll('Exception: ', '');
    }
    return 'An unknown error occurred. Please try again.';
  }
  
  /// Show error snackbar
  static void showError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

---

## 8. Constants File

Create a new file: `lib/constants.dart`

```dart
/// API Configuration
class ApiConfig {
  static const String baseUrl = 'https://your-api-domain.com/api/v1';
  static const Duration timeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}

/// UI Constants
class UiConstants {
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const int remarksMaxLength = 12;
  static const int maxClassSelection = 2;
}

/// Face Detection Constants
class FaceDetectionConstants {
  static const double faceDetectionThreshold = 0.85;
  static const double minFaceSize = 0.1;
  static const int maxFaceSize = 500;
  static const int frameDelmillisecondSampleRate = 100; // Process every 100ms
}

/// Enrollment Constants
class EnrollmentConstants {
  static const int minPhotosForEnrollment = 5;
  static const int photoQuality = 85; // 0-100
  static const List<String> enrollmentStatuses = [
    'no_photo',
    'pending',
    'enrolled'
  ];
}
```

---

## Testing Example

Create a new file: `test/models/student_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_app/models/student.dart';

void main() {
  group('Student Model Tests', () {
    
    test('Student creation with default values', () {
      final student = Student(
        id: '1',
        name: 'John Doe',
        rollNumber: '10021001',
      );

      expect(student.id, '1');
      expect(student.name, 'John Doe');
      expect(student.enrollmentStatus, 'no_photo');
      expect(student.isPresent, false);
    });

    test('Student JSON serialization', () {
      final student = Student(
        id: '1',
        name: 'John',
        rollNumber: '10021001',
        enrollmentStatus: 'enrolled',
        enrolledPhotosCount: 5,
      );

      final json = student.toJson();
      expect(json['id'], '1');
      expect(json['enrolledPhotosCount'], 5);
    });

    test('Student JSON deserialization', () {
      final json = {
        'id': '1',
        'name': 'John',
        'rollNumber': '10021001',
        'enrollmentStatus': 'enrolled',
        'enrolledPhotosCount': 5,
      };

      final student = Student.fromJson(json);
      expect(student.name, 'John');
      expect(student.enrollmentStatus, 'enrolled');
    });
  });
}
```

---

## Useful Flutter Snippets

### Loading Widget
```dart
Widget buildLoadingWidget() {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading...'),
      ],
    ),
  );
}
```

### Error Widget
```dart
Widget buildErrorWidget(String message, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
```

---

**Last Updated:** February 18, 2025
