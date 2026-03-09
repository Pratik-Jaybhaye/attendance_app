# Quick Start Guide - Photo & Embedding Services

Get up and running with the photo storage and embedding services in 5 minutes!

## 1. Add to pubspec.yaml Dependencies

Already added in this project:
```yaml
path_provider: ^2.1.0
uuid: ^4.0.0
```

Run: `flutter pub get`

## 2. Basic Usage Examples

### Save a Captured Photo
```dart
import 'package:attendance_app/services/photo_management_service.dart';

final photoMgmt = PhotoManagementService();

// After user captures/selects photo
final photo = await photoMgmt.saveCapturedPhoto(
  sourceImagePath: '/tmp/captured.jpg',
  studentId: 'STU001',
);

if (photo != null) {
  print('✓ Photo saved locally');
  print('  Path: ${photo.localPath}');
  print('  ID: ${photo.id}');
}
```

### Upload Photo to Backend
```dart
// Use saved photo ID from above
final authToken = 'get_from_auth_service';

final uploaded = await photoMgmt.uploadPhoto(
  photoId: photo.id,
  authToken: authToken,
);

if (uploaded != null) {
  print('✓ Photo uploaded to backend');
  print('  Cloud Path: ${uploaded.cloudPath}');
  print('  Upload ID: ${uploaded.uploadId}');
}
```

### Request Embedding Processing
```dart
// Use uploaded photo ID
final jobId = await photoMgmt.requestEmbeddingProcessing(
  photoId: uploaded.id,
  authToken: authToken,
);

if (jobId != null) {
  print('✓ Embedding processing started');
  print('  Job ID: $jobId');
  
  // Poll status (check periodically)
  final status = await photoMgmt.checkEmbeddingStatus(
    jobId: jobId,
    authToken: authToken,
  );
  print('  Status: ${status?['status']}');
}
```

### Verify Student Face (During Attendance)
```dart
// Get photo from student and verify
final result = await photoMgmt.verifyStudentFace(
  studentId: 'STU001',
  photoPath: '/path/to/captured_photo.jpg',
  authToken: authToken,
  threshold: 0.6,
);

if (result != null) {
  if (result.isVerified) {
    print('✓ Face verified!');
    print('  Match score: ${(result.matchScore * 100).toStringAsFixed(1)}%');
    print('  Status: ${result.verificationStatus}');
    // Mark student PRESENT
  } else {
    print('✗ Face not verified');
    print('  Match score: ${(result.matchScore * 100).toStringAsFixed(1)}%');
    // Prompt manual verification
  }
}
```

### Get All Student Photos
```dart
import 'package:attendance_app/services/database_helper.dart';

final db = DatabaseHelper();
final photos = await db.getStudentPhotos('STU001');

for (final photo in photos) {
  print('Photo: ${photo[DatabaseHelper.columnPhotoId]}');
  print('  Local Path: ${photo[DatabaseHelper.columnPhotoLocalPath]}');
  print('  Status: ${photo[DatabaseHelper.columnPhotoProcessingStatus]}');
}
```

## 3. Configure Backend URLs

In your service files, update these:

```dart
// In embedding_request_service.dart
static const String _baseUrl = 'https://your-api-server.com';

// In photo_upload_service.dart
static const String _baseUrl = 'https://your-api-server.com';
```

## 4. In Your Screen/Widget

```dart
import 'package:attendance_app/services/photo_management_service.dart';

class MyAttendanceScreen extends StatefulWidget {
  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  final PhotoManagementService _photoMgmt = PhotoManagementService();

  Future<void> markStudentPresent(String studentId, String photoPath) async {
    try {
      final authToken = 'get_from_your_auth_service';
      
      final result = await _photoMgmt.verifyStudentFace(
        studentId: studentId,
        photoPath: photoPath,
        authToken: authToken,
      );

      if (result?.isVerified ?? false) {
        setState(() {
          // Mark student present in your UI
          // _presentStudents.add(studentId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Student verified!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Face not recognized'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Attendance')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => markStudentPresent('STU001', '/path/to/photo.jpg'),
          child: const Text('Verify Student'),
        ),
      ),
    );
  }
}
```

## 5. Error Handling

```dart
// Basic error handling
Future<void> uploadWithRetry(String photoId, String token) async {
  int retries = 0;
  const maxRetries = 3;
  
  while (retries < maxRetries) {
    try {
      final result = await _photoMgmt.uploadPhoto(
        photoId: photoId,
        authToken: token,
      );
      
      if (result != null) {
        print('✓ Upload successful');
        return;
      }
    } catch (e) {
      print('Upload attempt ${retries + 1} failed: $e');
      retries++;
      
      if (retries < maxRetries) {
        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: 2 * retries));
      }
    }
  }
  
  print('✗ Upload failed after $maxRetries attempts');
}
```

