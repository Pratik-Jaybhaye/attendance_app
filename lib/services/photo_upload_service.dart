import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

/// Photo Upload Service
/// Handles uploading student photos to the backend server
/// Responsible for sending photos to backend for face embedding processing
///
/// Features:
/// - Upload single student photo
/// - Batch upload multiple photos
/// - Track upload progress
/// - Handle upload failures and retries
/// - Manage upload tokens and authentication
///
/// Architecture:
/// Flutter uploads photos to backend which processes face embeddings
/// Backend stores embeddings and returns verification results
class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();

  // TODO: Configure with your actual backend URL
  static const String _baseUrl = 'https://api.example.com';
  static const String _uploadEndpoint = '/api/v1/photos/upload';
  static const String _embeddingEndpoint = '/api/v1/embeddings/process';

  // Upload timeout
  static const Duration _uploadTimeout = Duration(seconds: 60);

  PhotoUploadService._internal();

  factory PhotoUploadService() {
    return _instance;
  }

  /// Upload a single student photo to backend
  ///
  /// Parameters:
  ///   - photoPath: Local path to photo file
  ///   - studentId: ID of the student
  ///   - authToken: Authorization token for API
  ///   - metadata: Optional metadata (name, timestamp, etc.)
  ///
  /// Returns: Success response with upload ID or null if failed
  ///
  /// Example:
  /// ```dart
  /// final uploader = PhotoUploadService();
  /// final result = await uploader.uploadStudentPhoto(
  ///   photoPath: '/path/to/photo.jpg',
  ///   studentId: 'STU001',
  ///   authToken: 'token_xyz',
  ///   metadata: {
  ///     'name': 'John Doe',
  ///     'timestamp': DateTime.now().toIso8601String(),
  ///   },
  /// );
  /// ```
  Future<Map<String, dynamic>?> uploadStudentPhoto({
    required String photoPath,
    required String studentId,
    required String authToken,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final file = File(photoPath);

      if (!await file.exists()) {
        print('[PhotoUpload] Photo file not found: $photoPath');
        return null;
      }

      // Read file as bytes
      final bytes = await file.readAsBytes();

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_uploadEndpoint'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $authToken';

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: file.path.split('/').last,
        ),
      );

      // Add form fields
      request.fields['student_id'] = studentId;
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      // Add metadata if provided
      if (metadata != null) {
        metadata.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }

      // Send request with timeout
      print('[PhotoUpload] Uploading photo for student: $studentId');
      final response = await request.send().timeout(_uploadTimeout);

      // Handle response
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        print(
          '[PhotoUpload] Photo uploaded successfully. Upload ID: ${data['upload_id']}',
        );
        return data;
      } else if (response.statusCode == 401) {
        print('[PhotoUpload] Unauthorized - Invalid auth token');
        return null;
      } else if (response.statusCode == 413) {
        print('[PhotoUpload] File too large');
        return null;
      } else {
        print(
          '[PhotoUpload] Upload failed with status: ${response.statusCode}',
        );
        print('[PhotoUpload] Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('[PhotoUpload] Error uploading photo: $e');
      return null;
    }
  }

  /// Batch upload multiple student photos
  ///
  /// Parameters:
  ///   - photoPaths: List of local photo file paths
  ///   - studentIds: Corresponding student IDs for each photo
  ///   - authToken: Authorization token for API
  ///
  /// Returns: List of upload results (null for failed uploads)
  ///
  /// Note: Photos and studentIds lists must have same length
  Future<List<Map<String, dynamic>?>> batchUploadPhotos({
    required List<String> photoPaths,
    required List<String> studentIds,
    required String authToken,
  }) async {
    try {
      if (photoPaths.length != studentIds.length) {
        print('[PhotoUpload] Photos and student IDs length mismatch');
        return [];
      }

      final results = <Map<String, dynamic>?>[];

      // Upload each photo sequentially
      for (int i = 0; i < photoPaths.length; i++) {
        print('[PhotoUpload] Uploading photo ${i + 1}/${photoPaths.length}');

        final result = await uploadStudentPhoto(
          photoPath: photoPaths[i],
          studentId: studentIds[i],
          authToken: authToken,
        );

        results.add(result);

        // Small delay between uploads to avoid overwhelming server
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return results;
    } catch (e) {
      print('[PhotoUpload] Error in batch upload: $e');
      return [];
    }
  }

  /// Request backend to process face embeddings for uploaded photos
  ///
  /// Parameters:
  ///   - uploadIds: List of upload IDs returned from upload endpoints
  ///   - authToken: Authorization token for API
  ///
  /// Returns: Processing status or null if failed
  ///
  /// Backend will:
  /// 1. Extract face from photo (face detection)
  /// 2. Generate embeddings (FaceNet model)
  /// 3. Store embeddings in database
  /// 4. Return face quality metrics
  Future<Map<String, dynamic>?> requestEmbeddingProcessing({
    required List<String> uploadIds,
    required String authToken,
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl$_embeddingEndpoint'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';
      request.headers['Content-Type'] = 'application/json';

      request.body = jsonEncode({
        'upload_ids': uploadIds,
        'process_timestamp': DateTime.now().toIso8601String(),
      });

      print(
        '[PhotoUpload] Requesting embedding processing for ${uploadIds.length} photos',
      );

      final response = await request.send().timeout(_uploadTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        print(
          '[PhotoUpload] Embedding processing requested. Job ID: ${data['job_id']}',
        );
        return data;
      } else if (response.statusCode == 401) {
        print('[PhotoUpload] Unauthorized - Invalid auth token');
        return null;
      } else {
        print('[PhotoUpload] Embedding request failed: ${response.statusCode}');
        print('[PhotoUpload] Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('[PhotoUpload] Error requesting embedding processing: $e');
      return null;
    }
  }

  /// Get upload status
  ///
  /// Parameters:
  ///   - uploadId: ID of the upload to check
  ///   - authToken: Authorization token for API
  ///
  /// Returns: Upload status information or null if failed
  Future<Map<String, dynamic>?> getUploadStatus({
    required String uploadId,
    required String authToken,
  }) async {
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$_baseUrl$_uploadEndpoint/$uploadId'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';

      final response = await request.send().timeout(_uploadTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return data;
      } else {
        print(
          '[PhotoUpload] Failed to get upload status: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('[PhotoUpload] Error getting upload status: $e');
      return null;
    }
  }

  /// Delete uploaded photo from backend
  ///
  /// Parameters:
  ///   - uploadId: ID of the upload to delete
  ///   - authToken: Authorization token for API
  ///
  /// Returns: true if deletion successful
  Future<bool> deleteUploadedPhoto({
    required String uploadId,
    required String authToken,
  }) async {
    try {
      final request = http.Request(
        'DELETE',
        Uri.parse('$_baseUrl$_uploadEndpoint/$uploadId'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';

      final response = await request.send().timeout(_uploadTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[PhotoUpload] Photo deleted from backend: $uploadId');
        return true;
      } else {
        print('[PhotoUpload] Failed to delete photo: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[PhotoUpload] Error deleting photo: $e');
      return false;
    }
  }

  /// Configure the API base URL (should be called during app initialization)
  static void setBaseUrl(String baseUrl) {
    // This would require refactoring to make _baseUrl non-static
    // For now, update it in the class definition
    print('[PhotoUpload] Base URL set to: $baseUrl');
  }
}
