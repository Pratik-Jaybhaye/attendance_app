import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Photo Storage Service
/// Manages local storage of student photos on the device
///
/// Features:
/// - Save photos with unique identifiers
/// - Organize photos in app-specific directories
/// - Retrieve photo file references
/// - Delete photos when no longer needed
/// - Generate consistent photo paths
///
/// Architecture:
/// Photos are stored locally on device, database stores only the paths/references
class PhotoStorageService {
  static final PhotoStorageService _instance = PhotoStorageService._internal();

  static final String _photosDirectory = 'student_photos';
  static final String _profilePhotosDirectory = 'profile_photos';

  PhotoStorageService._internal();

  factory PhotoStorageService() {
    return _instance;
  }

  /// Get the app documents directory
  Future<String> _getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get the student photos directory path
  /// Creates directory if it doesn't exist
  Future<String> _getStudentPhotosPath() async {
    final docPath = await _getAppDocumentsPath();
    final studentPhotosPath = path.join(docPath, _photosDirectory);

    final dir = Directory(studentPhotosPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print(
        '[PhotoStorage] Student photos directory created: $studentPhotosPath',
      );
    }

    return studentPhotosPath;
  }

  /// Get the profile photos directory path
  /// Creates directory if it doesn't exist
  Future<String> _getProfilePhotosPath() async {
    final docPath = await _getAppDocumentsPath();
    final profilePhotosPath = path.join(docPath, _profilePhotosDirectory);

    final dir = Directory(profilePhotosPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print(
        '[PhotoStorage] Profile photos directory created: $profilePhotosPath',
      );
    }

    return profilePhotosPath;
  }

  /// Save a student photo from source file
  ///
  /// Parameters:
  ///   - sourceImagePath: Path to the original photo file
  ///   - studentId: ID of the student
  ///   - photoIndex: Optional index for multiple photos per student
  ///
  /// Returns: Path to stored photo file, or null if failed
  ///
  /// Example:
  /// ```dart
  /// final photoService = PhotoStorageService();
  /// final photoPath = await photoService.saveStudentPhoto(
  ///   sourceImagePath: '/tmp/IMG_123.jpg',
  ///   studentId: 'STU001',
  /// );
  /// // Returns: /data/data/app/documents/student_photos/STU001_UUID.jpg
  /// ```
  Future<String?> saveStudentPhoto({
    required String sourceImagePath,
    required String studentId,
    int photoIndex = 0,
  }) async {
    try {
      final studentPhotosPath = await _getStudentPhotosPath();

      // Generate unique filename using student ID, index, and UUID
      final uuid = const Uuid().v4().substring(0, 8);
      final extension = path.extension(sourceImagePath);
      final filename = '${studentId}_${photoIndex}_$uuid$extension';
      final destinationPath = path.join(studentPhotosPath, filename);

      // Copy file from source to destination
      final sourceFile = File(sourceImagePath);
      if (!await sourceFile.exists()) {
        print('[PhotoStorage] Source file does not exist: $sourceImagePath');
        return null;
      }

      await sourceFile.copy(destinationPath);
      print('[PhotoStorage] Student photo saved: $filename');

      return destinationPath;
    } catch (e) {
      print('[PhotoStorage] Error saving student photo: $e');
      return null;
    }
  }

  /// Save a profile photo from source file
  ///
  /// Parameters:
  ///   - sourceImagePath: Path to the original photo file
  ///   - userId: ID of the user
  ///
  /// Returns: Path to stored photo file, or null if failed
  Future<String?> saveProfilePhoto({
    required String sourceImagePath,
    required String userId,
  }) async {
    try {
      final profilePhotosPath = await _getProfilePhotosPath();

      // Generate filename using user ID
      // Overwrite existing profile photo for the same user
      final extension = path.extension(sourceImagePath);
      final filename = '${userId}_profile$extension';
      final destinationPath = path.join(profilePhotosPath, filename);

      // Copy file from source to destination
      final sourceFile = File(sourceImagePath);
      if (!await sourceFile.exists()) {
        print('[PhotoStorage] Source file does not exist: $sourceImagePath');
        return null;
      }

      // Delete existing profile photo if it exists
      final existingFile = File(destinationPath);
      if (await existingFile.exists()) {
        await existingFile.delete();
        print('[PhotoStorage] Old profile photo deleted: $filename');
      }

      await sourceFile.copy(destinationPath);
      print('[PhotoStorage] Profile photo saved: $filename');

      return destinationPath;
    } catch (e) {
      print('[PhotoStorage] Error saving profile photo: $e');
      return null;
    }
  }

