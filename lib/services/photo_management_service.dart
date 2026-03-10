import 'package:uuid/uuid.dart';
import 'photo_storage_service.dart';
import 'photo_upload_service.dart';
import 'embedding_request_service.dart';
import '../models/photo.dart';

/// Photo Management Service
/// Comprehensive service for managing student photos end-to-end
///
/// Orchestrates:
/// 1. Local photo storage (PhotoStorageService)
/// 2. Database tracking (DatabaseHelper)
/// 3. Backend upload (PhotoUploadService)
/// 4. Embedding processing (EmbeddingRequestService)
///
/// Architecture:
/// Capture → Store Locally → Track in DB → Upload to Backend → Process Embeddings
class PhotoManagementService {
  static final PhotoManagementService _instance =
      PhotoManagementService._internal();

  final PhotoStorageService _photoStorage = PhotoStorageService();
  final PhotoUploadService _photoUploader = PhotoUploadService();
  final EmbeddingRequestService _embeddingService = EmbeddingRequestService();

  static const String _log = '[PhotoManagement]';

  PhotoManagementService._internal();

  factory PhotoManagementService() {
    return _instance;
  }

  // ==================== LOCAL STORAGE ====================

  /// Save captured photo and create database record
  ///
  /// Parameters:
  ///   - sourceImagePath: Path to captured image
  ///   - studentId: ID of the student
  ///   - metadata: Optional metadata (name, timestamp, etc.)
  ///
  /// Returns: Photo object with stored path or null if failed
  ///
  /// Example:
  /// ```dart
  /// final photoMgmt = PhotoManagementService();
  /// final photo = await photoMgmt.saveCapturedPhoto(
  ///   sourceImagePath: '/tmp/photo.jpg',
  ///   studentId: 'STU001',
  ///   metadata: {'name': 'John Doe'},
  /// );
  /// ```
  Future<Photo?> saveCapturedPhoto({
    required String sourceImagePath,
    required String studentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('$_log Saving captured photo for student: $studentId');

      // Save photo to local storage
      final storedPath = await _photoStorage.saveStudentPhoto(
        sourceImagePath: sourceImagePath,
        studentId: studentId,
      );

      if (storedPath == null) {
        print('$_log Failed to save photo locally');
        return null;
      }

      // Create Photo object
      final photo = Photo(
        id: const Uuid().v4(),
        studentId: studentId,
        localPath: storedPath,
        capturedAt: DateTime.now(),
        photoQuality: 'unknown',
        processingStatus: 'pending',
      );

      // Save to database
      final saved = await _savePhotoToDatabase(photo);
      if (!saved) {
        print('$_log Failed to save photo record to database');
        return null;
      }

      print('$_log Photo saved successfully: ${photo.id}');
      return photo;
    } catch (e) {
      print('$_log Error saving captured photo: $e');
      return null;
    }
  }

  /// Get all photos for a student
  Future<List<Photo>> getStudentPhotos(String studentId) async {
    try {
      final photos = await _getPhotosFromDatabase(studentId);
      return photos;
    } catch (e) {
      print('$_log Error getting student photos: $e');
      return [];
    }
  }

  /// Get latest photo for a student
  Future<Photo?> getLatestStudentPhoto(String studentId) async {
    try {
      final photos = await getStudentPhotos(studentId);
      if (photos.isEmpty) {
        return null;
      }

      // Sort by captured time, newest first
      photos.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      return photos.first;
    } catch (e) {
      print('$_log Error getting latest student photo: $e');
      return null;
    }
  }

  // ==================== UPLOAD TO BACKEND ====================

  /// Upload photo to backend
  ///
  /// Parameters:
  ///   - photoId: ID of photo to upload
  ///   - authToken: Authorization token
  ///
  /// Returns: Updated Photo with upload info or null
  Future<Photo?> uploadPhoto({
    required String photoId,
    required String authToken,
  }) async {
    try {
      // Get photo from database
      final photo = await _getPhotoFromDatabase(photoId);
      if (photo == null) {
        print('$_log Photo not found: $photoId');
        return null;
      }

      print('$_log Uploading photo: $photoId');

      // Upload to backend
      final uploadResponse = await _photoUploader.uploadStudentPhoto(
        photoPath: photo.localPath,
        studentId: photo.studentId,
        authToken: authToken,
        metadata: {
          'photo_id': photoId,
          'captured_at': photo.capturedAt.toIso8601String(),
        },
      );

      if (uploadResponse == null) {
        print('$_log Failed to upload photo to backend');
        return null;
      }

      // Update photo with upload info
      final uploadId = uploadResponse['upload_id'] as String? ?? '';
      final cloudPath = uploadResponse['cloud_path'] as String? ?? '';

      final updatedPhoto = photo.copyWith(
        uploadId: uploadId,
        cloudPath: cloudPath,
        uploadedAt: DateTime.now(),
      );

      // Save updated photo to database
      final updated = await _updatePhotoInDatabase(updatedPhoto);
      if (updated) {
        print('$_log Photo uploaded successfully. Upload ID: $uploadId');
        return updatedPhoto;
      }

      return null;
    } catch (e) {
      print('$_log Error uploading photo: $e');
      return null;
    }
  }