## 6. Common Patterns

### Pattern 1: Capture, Save, Upload, Verify
```dart
// 1. Capture photo
final photo = await _photoMgmt.saveCapturedPhoto(
  sourceImagePath: capturedPath,
  studentId: studentId,
);

// 2. Upload to backend
final uploaded = await _photoMgmt.uploadPhoto(
  photoId: photo!.id,
  authToken: token,
);

// 3. Request embeddings
final jobId = await _photoMgmt.requestEmbeddingProcessing(
  photoId: uploaded!.id,
  authToken: token,
);

// 4. Later: Verify during attendance
final result = await _photoMgmt.verifyStudentFace(
  studentId: studentId,
  photoPath: verifyPhotoPath,
  authToken: token,
);
```

### Pattern 2: Batch Upload with Progress
```dart
int completed = 0;
int total = photoIds.length;

for (final photoId in photoIds) {
  try {
    await _photoMgmt.uploadPhoto(photoId: photoId, authToken: token);
    completed++;
    setState(() => _progress = completed / total);
  } catch (e) {
    print('Failed to upload $photoId: $e');
  }
}
```

### Pattern 3: Check Upload Status
```dart
Future<Map<String, dynamic>?> getUploadInfo(
  String uploadId,
  String token,
) async {
  final db = DatabaseHelper();
  final photo = await db.getPhotoById(uploadId);
  
  if (photo != null) {
    return {
      'status': photo[DatabaseHelper.columnPhotoProcessingStatus],
      'quality': photo[DatabaseHelper.columnPhotoQuality],
      'uploaded': photo[DatabaseHelper.columnPhotoUploadedAt] != null,
    };
  }
  return null;
}
```

## 7. Testing with Mock Backend

For local testing without a real backend:

```dart
// Mock response
Future<Map<String, dynamic>?> mockVerifyFace(
  String studentId,
  String photoPath,
) async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));
  
  // Return mock result
  return {
    'verification_id': 'verify_123',
    'student_id': studentId,
    'match_score': 0.85,
    'verification_status': 'matched',
    'verified_at': DateTime.now().toIso8601String(),
  };
}

// Use in your code
var result = await mockVerifyFace('STU001', '/path');
if (result != null) {
  print('Mock result: ${result['match_score']}');
}
```

## 8. Debug Tips

```dart
// Check storage usage
final storage = PhotoStorageService();
final bytes = await storage.getStorageUsage();
final size = PhotoStorageService.formatStorageSize(bytes);
print('Photos storage: $size');

// Check database
final db = DatabaseHelper();
final allPhotos = await db.getAllStoredPhotos();
print('Total photos in system: ${allPhotos.length}');

// Check pending operations
final pending = await db.getPendingUploadPhotos();
print('Pending uploads: ${pending.length}');

final toProcess = await db.getPendingEmbeddingPhotos();
print('Pending embeddings: ${toProcess.length}');

// List all services
print('Services initialized:');
print('✓ PhotoStorageService');
print('✓ PhotoManagementService');
print('✓ DatabaseHelper');
```

## 9. Common Issues

### Issue: File not found
```dart
// Check file exists first
final exists = await File(photoPath).exists();
if (!exists) {
  print('Photo file missing: $photoPath');
  // Clean from database
}
```

### Issue: Network error on upload
```dart
// Check internet connection first
// Use connectivity_plus package
```

### Issue: Embedding processing not starting
```dart
// Make sure:
// 1. Photo is uploaded (has uploadId)
// 2. Upload ID is valid
// 3. Auth token is valid
// 4. Backend API is accessible
```

## 10. Next Steps

1. **Configure Backend URLs** - Set your API endpoints
2. **Test Locally** - Use mock responses first
3. **Integrate Screens** - Add to your UI screens
4. **Test with Backend** - Connect to real API
5. **Deploy** - Push to production

## Reference

- Full Architecture: `PHOTO_EMBEDDING_ARCHITECTURE.md`
- Integration Guide: `SCREEN_INTEGRATION_GUIDE.md`
- Code Examples: See service files documentation

## Need Help?

Check these for detailed information:
1. Service documentation (in-code comments)
2. PHOTO_EMBEDDING_ARCHITECTURE.md - comprehensive guide
3. SCREEN_INTEGRATION_GUIDE.md - screen examples
4. Model classes - photo.dart for data structures

---

**You're all set!** Start using these services in your screens now. 🎉
