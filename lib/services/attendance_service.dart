/// AttendanceService handles attendance-related operations
/// Provides methods for marking attendance, fetching logs, etc.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'contact_service.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  // TODO: Replace with your actual API base URL
  static const String apiBaseUrl = 'https://attendanceapi.acculekhaa.com/';

  static final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Mark attendance with face verification and location data
  /// Returns true if attendance marked successfully, false otherwise
  ///
  /// This method attempts to mark attendance using multiple strategies:
  /// 1. First tries the Contact API endpoint (recommended)
  /// 2. Falls back to local notification if API is unavailable
  ///
  /// API Endpoint: POST /api/Contact/MarkAttendance (primary)
  /// Request body:
  /// {
  ///   "contactId": "user_id",
  ///   "latitude": 17.4059,
  ///   "longitude": 78.3746,
  ///   "faceVerified": true
  /// }
  ///
  /// Response body:
  /// {
  ///   "success": true,
  ///   "message": "Attendance marked successfully",
  ///   "attendanceId": "id_here"
  /// }
  static Future<bool> markAttendance({
    required double latitude,
    required double longitude,
    required bool faceVerified,
    String? token,
    String? email,
    String? userId,
  }) async {
    try {
      print('AttendanceService: Marking attendance');
      print('Location: $latitude, $longitude');
      print('Face Verified: $faceVerified');
      print('Email: $email, UserID: $userId');

      // Determine contactId to use
      String? contactId = userId;

      // If contactId not provided but email is, try to get user ID from database
      if (contactId == null && email != null && email.isNotEmpty) {
        try {
          final user = await _dbHelper.getUserByEmail(email);
          if (user != null) {
            contactId = user.id;
            print(
              'AttendanceService: Retrieved user ID from email: $contactId',
            );
          }
        } catch (e) {
          print('AttendanceService: Could not retrieve user ID from email: $e');
        }
      }

      // Use ContactService if we have a contactId
      if (contactId != null && contactId.isNotEmpty) {
        print(
          'AttendanceService: Using ContactService with contactId: $contactId',
        );
        return await ContactService.markAttendance(
          contactId: contactId,
          latitude: latitude,
          longitude: longitude,
          faceVerified: faceVerified,
          token: token,
        );
      }

      // Fallback: Try the direct attendance endpoint without token
      print(
        'AttendanceService: Using direct attendance endpoint (no contactId)',
      );

      final headers = {'Content-Type': 'application/json'};

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('${apiBaseUrl}api/Contact/MarkAttendance'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "iOrgId": "1",
          "iEnrollmentID": contactId,
          "iPunchDateTime": DateTime.now().toIso8601String(),
          "latitude": latitude.toString(),
          "longitude": longitude.toString(),
          "MachineId": 1,
          "AttendanceType": 1,
          "PunchPhotoUrl": "",
          "CompanyCode": "ACCULEKHAA",
          "UserId": int.tryParse(contactId ?? "0") ?? 0,
          "UserType": "Teacher",
          "CustomerId": 1,
          "ContactId": int.tryParse(contactId ?? "0") ?? 0,
          "TokenId": token ?? "",
          "dbOperation": "INSERT",
        }),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");
      print("CONTACT ID USED: $contactId");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('AttendanceService: Attendance marked successfully');
        return data['success'] ?? true;
      } else if (response.statusCode == 401) {
        print('AttendanceService: Unauthorized - token expired or missing');
        return false;
      } else if (response.statusCode == 500) {
        print('AttendanceService: Server error - ${response.body}');
        return false;
      } else {
        print(
          'AttendanceService: Failed with status ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to mark attendance: ${response.statusCode}');
      }
    } catch (e) {
      print('AttendanceService: Error marking attendance - $e');
      return false;
    }
  }

  /// Fetch attendance logs for current user
  /// Returns list of attendance records if successful, empty list otherwise
  ///
  /// API Endpoint: GET /api/attendance/logs
  /// Headers: Authorization: Bearer {token}
  /// Query Parameters:
  ///   - limit: number of records to fetch (default 30)
  ///   - offset: pagination offset (default 0)
  ///
  /// Response body:
  /// {
  ///   "success": true,
  ///   "logs": [
  ///     {
  ///       "id": "attendance_id",
  ///       "date": "2024-02-13",
  ///       "time": "12:30:00",
  ///       "latitude": 17.4059,
  ///       "longitude": 78.3746,
  ///       "faceVerified": true
  ///     }
  ///   ]
  /// }
  static Future<List<Map<String, dynamic>>> fetchAttendanceLogs({
    String? token,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      print('AttendanceService: Fetching attendance logs');

      // TODO: Replace with actual API endpoint
      // For now, this is a mock implementation
      // Uncomment the code below when API is ready:

      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/api/attendance/logs?limit=$limit&offset=$offset',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);
        print('AttendanceService: Fetched ${logs.length} records');
        return logs;
      } else if (response.statusCode == 401) {
        print('AttendanceService: Unauthorized - token expired');
        return [];
      } else {
        throw Exception('Failed to fetch logs: ${response.statusCode}');
      }
    } catch (e) {
      print('AttendanceService: Error fetching logs - $e');
      return [];
    }
  }

  /// Get attendance statistics for current user
  /// Returns attendance summary statistics
  ///
  /// API Endpoint: GET /api/attendance/stats
  /// Headers: Authorization: Bearer {token}
  /// Query Parameters:
  ///   - month: month (1-12) optional
  ///   - year: year (e.g., 2024) optional
  ///
  /// Response body:
  /// {
  ///   "success": true,
  ///   "totalPresent": 20,
  ///   "totalAbsent": 2,
  ///   "attendancePercentage": 90.9
  /// }
  static Future<Map<String, dynamic>> fetchAttendanceStats({
    String? token,
    int? month,
    int? year,
  }) async {
    try {
      print('AttendanceService: Fetching attendance statistics');

      // TODO: Replace with actual API endpoint
      // For now, this is a mock implementation
      // Uncomment the code below when API is ready:

      // String url = '$apiBaseUrl/api/attendance/stats';
      // if (month != null && year != null) {
      //   url += '?month=$month&year=$year';
      // }
      //
      // final response = await http.get(
      //   Uri.parse(url),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   print('AttendanceService: Stats fetched successfully');
      //   return jsonDecode(response.body);
      // } else if (response.statusCode == 401) {
      //   print('AttendanceService: Unauthorized - token expired');
      //   return {};
      // } else {
      //   throw Exception('Failed to fetch stats: ${response.statusCode}');
      // }

      // MOCK IMPLEMENTATION: Remove when API is ready
      await Future.delayed(const Duration(milliseconds: 300));

      final mockStats = {
        'success': true,
        'totalPresent': 20,
        'totalAbsent': 2,
        'attendancePercentage': 90.9,
      };

      print('AttendanceService: Returning mock attendance statistics');
      return mockStats;
    } catch (e) {
      print('AttendanceService: Error fetching stats - $e');
      return {};
    }
  }

  // ==================== LOCAL DATABASE OPERATIONS ====================

  /// Save attendance record to local database
  /// Call this method after capturing attendance successfully
  ///
  /// Example:
  /// ```dart
  /// final record = AttendanceRecord(
  ///   id: 'record_123',
  ///   classId: 'class_1',
  ///   periodId: 'period_1',
  ///   dateTime: DateTime.now(),
  ///   studentAttendance: {
  ///     'student_1': true,
  ///     'student_2': false,
  ///   },
  /// );
  ///
  /// final saved = await AttendanceService.saveAttendanceLocally(record);
  /// if (saved) {
  ///   print('Attendance saved to local database');
  /// }
  /// ```
  static Future<bool> saveAttendanceLocally(AttendanceRecord record) async {
    try {
      print('AttendanceService: Saving attendance record locally');
      final result = await _dbHelper.saveAttendanceRecord(record);
      if (result) {
        print('AttendanceService: Attendance saved successfully to local DB');
      }
      return result;
    } catch (e) {
      print('AttendanceService: Error saving attendance locally - $e');
      return false;
    }
  }

  /// Save multiple attendance records to local database (batch operation)
  /// More efficient than saving one by one
  static Future<bool> saveBatchAttendanceLocally(
    List<AttendanceRecord> records,
  ) async {
    try {
      print(
        'AttendanceService: Saving ${records.length} attendance records locally',
      );
      final result = await _dbHelper.saveBatchAttendanceRecords(records);
      if (result) {
        print('AttendanceService: Batch attendance saved successfully');
      }
      return result;
    } catch (e) {
      print('AttendanceService: Error saving batch attendance - $e');
      return false;
    }
  }

  /// Retrieve attendance record from local database
  static Future<AttendanceRecord?> getAttendanceLocallyById(
    String recordId,
  ) async {
    try {
      print('AttendanceService: Retrieving attendance record: $recordId');
      return await _dbHelper.getAttendanceRecord(recordId);
    } catch (e) {
      print('AttendanceService: Error retrieving attendance - $e');
      return null;
    }
  }

  /// Get all attendance records from local database
  static Future<List<AttendanceRecord>> getAllAttendanceLocally() async {
    try {
      print(
        'AttendanceService: Retrieving all attendance records from local DB',
      );
      return await _dbHelper.getAllAttendanceRecords();
    } catch (e) {
      print('AttendanceService: Error retrieving all attendance - $e');
      return [];
    }
  }

  /// Get attendance records for a specific class from local database
  static Future<List<AttendanceRecord>> getAttendanceByClassLocally(
    String classId,
  ) async {
    try {
      print('AttendanceService: Retrieving attendance for class: $classId');
      return await _dbHelper.getAttendanceByClassId(classId);
    } catch (e) {
      print('AttendanceService: Error retrieving class attendance - $e');
      return [];
    }
  }

  /// Get attendance records within a date range from local database
  static Future<List<AttendanceRecord>> getAttendanceByDateRangeLocally(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print(
        'AttendanceService: Retrieving attendance between $startDate and $endDate',
      );
      return await _dbHelper.getAttendanceByDateRange(startDate, endDate);
    } catch (e) {
      print('AttendanceService: Error retrieving date range attendance - $e');
      return [];
    }
  }

  /// Get unsubmitted attendance records (for syncing with backend later)
  static Future<List<AttendanceRecord>>
  getUnsubmittedAttendanceLocally() async {
    try {
      print('AttendanceService: Retrieving unsubmitted attendance records');
      return await _dbHelper.getUnsubmittedAttendanceRecords();
    } catch (e) {
      print('AttendanceService: Error retrieving unsubmitted attendance - $e');
      return [];
    }
  }

  /// Update attendance record in local database
  static Future<bool> updateAttendanceLocally(AttendanceRecord record) async {
    try {
      print('AttendanceService: Updating attendance record: ${record.id}');
      final result = await _dbHelper.updateAttendanceRecord(record);
      if (result) {
        print('AttendanceService: Attendance updated successfully');
      }
      return result;
    } catch (e) {
      print('AttendanceService: Error updating attendance - $e');
      return false;
    }
  }

  /// Mark attendance record as submitted/synced with backend
  static Future<bool> markAttendanceAsSubmittedLocally(String recordId) async {
    try {
      print('AttendanceService: Marking attendance as submitted: $recordId');
      final result = await _dbHelper.markAsSubmitted(recordId);
      if (result) {
        print('AttendanceService: Attendance marked as submitted');
      }
      return result;
    } catch (e) {
      print('AttendanceService: Error marking attendance as submitted - $e');
      return false;
    }
  }

  /// Delete attendance record from local database
  static Future<bool> deleteAttendanceLocally(String recordId) async {
    try {
      print('AttendanceService: Deleting attendance record: $recordId');
      final result = await _dbHelper.deleteAttendanceRecord(recordId);
      if (result) {
        print('AttendanceService: Attendance deleted successfully');
      }
      return result;
    } catch (e) {
      print('AttendanceService: Error deleting attendance - $e');
      return false;
    }
  }

  /// Get total count of attendance records in local database
  static Future<int> getTotalAttendanceCountLocally() async {
    try {
      return await _dbHelper.getTotalAttendanceRecords();
    } catch (e) {
      print('AttendanceService: Error getting attendance count - $e');
      return 0;
    }
  }

  /// Sync unsubmitted attendance records with backend
  /// Call this method periodically or when internet is available
  static Future<bool> syncAttendanceWithBackend({String? token}) async {
    try {
      print('AttendanceService: Syncing attendance with backend');

      // Get all unsubmitted records
      final unsubmittedRecords = await _dbHelper
          .getUnsubmittedAttendanceRecords();

      if (unsubmittedRecords.isEmpty) {
        print('AttendanceService: No records to sync');
        return true;
      }

      print(
        'AttendanceService: Found ${unsubmittedRecords.length} records to sync',
      );

      // TODO: Replace with actual API endpoint for batch sync
      // For now, mark them as submitted after successful API call
      for (final record in unsubmittedRecords) {
        // Uncomment below when API is ready:
        //
        // final response = await http.post(
        //   Uri.parse('$apiBaseUrl/api/attendance/sync'),
        //   headers: {
        //     'Content-Type': 'application/json',
        //     'Authorization': 'Bearer $token',
        //   },
        //   body: jsonEncode(record.toJson()),
        // );
        //
        // if (response.statusCode == 200) {
        //   await _dbHelper.markAsSubmitted(record.id);
        // } else {
        //   print('Failed to sync record: ${record.id}');
        //   return false;
        // }

        // Mock sync - in real implementation, make API call
        await Future.delayed(const Duration(milliseconds: 200));
        await _dbHelper.markAsSubmitted(record.id);
      }

      print('AttendanceService: Sync completed successfully');
      return true;
    } catch (e) {
      print('AttendanceService: Error syncing attendance - $e');
      return false;
    }
  }
}
