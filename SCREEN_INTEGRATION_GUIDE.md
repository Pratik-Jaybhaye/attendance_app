# Screen Integration Guide - Using Photo Services

This guide shows how to integrate the new photo storage and embedding services into the Flutter screens.

## 1. Photo Picker Screen (`photo_picker_screen.dart`)

After user selects/captures a photo, save it using PhotoManagementService:

```dart
import 'package:attendance_app/services/photo_management_service.dart';

Future<void> _takePhotoWithCamera() async {
  try {
    // ... existing permission and camera code ...
    
    final XFile? photoFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );

    if (photoFile != null) {
      print('Photo taken: ${photoFile.path}');
      
      // NEW: Save photo using PhotoManagementService
      final photoMgmt = PhotoManagementService();
      final studentId = 'CURRENT_STUDENT_ID'; // Get from context
      
      final savedPhoto = await photoMgmt.saveCapturedPhoto(
        sourceImagePath: photoFile.path,
        studentId: studentId,
        metadata: {
          'source': 'camera',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (savedPhoto != null) {
        print('Photo saved with ID: ${savedPhoto.id}');
        // Return both the photo object and path
        if (mounted) {
          Navigator.of(context).pop({
            'photoPath': savedPhoto.localPath,
            'photoId': savedPhoto.id,
            'photo': savedPhoto,
          });
        }
      } else {
        print('Failed to save photo');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save photo')),
          );
        }
      }
    }
  } catch (e) {
    print('Error taking photo: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

## 2. Take Attendance Screen (`take_attendance_screen.dart`)

Use PhotoManagementService to verify faces:

```dart
import 'package:attendance_app/services/photo_management_service.dart';
import 'package:attendance_app/models/photo.dart';

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final PhotoManagementService _photoMgmt = PhotoManagementService();
  
  /// Verify a student's face during attendance
  Future<void> _verifyStudentFace(String studentId) async {
    try {
      // Capture/get the photo
      final photoPath = await _captureOrSelectPhoto();
      if (photoPath == null) {
        print('No photo selected');
        return;
      }

      print('Verifying face for student: $studentId');
      
      // Get auth token (from shared preferences or auth service)
      final authToken = 'USER_AUTH_TOKEN'; // Get from auth service
      
      // Verify face
      final result = await _photoMgmt.verifyStudentFace(
        studentId: studentId,
        photoPath: photoPath,
        authToken: authToken,
        threshold: 0.6,
      );

      if (result == null) {
        print('Verification failed - no response from backend');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face verification failed. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Handle verification result
      if (result.isVerified) {
        print('✓ Face verified! Match score: ${result.matchScore}');
        setState(() {
          _presentStudents[selectedClass.id]?.add(studentId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Student verified! (Match: ${(result.matchScore * 100).toStringAsFixed(1)}%)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('✗ Face not verified. Match score: ${result.matchScore}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Face not recognized. Match: ${(result.matchScore * 100).toStringAsFixed(1)}%',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error verifying face: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Alternative: Match face against all students (for unknown faces)
  Future<void> _identifyStudent(String photoPath) async {
    try {
      final authToken = 'USER_AUTH_TOKEN';
      
      final matches = await _photoMgmt._embeddingService.matchFace(
        photoPath: photoPath,
        authToken: authToken,
        limit: 5,
        threshold: 0.5,
      );

      if (matches.isEmpty) {
        print('No matching students found');
        // Show dialog asking to manually select student
        return;
      }

      // Show top matches to user
      final studentId = matches[0]['student_id'] as String;
      final matchScore = (matches[0]['score'] as num).toDouble();
      
      if (matchScore >= 0.65) {
        print('High confidence match: $studentId (${matchScore * 100}%)');
        // Auto-mark as present
        setState(() {
          _presentStudents[selectedClass.id]?.add(studentId);
        });
      } else {
        // Show dialog with top matches for user confirmation
        _showMatchesDialog(matches);
      }
    } catch (e) {
      print('Error identifying student: $e');
    }
  }
}
```

## 3. Upload Multiple Photos Screen (`upload_multiple_photos_screen.dart`)

Batch upload and request embeddings:

```dart
import 'package:attendance_app/services/photo_management_service.dart';

class _UploadMultiplePhotosScreenState extends State<UploadMultiplePhotosScreen> {
  final PhotoManagementService _photoMgmt = PhotoManagementService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  int _uploadProgress = 0;
  int _totalPhotos = 0;
  String _statusMessage = '';
  List<String> _completedPhotoIds = [];
  List<String> _failedPhotoIds = [];

  /// Batch upload all pending photos
  Future<void> _batchUploadPhotos() async {
    try {
      setState(() {
        _statusMessage = 'Preparing photos for upload...';
      });

      final authToken = 'USER_AUTH_TOKEN';
      
      // Get pending upload photos from database
      final pendingPhotos = await _dbHelper.getPendingUploadPhotos();
      if (pendingPhotos.isEmpty) {
        setState(() {
          _statusMessage = 'No photos to upload';
        });
        return;
      }

      setState(() {
        _totalPhotos = pendingPhotos.length;
        _uploadProgress = 0;
        _completedPhotoIds.clear();
        _failedPhotoIds.clear();
      });

      // Extract photo IDs
      final photoIds = pendingPhotos
          .map((p) => p[DatabaseHelper.columnPhotoId] as String)
          .toList();

      // Batch upload with progress tracking
      final uploaded = await _photoMgmt.batchUploadPhotos(
        photoIds: photoIds,
        authToken: authToken,
        onProgress: (uploadedCount, total) {
          setState(() {
            _uploadProgress = uploadedCount;
            _statusMessage = 'Uploaded $uploadedCount/$total photos';
          });
        },
      );

      // Track results
      _completedPhotoIds = uploaded.map((p) => p.id).toList();
      _failedPhotoIds = photoIds
          .where((id) => !_completedPhotoIds.contains(id))
          .toList();

      setState(() {
        _statusMessage = 
            'Upload complete! ${_completedPhotoIds.length} succeeded, '
            '${_failedPhotoIds.length} failed';
      });

      // If upload successful, request embedding processing
      if (_completedPhotoIds.isNotEmpty) {
        _requestEmbeddingProcessing(_completedPhotoIds);
      }
    } catch (e) {
      print('Error in batch upload: $e');
      setState(() {
        _statusMessage = 'Upload failed: $e';
      });
    }
  }

  /// Request embedding processing for uploaded photos
  Future<void> _requestEmbeddingProcessing(
    List<String> photoIds,
  ) async {
    try {
      setState(() {
        _statusMessage = 'Requesting embedding processing...';
      });

      final authToken = 'USER_AUTH_TOKEN';
      int processed = 0;

      for (final photoId in photoIds) {
        final jobId = await _photoMgmt.requestEmbeddingProcessing(
          photoId: photoId,
          authToken: authToken,
          priority: 'normal',
        );

        if (jobId != null) {
          print('Processing job created: $jobId');
          processed++;
          
          // Poll job status
          _pollJobStatus(jobId, authToken);
        }
      }

      setState(() {
        _statusMessage = 
            'Embedding processing requested for $processed photos';
      });
    } catch (e) {
      print('Error requesting embedding: $e');
      setState(() {
        _statusMessage = 'Error requesting embeddings: $e';
      });
    }
  }

  /// Poll job status periodically
  void _pollJobStatus(String jobId, String authToken) async {
    int pollingCount = 0;
    const maxPolls = 120; // 10 minutes with 5s intervals
    const pollInterval = Duration(seconds: 5);

    while (pollingCount < maxPolls) {
      try {
        final status = await _photoMgmt.checkEmbeddingStatus(
          jobId: jobId,
          authToken: authToken,
        );

        if (status != null) {
          final jobStatus = status['status'] as String?;
          final progress = status['progress'] as int? ?? 0;

          print('Job $jobId status: $jobStatus ($progress%)');

          if (jobStatus == 'completed') {
            setState(() {
              _statusMessage = 'Embedding processing completed!';
            });
            break;
          } else if (jobStatus == 'failed') {
            setState(() {
              _statusMessage = 'Embedding processing failed';
            });
            break;
          }
        }
      } catch (e) {
        print('Error polling job status: $e');
      }

      pollingCount++;
      await Future.delayed(pollInterval);
    }

    if (pollingCount >= maxPolls) {
      print('Job polling timeout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Photos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_totalPhotos > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress / _totalPhotos,
                      minHeight: 10,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_uploadProgress / $_totalPhotos',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _batchUploadPhotos,
              child: const Text('Upload All Photos'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 4. Update Profile Photo Screen (`update_profile_photo_screen.dart`)

Save profile photo:

```dart
import 'package:attendance_app/services/photo_storage_service.dart';

class _UpdateProfilePhotoScreenState extends State<UpdateProfilePhotoScreen> {
  final PhotoStorageService _photoStorage = PhotoStorageService();

  Future<void> _saveProfilePhoto(String imageSourcePath) async {
    try {
      final userId = 'CURRENT_USER_ID'; // Get from auth service
      
      // Save profile photo (replaces old one)
      final savedPath = await _photoStorage.saveProfilePhoto(
        sourceImagePath: imageSourcePath,
        userId: userId,
      );

      if (savedPath != null) {
        print('Profile photo saved: $savedPath');
        
        // Update user profile in database
        await UserService.updateUserProfile(
          userId: userId,
          profileImagePath: savedPath,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(savedPath);
        }
      }
    } catch (e) {
      print('Error saving profile photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
```

## 5. Student Enrollment Form

Upload and enroll student with photos:

```dart
Future<void> _enrollNewStudent() async {
  try {
    // Capture multiple photos for enrollment
    final photoMgmt = PhotoManagementService();
    final authToken = 'USER_AUTH_TOKEN';
    final photoIds = <String>[];

    // Capture 3 photos from different angles
    for (int i = 0; i < 3; i++) {
      final photoPath = await _capturePhoto('Photo ${i + 1}/3');
      if (photoPath != null) {
        final photo = await photoMgmt.saveCapturedPhoto(
          sourceImagePath: photoPath,
          studentId: _newStudentId,
          metadata: {'angle': 'front', 'attempt': i + 1},
        );
        if (photo != null) {
          photoIds.add(photo.id);
        }
      }
    }

    // Upload all photos
    final uploaded = await photoMgmt.batchUploadPhotos(
      photoIds: photoIds,
      authToken: authToken,
    );

    if (uploaded.isNotEmpty) {
      // Request embedding processing
      for (final photo in uploaded) {
        await photoMgmt.requestEmbeddingProcessing(
          photoId: photo.id,
          authToken: authToken,
          priority: 'high', // High priority for new enrollment
        );
      }

      print('Student enrolled with ${uploaded.length} photos');
      _showSuccessMessage('Student enrolled successfully');
    }
  } catch (e) {
    print('Error enrolling student: $e');
    _showErrorMessage('Enrollment failed: $e');
  }
}
```

## State Management Pattern

For managing upload/processing state in your screens:

```dart
class PhotoUploadState {
  final int uploadedCount;
  final int totalCount;
  final List<String> failedPhotoIds;
  final String statusMessage;
  final bool isProcessing;

  PhotoUploadState({
    required this.uploadedCount,
    required this.totalCount,
    this.failedPhotoIds = const [],
    this.statusMessage = '',
    this.isProcessing = false,
  });

  double get progress => totalCount > 0 ? uploadedCount / totalCount : 0.0;
  bool get isComplete => uploadedCount == totalCount && !isProcessing;
  bool get hasFailed => failedPhotoIds.isNotEmpty;
}
```

## Best Practices

1. **Always use auth tokens** from your authentication service
2. **Show progress feedback** during uploads and processing
3. **Handle errors gracefully** - network issues are common
4. **Implement retry logic** for failed uploads
5. **Cache photo IDs** locally before batch operations
6. **Clean up old photos** periodically to save storage
7. **Use loading indicators** while waiting for backend processing
8. **Provide user feedback** on embedding processing status

## Error Handling Tree

```
Upload Error
├── Network Error → Show retry option
├── File Not Found → Clean from DB
├── Unauthorized → Re-authenticate
└── Server Error → Show error message

Processing Error
├── Job Not Found → Check polling timeout
├── Processing Failed → Show error details
└── Timeout → Let user check status later

Verification Error
├── No Embeddings → Show enrollment required message
├── Face Not Detected → Show capture again message
└── Match Too Low → Show threshold not met message
```
