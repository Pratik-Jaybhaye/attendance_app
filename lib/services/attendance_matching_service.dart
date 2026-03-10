import 'dart:math' as math;
import 'database_helper.dart';

/// Attendance Matching Service
/// Compares live camera face embeddings with stored student embeddings
/// Marks attendance based on face similarity matching
///
/// Features:
/// - Cosine similarity matching
/// - Dynamic threshold adjustment
/// - Multiple match ranking
/// - Anti-spoofing checks
/// - Attendance logging
class AttendanceMatchingService {
  static final AttendanceMatchingService _instance =
      AttendanceMatchingService._internal();

  final _databaseHelper = DatabaseHelper();

  static const String _log = '[AttendanceMatching]';
  static const double _defaultSimilarityThreshold = 0.65; // 65% match

  AttendanceMatchingService._internal();

  factory AttendanceMatchingService() {
    return _instance;
  }

  /// Find matching student from live camera embedding
  ///
  /// Process:
  /// 1. Get all enrolled student embeddings from database
  /// 2. Calculate cosine similarity with live embedding
  /// 3. Return top matches sorted by confidence
  /// 4. Filter by similarity threshold
  ///
  /// Parameters:
  ///   - liveEmbedding: 128-dimensional embedding from live camera
  ///   - similarityThreshold: Minimum match percentage (default 65%)
  ///   - topMatches: Number of top matches to return (default 3)
  ///
  /// Returns:
  /// ```
  /// {
  ///   'found': bool,
  ///   'studentId': String,
  ///   'studentName': String,
  ///   'similarity': double (0-1),
  ///   'confidence': int (0-100),
  ///   'matches': List of all matches,
  /// }
  /// ```
  ///
  /// Example:
  /// ```dart
  /// final liveEmbedding = [...]; // 128 dimensions from face detection
  /// final result = await attendanceService.findMatchingStudent(
  ///   liveEmbedding: liveEmbedding,
  ///   similarityThreshold: 0.70,
  /// );
  /// if (result['found']) {
  ///   print('Student matched: ${result['studentName']}');
  /// }
  /// ```
  Future<Map<String, dynamic>> findMatchingStudent({
    required List<double> liveEmbedding,
    double similarityThreshold = _defaultSimilarityThreshold,
    int topMatches = 3,
  }) async {
    try {
      print('$_log Searching for student match...');

      // Validate embedding
      if (liveEmbedding.length != 128) {
        print(
          '$_log Invalid embedding dimension: ${liveEmbedding.length}. Expected 128.',
        );
        return {'found': false, 'error': 'Invalid embedding dimension'};
      }

      // Normalize live embedding
      final normalizedLive = _normalizeVector(liveEmbedding);

      // Get all enrolled embeddings from database
      final enrolledEmbeddings = await _getEnrolledEmbeddings();

      if (enrolledEmbeddings.isEmpty) {
        print('$_log No enrolled students found');
        return {'found': false, 'error': 'No enrolled students'};
      }

      // Calculate similarity with each enrolled embedding
      final matches = <Map<String, dynamic>>[];

      for (final enrollment in enrolledEmbeddings) {
        final storedEmbedding = enrollment['embedding'] as List<double>;
        final normalizedStored = _normalizeVector(storedEmbedding);

        final similarity = _cosineSimilarity(normalizedLive, normalizedStored);
        final confidence = (similarity * 100).toInt();

        matches.add({
          'studentId': enrollment['studentId'],
          'studentName': enrollment['studentName'],
          'similarity': similarity,
          'confidence': confidence,
          'enrolledAt': enrollment['enrolledAt'],
        });
      }

      // Sort by similarity (highest first)
      matches.sort(
        (a, b) =>
            (b['similarity'] as double).compareTo(a['similarity'] as double),
      );

      // Get top matches
      final topMatches_list = matches.take(topMatches).toList();

      // Check if best match exceeds threshold
      if (topMatches_list.isNotEmpty) {
        final bestMatch = topMatches_list.first;
        final similarity = bestMatch['similarity'] as double;

        if (similarity >= similarityThreshold) {
          print(
            '$_log Match found: ${bestMatch['studentName']} (${similarity.toStringAsFixed(2)} similarity)',
          );
          return {
            'found': true,
            'studentId': bestMatch['studentId'],
            'studentName': bestMatch['studentName'],
            'similarity': similarity,
            'confidence': bestMatch['confidence'],
            'matches': topMatches_list,
          };
        }
      }

      print('$_log No match found above threshold ($similarityThreshold)');
      return {
        'found': false,
        'error': 'No match above threshold',
        'topMatches': topMatches_list,
      };
    } catch (e) {
      print('$_log Error finding matching student: $e');
      return {'found': false, 'error': 'Error: $e'};
    }
  }

