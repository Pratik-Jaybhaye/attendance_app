/// DeviceService handles device-related API operations
/// Provides methods for device validation, file uploads, student photos, and attendance marking
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/photo.dart';

class DeviceService {
  // API Base URL
  static const String apiBaseUrl = 'https://attendanceapi.acculekhaa.com';

  // ==================== USER VALIDATION ====================

  /// Validate user credentials on device
  /// API Endpoint: POST /api/Device/ValidateUser
  /// Parameters:
  ///   - username: User username (required)
  ///   - password: User password (required)
  /// Returns: true if user is valid, false otherwise
  static Future<bool> validateUser({
    required String username,
    required String password,
    String? token,
  }) async {
    try {
      print('DeviceService: Validating user - $username');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Device/ValidateUser'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isValid = data['success'] ?? data['isValid'] ?? false;
        print('DeviceService: User validation result - $isValid');
        return isValid;
      } else {
        print('DeviceService: Error validating user - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('DeviceService: Exception validating user - $e');
      return false;
    }
  }

  // ==================== CLASS OPERATIONS ====================

  /// Get all classes/groups for user
  /// API Endpoint: GET /api/Device/GetUserClasses
  /// Returns: List of class data
  static Future<List<Map<String, dynamic>>> getUserClasses({
    String? token,
  }) async {
    try {
      print('DeviceService: Fetching user classes');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/Device/GetUserClasses'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> classesList = [];
        if (data is Map) {
          classesList = data['data'] ?? data['classes'] ?? data['result'] ?? [];
        } else if (data is List) {
          classesList = data;
        }

        final classes = List<Map<String, dynamic>>.from(classesList);
        print('DeviceService: Fetched ${classes.length} classes');
        return classes;
      } else {
        print('DeviceService: Error fetching classes - ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('DeviceService: Exception fetching classes - $e');
      return [];
    }
  }

  // ==================== STUDENT OPERATIONS ====================

  /// Get all students (optionally filtered by class)
  /// API Endpoint: GET /api/Device/GetStudents
  /// Parameters:
  ///   - classId: Class ID (optional)
  ///   - limit: Number of records to fetch (optional)
  ///   - offset: Pagination offset (optional)
  /// Returns: List of Student objects
  static Future<List<Student>> getStudents({
    String? classId,
    int? limit,
    int? offset,
    String? token,
  }) async {
    try {
      print('DeviceService: Fetching students');

      final queryParams = <String, String>{};
      if (classId != null) queryParams['classId'] = classId;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse(
        '$apiBaseUrl/api/Device/GetStudents',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> studentsList = [];
        if (data is Map) {
          studentsList =
              data['data'] ?? data['students'] ?? data['result'] ?? [];
        } else if (data is List) {
          studentsList = data;
        }

        final students = studentsList.map((s) => Student.fromJson(s)).toList();
        print('DeviceService: Fetched ${students.length} students');
        return students;
      } else {
        print(
          'DeviceService: Error fetching students - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('DeviceService: Exception fetching students - $e');
      return [];
    }
  }

  // ==================== FILE OPERATIONS ====================

  /// Upload file to server
  /// API Endpoint: POST /api/Device/UploadFile
  /// Parameters:
  ///   - filePath: Path to file to upload (required)
  ///   - fileType: Type of file (photo, document, etc.) (optional)
  /// Returns: Map with upload response (fileId, url, etc.)
  static Future<Map<String, dynamic>?> uploadFile({
    required String filePath,
    String? fileType,
    String? token,
  }) async {
    try {
      print('DeviceService: Uploading file - $filePath');

      if (!File(filePath).existsSync()) {
        print('DeviceService: File not found - $filePath');
        return null;
      }

      final file = File(filePath);
      final fileName = file.path.split('/').last;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/api/Device/UploadFile'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      if (fileType != null) {
        request.fields['fileType'] = fileType;
      }

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseData);
        print('DeviceService: File uploaded successfully - $fileName');
        return data;
      } else {
        print('DeviceService: Error uploading file - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('DeviceService: Exception uploading file - $e');
      return null;
    }
  }

  // ==================== PHOTO OPERATIONS ====================

  /// Save student photo
  /// API Endpoint: POST /api/Device/SaveStudentPhoto
  /// Parameters:
  ///   - studentId: Student ID (required)
  ///   - photoPath: Path to photo file (required)
  ///   - photoType: Type of photo (required)
  /// Returns: Photo object if successful, null otherwise
  static Future<Photo?> saveStudentPhoto({
    required String studentId,
    required String photoPath,
    required String photoType,
    String? token,
  }) async {
    try {
      print('DeviceService: Saving student photo - $studentId');

      if (!File(photoPath).existsSync()) {
        print('DeviceService: Photo file not found - $photoPath');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/api/Device/SaveStudentPhoto'),
      );

      request.fields['studentId'] = studentId;
      request.fields['photoType'] = photoType;
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));

      request.headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseData);
        final photo = Photo.fromJson(data['data'] ?? data);
        print('DeviceService: Student photo saved - $studentId');
        return photo;
      } else {
        print(
          'DeviceService: Error saving student photo - ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('DeviceService: Exception saving student photo - $e');
      return null;
    }
  }

  /// Save or update profile photo
  /// API Endpoint: PUT /api/Device/SaveProfilePhoto
  /// Parameters:
  ///   - userId: User ID (required)
  ///   - photoPath: Path to photo file (required)
  /// Returns: Photo object if successful, null otherwise
  static Future<Photo?> saveProfilePhoto({
    required String userId,
    required String photoPath,
    String? token,
  }) async {
    try {
      print('DeviceService: Saving profile photo - $userId');

      if (!File(photoPath).existsSync()) {
        print('DeviceService: Photo file not found - $photoPath');
        return null;
      }

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$apiBaseUrl/api/Device/SaveProfilePhoto'),
      );

      request.fields['userId'] = userId;
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));

