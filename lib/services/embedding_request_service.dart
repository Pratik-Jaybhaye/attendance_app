import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/photo.dart';
import 'dart:io';

/// Embedding Request Service
/// Handles communication with backend for face embeddings and verification
/// Requests embeddings generation, stores verification results
///
/// Features:
/// - Request embeddings for uploaded photos
/// - Verify faces during attendance
/// - Retrieve embedding data
/// - Track verification history
/// - Handle embedding model updates
///
/// Backend Responsibilities:
/// - Extract faces from photos (face detection)
/// - Generate 128-dimensional embeddings using FaceNet
/// - Store embeddings in database
/// - Perform face matching and verification
class EmbeddingRequestService {
  static final EmbeddingRequestService _instance =
      EmbeddingRequestService._internal();

  // TODO: Configure with your actual backend URL
  static const String _baseUrl = 'https://api.example.com';
  static const String _embeddingsEndpoint = '/api/v1/embeddings';
  static const String _verificationEndpoint = '/api/v1/embeddings/verify';
  static const String _matchingEndpoint = '/api/v1/embeddings/match';

  static const Duration _requestTimeout = Duration(seconds: 30);

  EmbeddingRequestService._internal();

  factory EmbeddingRequestService() {
    return _instance;
  }

  /// Request backend to generate face embeddings for uploaded photos
  ///
  /// Parameters:
  ///   - uploadIds: List of upload IDs to process
  ///   - authToken: Authorization token
  ///   - priority: 'high', 'normal', 'low' - processing priority
  ///
  /// Returns: Processing job information or null if failed
  ///
  /// Example:
  /// ```dart
  /// final embeddingService = EmbeddingRequestService();
  /// final result = await embeddingService.requestEmbeddingGeneration(
  ///   uploadIds: ['upload_1', 'upload_2'],
  ///   authToken: 'token_xyz',
  ///   priority: 'high',
  /// );
  /// // Returns: {'job_id': 'job_123', 'status': 'processing', 'estimated_time': 5}
  /// ```
  Future<Map<String, dynamic>?> requestEmbeddingGeneration({
    required List<String> uploadIds,
    required String authToken,
    String priority = 'normal',
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl$_embeddingsEndpoint/generate'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';
      request.headers['Content-Type'] = 'application/json';

      request.body = jsonEncode({
        'upload_ids': uploadIds,
        'priority': priority,
        'requested_at': DateTime.now().toIso8601String(),
      });

      print(
        '[EmbeddingRequest] Requesting embeddings for ${uploadIds.length} photos',
      );

      final response = await request.send().timeout(_requestTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        print('[EmbeddingRequest] Job created: ${data['job_id']}');
        return data;
      } else if (response.statusCode == 401) {
        print('[EmbeddingRequest] Unauthorized - Invalid auth token');
        return null;
      } else {
        print('[EmbeddingRequest] Request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[EmbeddingRequest] Error requesting embeddings: $e');
      return null;
    }
  }

  /// Get embeddings for a specific student
  ///
  /// Parameters:
  ///   - studentId: Student ID
  ///   - authToken: Authorization token
  ///   - limit: Max number of embeddings to retrieve
  ///
  /// Returns: List of EmbeddingResponse objects
  Future<List<EmbeddingResponse>> getStudentEmbeddings({
    required String studentId,
    required String authToken,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl$_embeddingsEndpoint/student/$studentId',
      ).replace(queryParameters: {'limit': '$limit'});

      final request = http.Request('GET', uri);
      request.headers['Authorization'] = 'Bearer $authToken';

      print('[EmbeddingRequest] Fetching embeddings for student: $studentId');

      final response = await request.send().timeout(_requestTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final embeddings =
            (data['embeddings'] as List?)
                ?.map((e) => EmbeddingResponse.fromJson(e))
                .toList() ??
            [];
        print('[EmbeddingRequest] Retrieved ${embeddings.length} embeddings');
        return embeddings;
      } else {
        print(
          '[EmbeddingRequest] Failed to fetch embeddings: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('[EmbeddingRequest] Error fetching embeddings: $e');
      return [];
    }
  }

  /// Verify a face during attendance
  /// Compares captured face with enrolled student face embeddings
  ///
  /// Parameters:
  ///   - studentId: Student to verify
  ///   - capturedPhotoPath: Path to captured photo (local)
  ///   - authToken: Authorization token
  ///   - threshold: Similarity threshold (0.0-1.0, default 0.6)
  ///
  /// Returns: FaceVerificationResult or null if failed
  ///
  /// Example:
  /// ```dart
  /// final result = await embeddingService.verifyFace(
  ///   studentId: 'STU001',
  ///   capturedPhotoPath: '/path/to/captured.jpg',
  ///   authToken: 'token_xyz',
  ///   threshold: 0.65,
  /// );
  /// if (result?.isVerified ?? false) {
  ///   print('Face verified!');
  /// }
  /// ```
  Future<FaceVerificationResult?> verifyFace({
    required String studentId,
    required String capturedPhotoPath,
    required String authToken,
    double threshold = 0.6,
  }) async {
    try {
      final photoFile = File(capturedPhotoPath);

      if (!await photoFile.exists()) {
        print('[EmbeddingRequest] Photo file not found');
        return null;
      }

      // Read photo as bytes
      final photoBytes = await photoFile.readAsBytes();

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_verificationEndpoint'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';

      // Add photo
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photoBytes,
          filename: photoFile.path.split('/').last,
        ),
      );

      // Add form fields
      request.fields['student_id'] = studentId;
      request.fields['threshold'] = threshold.toString();
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      print('[EmbeddingRequest] Verifying face for student: $studentId');

      final response = await request.send().timeout(_requestTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final result = FaceVerificationResult.fromJson(data);
        print(
          '[EmbeddingRequest] Face verification - Status: ${result.verificationStatus}',
        );
        return result;
      } else if (response.statusCode == 400) {
        print('[EmbeddingRequest] Bad request - Invalid student or photo');
        return null;
      } else {
        print('[EmbeddingRequest] Verification failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[EmbeddingRequest] Error verifying face: $e');
      return null;
    }
  }

  /// Batch verify multiple captured faces
  ///
  /// Parameters:
  ///   - studentIds: List of student IDs to verify
  ///   - photoPaths: Corresponding photo paths
  ///   - authToken: Authorization token
  ///
  /// Returns: List of verification results
  Future<List<FaceVerificationResult>> batchVerifyFaces({
    required List<String> studentIds,
    required List<String> photoPaths,
    required String authToken,
  }) async {
    try {
      if (studentIds.length != photoPaths.length) {
        print('[EmbeddingRequest] StudentIds and photos length mismatch');
        return [];
      }

      final results = <FaceVerificationResult>[];

      for (int i = 0; i < studentIds.length; i++) {
        print('[EmbeddingRequest] Verifying ${i + 1}/${studentIds.length}');

        final result = await verifyFace(
          studentId: studentIds[i],
          capturedPhotoPath: photoPaths[i],
          authToken: authToken,
        );

        if (result != null) {
          results.add(result);
        }

        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 200));
      }

      return results;
    } catch (e) {
      print('[EmbeddingRequest] Error in batch verification: $e');
      return [];
    }
  }

  /// Match a face against all enrolled students (1-to-many matching)
  /// Useful for identifying unknown faces in photos
  ///
  /// Parameters:
  ///   - photoPath: Path to photo with face to match
  ///   - authToken: Authorization token
  ///   - limit: Max results to return
  ///   - threshold: Minimum similarity threshold
  ///
  /// Returns: List of matching students sorted by similarity
  Future<List<Map<String, dynamic>>> matchFace({
    required String photoPath,
    required String authToken,
    int limit = 5,
    double threshold = 0.5,
  }) async {
    try {
      final photoFile = File(photoPath);

      if (!await photoFile.exists()) {
        print('[EmbeddingRequest] Photo file not found');
        return [];
      }

      final photoBytes = await photoFile.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_matchingEndpoint'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photoBytes,
          filename: photoFile.path.split('/').last,
        ),
      );

      request.fields['limit'] = limit.toString();
      request.fields['threshold'] = threshold.toString();

      print('[EmbeddingRequest] Matching face against enrolled students');

      final response = await request.send().timeout(_requestTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final matches =
            (data['matches'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        print('[EmbeddingRequest] Found ${matches.length} matches');
        return matches;
      } else {
        print('[EmbeddingRequest] Matching failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[EmbeddingRequest] Error matching face: $e');
      return [];
    }
  }

  /// Get processing job status
  ///
  /// Parameters:
  ///   - jobId: Job ID from embedding generation request
  ///   - authToken: Authorization token
  ///
  /// Returns: Job status information or null
  Future<Map<String, dynamic>?> getJobStatus({
    required String jobId,
    required String authToken,
  }) async {
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_baseUrl$_embeddingsEndpoint/jobs/$jobId'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';

      final response = await request.send().timeout(_requestTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return data;
      } else {
        print(
          '[EmbeddingRequest] Failed to get job status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('[EmbeddingRequest] Error getting job status: $e');
      return null;
    }
  }

  /// Re-enroll a student with new embeddings
  /// Replaces old embeddings with new ones from new photos
  ///
  /// Parameters:
  ///   - studentId: Student ID to re-enroll
  ///   - uploadIds: New upload IDs for re-enrollment
  ///   - authToken: Authorization token
  ///
  /// Returns: Success status
  Future<bool> reenrollStudent({
    required String studentId,
    required List<String> uploadIds,
    required String authToken,
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl$_embeddingsEndpoint/reenroll'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';
      request.headers['Content-Type'] = 'application/json';

      request.body = jsonEncode({
        'student_id': studentId,
        'upload_ids': uploadIds,
        'requested_at': DateTime.now().toIso8601String(),
      });

      print('[EmbeddingRequest] Re-enrolling student: $studentId');

      final response = await request.send().timeout(_requestTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 202) {
        print('[EmbeddingRequest] Re-enrollment successful');
        return true;
      } else {
        print(
          '[EmbeddingRequest] Re-enrollment failed: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('[EmbeddingRequest] Error during re-enrollment: $e');
      return false;
    }
  }

  /// Configure the API base URL (should be called during app initialization)
  static void setBaseUrl(String baseUrl) {
    print('[EmbeddingRequest] Base URL set to: $baseUrl');
  }
}
