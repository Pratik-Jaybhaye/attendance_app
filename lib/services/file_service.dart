/// FileService handles file-related API operations
/// Provides methods for uploading and managing files
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FileService {
  // API Base URL
  static const String apiBaseUrl = 'https://attendanceapi.acculekhaa.com';

  // ==================== FILE OPERATIONS ====================

  /// Upload file to server
  /// API Endpoint: POST /api/File/UploadFile
  /// Parameters:
  ///   - filePath: Path to file to upload (required)
  ///   - fileCategory: Category of file like 'document', 'image', 'video' (optional)
  ///   - description: Description of file (optional)
  /// Returns: Map with upload response containing fileId, url, etc.
  static Future<Map<String, dynamic>?> uploadFile({
    required String filePath,
    String? fileCategory,
    String? description,
    String? token,
  }) async {
    try {
      print('FileService: Uploading file - $filePath');

      if (!File(filePath).existsSync()) {
        print('FileService: File not found - $filePath');
        return null;
      }

      final file = File(filePath);
      final fileName = file.path.split('/').last;
      final fileSize = file.lengthSync();

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/api/File/UploadFile'),
      );

      // Add file to request
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      // Add optional fields
      request.fields['fileName'] = fileName;
      request.fields['fileSize'] = fileSize.toString();

      if (fileCategory != null) {
        request.fields['fileCategory'] = fileCategory;
      }

      if (description != null) {
        request.fields['description'] = description;
      }

      // Add headers
      request.headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseData);
        print('FileService: File uploaded successfully - $fileName');

        // Extract success status
        final isSuccess = data['success'] ?? data['isSuccess'] ?? true;

        if (isSuccess) {
          // Return file information from response
          return {
            'success': true,
            'fileId': data['fileId'] ?? data['id'],
            'fileName': data['fileName'] ?? fileName,
            'url': data['url'] ?? data['filePath'],
            'fileSize': fileSize,
            'uploadedAt': DateTime.now().toIso8601String(),
            ...data, // Include all response data
          };
        }
      } else {
        print('FileService: Error uploading file - ${response.statusCode}');
        print('FileService: Response - $responseData');
        return null;
      }
    } catch (e) {
      print('FileService: Exception uploading file - $e');
      return null;
    }

    return null;
  }

  /// Upload multiple files
  /// Parameters:
  ///   - filePaths: List of file paths to upload
  ///   - fileCategory: Category for all files (optional)
  /// Returns: List of upload responses
  static Future<List<Map<String, dynamic>>> uploadMultipleFiles({
    required List<String> filePaths,
    String? fileCategory,
    String? token,
  }) async {
    try {
      print('FileService: Uploading ${filePaths.length} files');

      final results = <Map<String, dynamic>>[];

      for (final filePath in filePaths) {
        final result = await uploadFile(
          filePath: filePath,
          fileCategory: fileCategory,
          token: token,
        );

        if (result != null) {
          results.add(result);
        }
      }

      print('FileService: Successfully uploaded ${results.length} files');
      return results;
    } catch (e) {
      print('FileService: Exception uploading multiple files - $e');
      return [];
    }
  }

  /// Validate file before upload
  /// Checks file size and format
  static Future<Map<String, dynamic>> validateFile({
    required String filePath,
    int maxSizeInMB = 50,
    List<String>? allowedExtensions,
  }) async {
    try {
      if (!File(filePath).existsSync()) {
        return {'isValid': false, 'error': 'File not found'};
      }

      final file = File(filePath);
      final fileSize = file.lengthSync();
      final maxSizeInBytes = maxSizeInMB * 1024 * 1024;

      // Check file size
      if (fileSize > maxSizeInBytes) {
        return {
          'isValid': false,
          'error': 'File size exceeds maximum allowed size ($maxSizeInMB MB)',
          'fileSize': fileSize,
        };
      }

      // Check file extension if specified
      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        final fileName = file.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();

        if (!allowedExtensions.contains(fileExtension)) {
          return {
            'isValid': false,
            'error':
                'File type not allowed. Allowed types: ${allowedExtensions.join(", ")}',
            'fileExtension': fileExtension,
          };
        }
      }

      return {
        'isValid': true,
        'fileName': file.path.split('/').last,
        'fileSize': fileSize,
      };
    } catch (e) {
      print('FileService: Exception validating file - $e');
      return {'isValid': false, 'error': 'Error validating file: $e'};
    }
  }

  /// Get file information
  /// Useful for checking file details before/after upload
  static Map<String, dynamic> getFileInfo(String filePath) {
    try {
      final file = File(filePath);

      if (!file.existsSync()) {
        return {'exists': false};
      }

      final stats = file.statSync();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last;

      return {
        'exists': true,
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': stats.size,
        'fileExtension': fileExtension,
        'lastModified': stats.modified.toIso8601String(),
        'fileSizeInMB': (stats.size / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      print('FileService: Exception getting file info - $e');
      return {'exists': false, 'error': 'Error getting file info: $e'};
    }
  }
}