      request.headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        final photo = Photo.fromJson(data['data'] ?? data);
        print('DeviceService: Profile photo saved - $userId');
        return photo;
      } else {
        print(
          'DeviceService: Error saving profile photo - ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('DeviceService: Exception saving profile photo - $e');
      return null;
    }
  }

  /// Get student face photos
  /// API Endpoint: GET /api/Device/GetStudentFacePhotos
  /// Parameters:
  ///   - studentId: Student ID (required)
  /// Returns: List of Photo objects for student
  static Future<List<Photo>> getStudentFacePhotos({
    required String studentId,
    String? token,
  }) async {
    try {
      print('DeviceService: Fetching student face photos - $studentId');

      final uri = Uri.parse(
        '$apiBaseUrl/api/Device/GetStudentFacePhotos',
      ).replace(queryParameters: {'studentId': studentId});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> photosList = [];
        if (data is Map) {
          photosList = data['data'] ?? data['photos'] ?? data['result'] ?? [];
        } else if (data is List) {
          photosList = data;
        }

        final photos = photosList.map((p) => Photo.fromJson(p)).toList();
        print('DeviceService: Fetched ${photos.length} face photos');
        return photos;
      } else {
        print(
          'DeviceService: Error fetching student face photos - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('DeviceService: Exception fetching student face photos - $e');
      return [];
    }
  }

  // ==================== PHONE TYPES ====================

  /// Get available phone types
  /// API Endpoint: GET /api/Device/GetPhoneTypes
  /// Returns: List of phone types available
  static Future<List<String>> getPhoneTypes({String? token}) async {
    try {
      print('DeviceService: Fetching phone types');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/Device/GetPhoneTypes'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> typesList = [];
        if (data is Map) {
          typesList = data['data'] ?? data['types'] ?? data['result'] ?? [];
        } else if (data is List) {
          typesList = data;
        }

        final types = typesList.map((t) => t.toString()).toList();
        print('DeviceService: Fetched ${types.length} phone types');
        return types;
      } else {
        print(
          'DeviceService: Error fetching phone types - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('DeviceService: Exception fetching phone types - $e');
      return [];
    }
  }

  // ==================== ATTENDANCE OPERATIONS ====================

  /// Mark attendance in bulk for multiple students
  /// API Endpoint: POST /api/Device/BulkAttendanceMark
  /// Parameters:
  ///   - classId: Class ID (required)
  ///   - attendanceData: List of attendance records with studentId and status
  /// Returns: Map with success status and details
  static Future<Map<String, dynamic>?> bulkAttendanceMark({
    required String classId,
    required List<Map<String, dynamic>> attendanceData,
    String? token,
  }) async {
    try {
      print('DeviceService: Marking bulk attendance for class - $classId');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Device/BulkAttendanceMark'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'classId': classId,
          'attendanceData': attendanceData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DeviceService: Bulk attendance marked successfully');
        return data;
      } else {
        print(
          'DeviceService: Error marking bulk attendance - ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('DeviceService: Exception marking bulk attendance - $e');
      return null;
    }
  }
}