  /// Get profile photo path for a user
  Future<String?> getProfilePhotoPath(String userId) async {
    try {
      final profilePhotosPath = await _getProfilePhotosPath();

      // Check for common image extensions
      final extensions = ['.jpg', '.jpeg', '.png', '.webp'];

      for (final ext in extensions) {
        final photoPath = path.join(profilePhotosPath, '${userId}_profile$ext');
        final file = File(photoPath);

        if (await file.exists()) {
          return photoPath;
        }
      }

      return null; // Photo not found
    } catch (e) {
      print('[PhotoStorage] Error getting profile photo path: $e');
      return null;
    }
  }

  /// Get all photos for a student
  /// Returns list of photo paths
  Future<List<String>> getStudentPhotoPaths(String studentId) async {
    try {
      final studentPhotosPath = await _getStudentPhotosPath();
      final dir = Directory(studentPhotosPath);

      if (!await dir.exists()) {
        return [];
      }

      final photoPaths = <String>[];

      // List all files matching student ID pattern
      final files = dir.listSync();
      for (final file in files) {
        if (file is File && file.path.contains(studentId)) {
          photoPaths.add(file.path);
        }
      }

      // Sort by modification time (newest first)
      photoPaths.sort((a, b) {
        final fileA = File(a);
        final fileB = File(b);
        return fileB.statSync().modified.compareTo(fileA.statSync().modified);
      });

      return photoPaths;
    } catch (e) {
      print('[PhotoStorage] Error getting student photos: $e');
      return [];
    }
  }

  /// Delete a specific photo file
  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);

      if (!await file.exists()) {
        print('[PhotoStorage] Photo file not found: $photoPath');
        return false;
      }

      await file.delete();
      print('[PhotoStorage] Photo deleted: $photoPath');
      return true;
    } catch (e) {
      print('[PhotoStorage] Error deleting photo: $e');
      return false;
    }
  }

  /// Delete all photos for a student
  Future<bool> deleteAllStudentPhotos(String studentId) async {
    try {
      final photoPaths = await getStudentPhotoPaths(studentId);

      bool allDeleted = true;
      for (final photoPath in photoPaths) {
        final deleted = await deletePhoto(photoPath);
        if (!deleted) {
          allDeleted = false;
        }
      }

      if (allDeleted) {
        print('[PhotoStorage] All photos deleted for student: $studentId');
      }

      return allDeleted;
    } catch (e) {
      print('[PhotoStorage] Error deleting all student photos: $e');
      return false;
    }
  }

  /// Check if a photo file exists
  Future<bool> photoExists(String photoPath) async {
    try {
      final file = File(photoPath);
      return await file.exists();
    } catch (e) {
      print('[PhotoStorage] Error checking photo existence: $e');
      return false;
    }
  }

  /// Get photo file size in bytes
  Future<int?> getPhotoFileSize(String photoPath) async {
    try {
      final file = File(photoPath);

      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      return stat.size;
    } catch (e) {
      print('[PhotoStorage] Error getting photo file size: $e');
      return null;
    }
  }

  /// Get app storage directory size (in bytes)
  /// Useful for monitoring storage usage
  Future<int> getStorageUsage() async {
    try {
      final docPath = await _getAppDocumentsPath();
      final dir = Directory(docPath);

      int totalSize = 0;

      if (await dir.exists()) {
        final files = dir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            totalSize += stat.size;
          }
        }
      }

      return totalSize;
    } catch (e) {
      print('[PhotoStorage] Error calculating storage usage: $e');
      return 0;
    }
  }

  /// Convert storage size to human-readable format
  static String formatStorageSize(int bytes) {
    const int kb = 1024;
    const int mb = kb * 1024;

    if (bytes < kb) {
      return '$bytes B';
    } else if (bytes < mb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    }
  }

  /// Get all stored photos (for debugging/management)
  Future<List<String>> getAllStoredPhotos() async {
    try {
      final studentPhotosPath = await _getStudentPhotosPath();
      final profilePhotosPath = await _getProfilePhotosPath();

      final allPhotos = <String>[];

      // Get student photos
      final studentDir = Directory(studentPhotosPath);
      if (await studentDir.exists()) {
        final studentFiles = studentDir.listSync();
        for (final file in studentFiles) {
          if (file is File) {
            allPhotos.add(file.path);
          }
        }
      }

      // Get profile photos
      final profileDir = Directory(profilePhotosPath);
      if (await profileDir.exists()) {
        final profileFiles = profileDir.listSync();
        for (final file in profileFiles) {
          if (file is File) {
            allPhotos.add(file.path);
          }
        }
      }

      return allPhotos;
    } catch (e) {
      print('[PhotoStorage] Error getting all stored photos: $e');
      return [];
    }
  }
}