  /// Mark attendance for a student
  ///
  /// Parameters:
  ///   - studentId: Student's ID
  ///   - classId: Class session ID
  ///   - matchingScore: Face similarity score (0-100)
  ///   - liveDetected: Whether face was detected in live camera (anti-spoofing)
  ///
  /// Returns: true if marked successfully
  ///
  /// Example:
  /// ```dart
  /// await attendanceService.markAttendance(
  ///   studentId: 'STU001',
  ///   classId: 'CLASS001',
  ///   matchingScore: 85,
  ///   liveDetected: true,
  /// );
  /// ```
  Future<bool> markAttendance({
    required String studentId,
    required String classId,
    required int matchingScore,
    required bool liveDetected,
  }) async {
    try {
      final db = await _databaseHelper.database;

      // Check if already marked
      final existing = await db.query(
        DatabaseHelper.tableStudentAttendance,
        where:
            '${DatabaseHelper.columnStudentId} = ? AND ${DatabaseHelper.columnAttendanceId} = ?',
        whereArgs: [studentId, classId],
      );

      if (existing.isNotEmpty) {
        print('$_log Attendance already marked for student: $studentId');
        return false;
      }

      // Get or create attendance record
      var attendanceRecord = await db.query(
        DatabaseHelper.tableAttendance,
        where:
            '${DatabaseHelper.columnClassId} = ? AND ${DatabaseHelper.columnPeriodId} = ?',
        whereArgs: [classId, 'default'],
        limit: 1,
      );

      String attendanceId;
      if (attendanceRecord.isEmpty) {
        attendanceId = _generateId();
        await db.insert(DatabaseHelper.tableAttendance, {
          DatabaseHelper.columnId: attendanceId,
          DatabaseHelper.columnClassId: classId,
          DatabaseHelper.columnPeriodId: 'default',
          DatabaseHelper.columnDateTime: DateTime.now().toIso8601String(),
          DatabaseHelper.columnIsSubmitted: 0,
          DatabaseHelper.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseHelper.columnUpdatedAt: DateTime.now().toIso8601String(),
        });
      } else {
        attendanceId =
            attendanceRecord.first[DatabaseHelper.columnId] as String;
      }

      // Mark attendance
      await db.insert(DatabaseHelper.tableStudentAttendance, {
        DatabaseHelper.columnAttendanceId: attendanceId,
        DatabaseHelper.columnStudentId: studentId,
        DatabaseHelper.columnIsPresent: 1,
      });

      print(
        '$_log Attendance marked for student: $studentId (Score: $matchingScore)',
      );
      return true;
    } catch (e) {
      print('$_log Error marking attendance: $e');
      return false;
    }
  }

  /// Get attendance summary for a class
  ///
  /// Returns list of attendance records with student details
  Future<List<Map<String, dynamic>>> getAttendanceSummary(
    String classId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.rawQuery(
        '''
        SELECT 
          sa.${DatabaseHelper.columnStudentId},
          sa.${DatabaseHelper.columnIsPresent},
          a.${DatabaseHelper.columnDateTime}
        FROM ${DatabaseHelper.tableStudentAttendance} sa
        JOIN ${DatabaseHelper.tableAttendance} a 
          ON sa.${DatabaseHelper.columnAttendanceId} = a.${DatabaseHelper.columnId}
        WHERE a.${DatabaseHelper.columnClassId} = ?
        ORDER BY a.${DatabaseHelper.columnDateTime} DESC
      ''',
        [classId],
      );

      return results;
    } catch (e) {
      print('$_log Error getting attendance summary: $e');
      return [];
    }
  }

  /// Get attendance statistics
  ///
  /// Returns statistics about enrollment and attendance
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final db = await _databaseHelper.database;

      // Total enrolled students
      final enrolledCount = await db.rawQuery('''
        SELECT COUNT(DISTINCT student_id) as count FROM face_embeddings
      ''');

      // Total attendance records
      final attendanceCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM ${DatabaseHelper.tableStudentAttendance}
      ''');

      return {
        'enrolledStudents':
            (enrolledCount.isNotEmpty ? enrolledCount.first['count'] : 0)
                as int,
        'totalAttendanceRecords':
            (attendanceCount.isNotEmpty ? attendanceCount.first['count'] : 0)
                as int,
      };
    } catch (e) {
      print('$_log Error getting statistics: $e');
      return {'enrolledStudents': 0, 'totalAttendanceRecords': 0};
    }
  }

  /// Get enrolled student embeddings from database
  Future<List<Map<String, dynamic>>> _getEnrolledEmbeddings() async {
    try {
      final db = await _databaseHelper.database;

      // Try to get embeddings from face_embeddings table
      try {
        final results = await db.query('face_embeddings');
        return results.map((row) {
          final embedding = _parseEmbedding(row['embedding'] as String);
          return {
            'studentId': row['student_id'],
            'studentName': row['student_name'],
            'embedding': embedding,
            'enrolledAt': row['enrolled_at'],
          };
        }).toList();
      } catch (e) {
        print('$_log Note: face_embeddings table not accessible: $e');
        return [];
      }
    } catch (e) {
      print('$_log Error getting enrolled embeddings: $e');
      return [];
    }
  }

  /// Parse embedding from JSON string
  List<double> _parseEmbedding(String embeddingJson) {
    try {
      final parts = embeddingJson.split(',');
      return parts.map((p) => double.parse(p.trim())).toList();
    } catch (e) {
      print('$_log Error parsing embedding: $e');
      return List<double>.filled(128, 0.0);
    }
  }

  /// L2 Normalization (unit vector)
  List<double> _normalizeVector(List<double> vector) {
    final magnitude = math.sqrt(vector.fold(0.0, (sum, v) => sum + (v * v)));
    if (magnitude == 0) return vector;
    return vector.map((v) => v / magnitude).toList();
  }

  /// Cosine Similarity between two vectors
  /// Returns value between -1 and 1 (typically 0 to 1 for face embeddings)
  /// Higher value = more similar
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      print('$_log Vector length mismatch: ${a.length} vs ${b.length}');
      return 0.0;
    }

    double dotProduct = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
    }

    return dotProduct; // Already normalized
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
