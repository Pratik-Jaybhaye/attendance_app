import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'face_recognition_service.dart';

/// Face Embedding Service
/// High-level interface for managing face embeddings in SQLite database
///
/// Features:
/// - Student face enrollment and management
/// - Batch embedding storage
/// - Embedding statistics and monitoring
/// - Student face removal and updates
class FaceEmbeddingService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();

  static const String _log = '[FaceEmbedding]';

  /// Enroll a student with their face embedding
  /// Stores a single face embedding for a student in the database
  ///
  /// Parameters:
  ///   - studentId: Unique student identifier
  ///   - studentName: Full name of student
  ///   - embeddingVector: 128-dimensional face vector (from FaceNet model)
  ///
  /// Returns: true if enrollment successful
  ///
  /// Usage:
  /// ```dart
  /// final faceEmbed = FaceEmbeddingService();
  /// final embedding = [0.1, 0.2, ..., -0.3]; // 128 values
  /// await faceEmbed.enrollStudentFace(
  ///   studentId: 'STU001',
  ///   studentName: 'John Doe',
  ///   embeddingVector: embedding,
  /// );
  /// ```
  Future<bool> enrollStudentFace({
    required String studentId,
    required String studentName,
    required List<double> embeddingVector,
  }) async {
    try {
      // Validate embedding dimension
      if (embeddingVector.length != 128) {
        print(
          '$_log Invalid embedding dimension: ${embeddingVector.length}. Expected 128.',
        );
        return false;
      }

      // Generate unique embedding ID
      const uuid = Uuid();
      final embeddingId = uuid.v4();

      // Save to database
      final success = await _faceRecognitionService.saveFaceEmbeddingToDatabase(
        embeddingId: embeddingId,
        studentId: studentId,
        studentName: studentName,
        embeddingVector: embeddingVector,
        enrolledAt: DateTime.now(),
      );

      if (success) {
        print('$_log Enrolled face for: $studentName (ID: $studentId)');
      }

      return success;
    } catch (e) {
      print('$_log Error enrolling student face: $e');
      return false;
    }
  }

  /// Enroll multiple students with their face embeddings (batch)
  /// Efficient batch enrollment for multiple students at once
  ///
  /// Parameters:
  ///   - enrollments: List of enrollment data with studentId, studentName, and embeddingVector
  ///
  /// Returns: true if all enrollments successful
  ///
  /// Usage:
  /// ```dart
  /// final enrollments = [
  ///   {
  ///     'studentId': 'STU001',
  ///     'studentName': 'John Doe',
  ///     'embeddingVector': [...128 values...],
  ///   },
  ///   {
  ///     'studentId': 'STU002',
  ///     'studentName': 'Jane Smith',
  ///     'embeddingVector': [...128 values...],
  ///   },
  /// ];
  /// await faceEmbed.batchEnrollStudents(enrollments);
  /// ```
  Future<bool> batchEnrollStudents(
    List<Map<String, dynamic>> enrollments,
  ) async {
    try {
      print(
        '$_log Starting batch enrollment for ${enrollments.length} students...',
      );

      final embeddingMaps = <Map<String, dynamic>>[];

      for (final enrollment in enrollments) {
        final embeddingVector = enrollment['embeddingVector'] as List<double>;

        // Validate embedding dimension
        if (embeddingVector.length != 128) {
          print(
            '$_log Skipping ${enrollment['studentName']}: Invalid embedding dimension',
          );
          continue;
        }

        const uuid = Uuid();
        embeddingMaps.add({
          'embeddingId': uuid.v4(),
          'studentId': enrollment['studentId'] as String,
          'studentName': enrollment['studentName'] as String,
          'embeddingVector': embeddingVector,
          'enrolledAt': DateTime.now(),
        });
      }

      if (embeddingMaps.isEmpty) {
        print('$_log No valid embeddings to enroll');
        return false;
      }

      final success = await _databaseHelper.saveBatchFaceEmbeddings(
        embeddingMaps,
      );

      if (success) {
        print(
          '$_log Successfully batch enrolled ${embeddingMaps.length} students',
        );
      }

      return success;
    } catch (e) {
      print('$_log Error in batch enrollment: $e');
      return false;
    }
  }

  /// Re-enroll a student with new face embedding(s)
  /// Deletes all old embeddings and adds new ones
  ///
  /// Parameters:
  ///   - studentId: Student to re-enroll
  ///   - studentName: Student name
  ///   - newEmbeddings: New embedding vectors (can be multiple for robustness)
  ///
  /// Returns: true if successful
  Future<bool> reenrollStudent({
    required String studentId,
    required String studentName,
    required List<List<double>> newEmbeddings,
  }) async {
    try {
      print('$_log Re-enrolling student: $studentName (ID: $studentId)');

      // Delete old embeddings
      await _faceRecognitionService.deleteStudentEmbeddingsFromDatabase(
        studentId,
      );

      // Create enrollment data for new embeddings
      final enrollments = newEmbeddings
          .map(
            (embedding) => {
              'embeddingId':
                  '${studentId}_${DateTime.now().millisecondsSinceEpoch}_${newEmbeddings.indexOf(embedding)}',
              'studentId': studentId,
              'studentName': studentName,
              'embeddingVector': embedding,
              'enrolledAt': DateTime.now(),
            },
          )
          .toList();

      // Save new embeddings
      final success = await _databaseHelper.saveBatchFaceEmbeddings(
        enrollments,
      );

      if (success) {
        print(
          '$_log Re-enrolled student with ${newEmbeddings.length} embeddings',
        );
      }

      return success;
    } catch (e) {
      print('$_log Error re-enrolling student: $e');
      return false;
    }
  }

  /// Remove student from face database
  /// Deletes all face embeddings for a student
  ///
  /// Parameters:
  ///   - studentId: Student to remove
  ///
  /// Returns: true if successful
  ///
  /// Usage:
  /// ```dart
  /// await faceEmbed.removeStudent('STU001');
  /// ```
  Future<bool> removeStudent(String studentId) async {
    try {
      print('$_log Removing student from face database: $studentId');
      return await _faceRecognitionService.deleteStudentEmbeddingsFromDatabase(
        studentId,
      );
    } catch (e) {
      print('$_log Error removing student: $e');
      return false;
    }
  }

  /// Get statistics about face embeddings in database
  /// Returns summary information about stored embeddings
  ///
  /// Returns: Map with keys:
  ///   - totalEmbeddings: Total embeddings stored
  ///   - enrolledStudents: Number of students with embeddings
  ///   - databaseSize: Approximate size
  ///
  /// Usage:
  /// ```dart
  /// final stats = await faceEmbed.getEmbeddingStats();
  /// print('Total embeddings: ${stats['totalEmbeddings']}');
  /// print('Students enrolled: ${stats['enrolledStudents']}');
  /// ```
  Future<Map<String, dynamic>> getEmbeddingStats() async {
    try {
      final totalCount = await _faceRecognitionService
          .getTotalEmbeddingsCount();

      // Get all embeddings to count unique students
      final allEmbeddings = await _databaseHelper.getAllFaceEmbeddings();
      final enrolledStudents = allEmbeddings.length;

      // Calculate approximate database size
      // Each embedding: 128 doubles × 8 bytes = 1024 bytes
      const bytesPerEmbedding = 1024;
      final approximateSize = totalCount * bytesPerEmbedding;
      final sizeMB = approximateSize / (1024 * 1024);

      return {
        'totalEmbeddings': totalCount,
        'enrolledStudents': enrolledStudents,
        'databaseSize': '${sizeMB.toStringAsFixed(2)} MB',
        'averageEmbeddingsPerStudent': enrolledStudents > 0
            ? (totalCount / enrolledStudents).toStringAsFixed(1)
            : 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('$_log Error getting stats: $e');
      return {
        'totalEmbeddings': 0,
        'enrolledStudents': 0,
        'databaseSize': '0 MB',
      };
    }
  }

  /// Check if student is enrolled in face database
  ///
  /// Parameters:
  ///   - studentId: Student to check
  ///
  /// Returns: true if student has face embeddings
  Future<bool> isStudentEnrolled(String studentId) async {
    try {
      final count = await _faceRecognitionService.getStudentEmbeddingCount(
        studentId,
      );
      return count > 0;
    } catch (e) {
      print('$_log Error checking enrollment: $e');
      return false;
    }
  }

  /// Get number of embeddings for a student
  ///
  /// Parameters:
  ///   - studentId: Student to check
  ///
  /// Returns: Number of face embeddings stored
  Future<int> getStudentEmbeddingCount(String studentId) async {
    try {
      return await _faceRecognitionService.getStudentEmbeddingCount(studentId);
    } catch (e) {
      print('$_log Error getting embedding count: $e');
      return 0;
    }
  }

  /// Load all embeddings into memory for recognition
  /// Call this during app initialization or class selection
  /// Preloads all student embeddings for fast face recognition
  ///
  /// Usage:
  /// ```dart
  /// await faceEmbed.preloadAllEmbeddings();
  /// ```
  Future<void> preloadAllEmbeddings() async {
    try {
      print('$_log Preloading all embeddings from database...');
      await _faceRecognitionService.preloadAllEmbeddings();
    } catch (e) {
      print('$_log Error preloading embeddings: $e');
    }
  }

  /// Load specific students' embeddings
  /// Loads only embeddings for specified students
  ///
  /// Parameters:
  ///   - studentIds: List of student IDs to load
  ///
  /// Usage:
  /// ```dart
  /// await faceEmbed.loadStudentEmbeddings(['STU001', 'STU002']);
  /// ```
  Future<void> loadStudentEmbeddings(List<String> studentIds) async {
    try {
      print('$_log Loading ${studentIds.length} students embeddings...');
      await _faceRecognitionService.loadStudentEmbeddings(studentIds);
    } catch (e) {
      print('$_log Error loading student embeddings: $e');
    }
  }

  /// Clear in-memory embedding cache
  /// Frees up RAM but embeddings remain in database
  void clearCache() {
    print('$_log Clearing embedding cache from memory');
    _faceRecognitionService.clearCache();
  }

  /// Validate embedding vector
  /// Checks if embedding has correct dimension and values
  ///
  /// Parameters:
  ///   - embedding: Vector to validate
  ///
  /// Returns: true if valid
  static bool isValidEmbedding(List<double> embedding) {
    if (embedding.length != 128) {
      return false;
    }

    // Check for NaN or infinite values
    for (final value in embedding) {
      if (value.isNaN || value.isInfinite) {
        return false;
      }
    }

    return true;
  }

  /// Normalize embedding vector to unit length
  /// Ensures consistent comparison across embeddings
  ///
  /// Parameters:
  ///   - embedding: Vector to normalize
  ///
  /// Returns: Normalized vector
  static List<double> normalizeEmbedding(List<double> embedding) {
    final magnitude = math.sqrt(embedding.fold(0.0, (sum, v) => sum + (v * v)));

    if (magnitude == 0) return embedding;
    return embedding.map((v) => v / magnitude).toList();
  }

  /// Calculate cosine similarity between two embeddings
  /// Used for face matching with range 0-1
  ///
  /// Parameters:
  ///   - vec1: First embedding vector
  ///   - vec2: Second embedding vector
  ///
  /// Returns: Similarity score (0-1, where 1 is identical)
  static double cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.length != vec2.length) {
      throw ArgumentError('Vectors must have same dimension');
    }

    double dotProduct = 0.0;
    double mag1 = 0.0;
    double mag2 = 0.0;

    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
      mag1 += vec1[i] * vec1[i];
      mag2 += vec2[i] * vec2[i];
    }

    final denominator = math.sqrt(mag1) * math.sqrt(mag2);
    if (denominator == 0) return 0.0;

    return (dotProduct / denominator).clamp(0.0, 1.0);
  }

  /// Generate mock embedding for testing
  /// Creates a random 128-dimensional vector
  ///
  /// Returns: Random embedding vector
  static List<double> generateMockEmbedding() {
    final random = math.Random();
    return List.generate(128, (_) => (random.nextDouble() - 0.5) * 2);
  }
}