  /// Batch upload multiple photos
  ///
  /// Parameters:
  ///   - photoIds: List of photo IDs to upload
  ///   - authToken: Authorization token
  ///   - onProgress: Optional callback for progress updates
  ///
  /// Returns: List of successfully uploaded photos
  Future<List<Photo>> batchUploadPhotos({
    required List<String> photoIds,
    required String authToken,
    Function(int uploaded, int total)? onProgress,
  }) async {
    try {
      final uploadedPhotos = <Photo>[];

      for (int i = 0; i < photoIds.length; i++) {
        print('$_log Uploading ${i + 1}/${photoIds.length}');

        final photo = await uploadPhoto(
          photoId: photoIds[i],
          authToken: authToken,
        );

        if (photo != null) {
          uploadedPhotos.add(photo);
        }

        onProgress?.call(i + 1, photoIds.length);

        // Small delay between uploads
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return uploadedPhotos;
    } catch (e) {
      print('$_log Error in batch upload: $e');
      return [];
    }
  }

  // ==================== EMBEDDING PROCESSING ====================

  /// Request embedding processing for a photo
  ///
  /// Parameters:
  ///   - photoId: ID of photo to process
  ///   - authToken: Authorization token
  ///   - priority: Processing priority
  ///
  /// Returns: Job ID or null if failed
  Future<String?> requestEmbeddingProcessing({
    required String photoId,
    required String authToken,
    String priority = 'normal',
  }) async {
    try {
      final photo = await _getPhotoFromDatabase(photoId);
      if (photo == null) {
        print('$_log Photo not found: $photoId');
        return null;
      }

      if (photo.uploadId == null) {
        print('$_log Photo not uploaded yet: $photoId');
        return null;
      }

      print('$_log Requesting embedding processing for photo: $photoId');

      final response = await _embeddingService.requestEmbeddingGeneration(
        uploadIds: [photo.uploadId!],
        authToken: authToken,
        priority: priority,
      );

      if (response == null) {
        print('$_log Failed to request embedding processing');
        return null;
      }

      final jobId = response['job_id'] as String? ?? '';

      // Update photo status
      final updatedPhoto = photo.copyWith(processingStatus: 'processing');
      await _updatePhotoInDatabase(updatedPhoto);

      return jobId;
    } catch (e) {
      print('$_log Error requesting embedding processing: $e');
      return null;
    }
  }

  /// Check embedding processing status
  Future<Map<String, dynamic>?> checkEmbeddingStatus({
    required String jobId,
    required String authToken,
  }) async {
    try {
      return await _embeddingService.getJobStatus(
        jobId: jobId,
        authToken: authToken,
      );
    } catch (e) {
      print('$_log Error checking embedding status: $e');
      return null;
    }
  }

  // ==================== VERIFICATION ====================

  /// Verify student face during attendance
  ///
  /// Parameters:
  ///   - studentId: Student ID to verify
  ///   - photoPath: Path to captured photo
  ///   - authToken: Authorization token
  ///   - threshold: Similarity threshold
  ///
  /// Returns: FaceVerificationResult or null
  Future<FaceVerificationResult?> verifyStudentFace({
    required String studentId,
    required String photoPath,
    required String authToken,
    double threshold = 0.6,
  }) async {
    try {
      print('$_log Verifying face for student: $studentId');

      final result = await _embeddingService.verifyFace(
        studentId: studentId,
        capturedPhotoPath: photoPath,
        authToken: authToken,
        threshold: threshold,
      );

      if (result != null) {
        print('$_log Face verification result: ${result.verificationStatus}');
      }

      return result;
    } catch (e) {
      print('$_log Error verifying student face: $e');
      return null;
    }
  }

  /// Get all embeddings for a student
  Future<List<EmbeddingResponse>> getStudentEmbeddings({
    required String studentId,
    required String authToken,
  }) async {
    try {
      return await _embeddingService.getStudentEmbeddings(
        studentId: studentId,
        authToken: authToken,
      );
    } catch (e) {
      print('$_log Error getting student embeddings: $e');
      return [];
    }
  }

  // ==================== CLEANUP ====================

  /// Delete a photo (local and remote)
  ///
  /// Parameters:
  ///   - photoId: Photo ID to delete
  ///   - authToken: Optional token for remote deletion
  ///   - deleteRemote: Whether to delete from backend too
  ///
  /// Returns: true if successful
  Future<bool> deletePhoto({
    required String photoId,
    String? authToken,
    bool deleteRemote = true,
  }) async {
    try {
      final photo = await _getPhotoFromDatabase(photoId);
      if (photo == null) {
        return false;
      }

      // Delete local file
      await _photoStorage.deletePhoto(photo.localPath);

      // Delete from database
      await _deletePhotoFromDatabase(photoId);

      // Delete from backend if upload ID exists
      if (deleteRemote && photo.uploadId != null && authToken != null) {
        await _photoUploader.deleteUploadedPhoto(
          uploadId: photo.uploadId!,
          authToken: authToken,
        );
      }

      print('$_log Photo deleted: $photoId');
      return true;
    } catch (e) {
      print('$_log Error deleting photo: $e');
      return false;
    }
  }

  /// Delete all photos for a student
  Future<bool> deleteAllStudentPhotos({
    required String studentId,
    String? authToken,
    bool deleteRemote = false,
  }) async {
    try {
      final photos = await getStudentPhotos(studentId);

      for (final photo in photos) {
        await deletePhoto(
          photoId: photo.id,
          authToken: authToken,
          deleteRemote: deleteRemote,
        );
      }

      // Clean local storage
      await _photoStorage.deleteAllStudentPhotos(studentId);

      return true;
    } catch (e) {
      print('$_log Error deleting all student photos: $e');
      return false;
    }
  }

  // ==================== DATABASE OPERATIONS ====================

  /// Save photo to database
  /// Note: Actual implementation depends on your database_helper.dart structure
  Future<bool> _savePhotoToDatabase(Photo photo) async {
    try {
      // This is a placeholder - implement in database_helper.dart
      // final db = await _dbHelper.database;
      // await db.insert(_photosTable, photo.toJson());

      print('$_log Photo saved to database: ${photo.id}');
      return true;
    } catch (e) {
      print('$_log Error saving photo to database: $e');
      return false;
    }
  }

  /// Get photo from database
  Future<Photo?> _getPhotoFromDatabase(String photoId) async {
    try {
      // This is a placeholder - implement in database_helper.dart
      // final db = await _dbHelper.database;
      // final result = await db.query(_photosTable, where: 'id = ?', whereArgs: [photoId]);
      // if (result.isNotEmpty) {
      //   return Photo.fromJson(result.first);
      // }

      return null;
    } catch (e) {
      print('$_log Error getting photo from database: $e');
      return null;
    }
  }

  /// Get all photos for student from database
  Future<List<Photo>> _getPhotosFromDatabase(String studentId) async {
    try {
      // This is a placeholder - implement in database_helper.dart
      // final db = await _dbHelper.database;
      // final result = await db.query(
      //   _photosTable,
      //   where: 'student_id = ?',
      //   whereArgs: [studentId],
      //   orderBy: 'captured_at DESC',
      // );
      // return result.map((p) => Photo.fromJson(p)).toList();

      return [];
    } catch (e) {
      print('$_log Error getting photos from database: $e');
      return [];
    }
  }

  /// Update photo in database
  Future<bool> _updatePhotoInDatabase(Photo photo) async {
    try {
      // This is a placeholder - implement in database_helper.dart
      // final db = await _dbHelper.database;
      // await db.update(
      //   _photosTable,
      //   photo.toJson(),
      //   where: 'id = ?',
      //   whereArgs: [photo.id],
      // );

      print('$_log Photo updated in database: ${photo.id}');
      return true;
    } catch (e) {
      print('$_log Error updating photo in database: $e');
      return false;
    }
  }

  /// Delete photo from database
  Future<bool> _deletePhotoFromDatabase(String photoId) async {
    try {
      // This is a placeholder - implement in database_helper.dart
      // final db = await _dbHelper.database;
      // await db.delete(_photosTable, where: 'id = ?', whereArgs: [photoId]);

      print('$_log Photo deleted from database: $photoId');
      return true;
    } catch (e) {
      print('$_log Error deleting photo from database: $e');
      return false;
    }
  }
}
