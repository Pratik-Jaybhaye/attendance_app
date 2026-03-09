# Photo Storage & Embedding Architecture Implementation Guide

## Architecture Overview

This document describes the implementation of student photo storage and face embedding management for the Attendance App according to the following architecture decision:

```
Student photos → Stored LOCALLY on device as photo files
                ↓
        SQLite Database → Stores ONLY references/paths to photos
                ↓
        Backend Server → Handles face embeddings generation, storage, and verification
                ↓
        Flutter App → Captures, stores locally, uploads when needed, displays results
```

## Components

### 1. **Photo Storage Service** (`photo_storage_service.dart`)
Manages local file storage of student photos on the device.

**Key Features:**
- Save student photos with unique identifiers
- Organize photos in app-specific directories
- Retrieve photo file references
- Delete photos when no longer needed
- Monitor storage usage

**Directory Structure:**
```
App Documents/
├── student_photos/     # Individual student enrollment photos
│   ├── STU001_0_uuid.jpg
│   ├── STU001_1_uuid.jpg
│   └── STU002_0_uuid.jpg
└── profile_photos/     # User profile photos
    ├── USR001_profile.jpg
    └── USR002_profile.jpg
```

### 2. **Photo Model** (`models/photo.dart`)
Represents photo data with metadata.

**Photo Class Fields:**
```dart
- id: String                          // Unique photo ID
- studentId: String                   // Student who owns the photo
- localPath: String                   // Local storage path
- cloudPath: String?                  // Backend storage path (after upload)
- uploadId: String?                   // ID from backend upload
- capturedAt: DateTime                // When photo was taken
- uploadedAt: DateTime?               // When uploaded to backend
- photoQuality: String?               // 'good', 'fair', 'poor'
- faceDetectionScore: int?            // 0-100 confidence
- isLiveImage: bool?                  // Anti-spoofing verification
- embeddingId: String?                // Generated face embedding ID
- isProcessed: bool                   // Whether embeddings were generated
- processingStatus: String            // 'pending', 'processing', 'completed', 'failed'
```

### 3. **Photo Upload Service** (`photo_upload_service.dart`)
Handles uploading photos to the backend server.

**Key Methods:**
```dart
// Upload single photo
uploadStudentPhoto({
  required String photoPath,
  required String studentId,
  required String authToken,
  Map<String, dynamic>? metadata,
})

// Batch upload multiple photos
batchUploadPhotos({
  required List<String> photoPaths,
  required List<String> studentIds,
  required String authToken,
})

// Request backend to process embeddings
requestEmbeddingProcessing({
  required List<String> uploadIds,
  required String authToken,
})

// Get upload status
getUploadStatus({
  required String uploadId,
  required String authToken,
})

// Delete uploaded photo
deleteUploadedPhoto({
  required String uploadId,
  required String authToken,
})
```

### 4. **Embedding Request Service** (`embedding_request_service.dart`)
Manages face embedding generation and verification requests to the backend.

**Backend Responsibilities:**
- Extract faces from photos (face detection)
- Generate 128-dimensional vectors using FaceNet model
- Store embeddings in backend database
- Perform face matching during attendance verification

**Key Methods:**
```dart
// Request face embedding generation
requestEmbeddingGeneration({
  required List<String> uploadIds,
  required String authToken,
  String priority = 'normal',
})

// Verify student face during attendance
verifyFace({
  required String studentId,
  required String capturedPhotoPath,
  required String authToken,
  double threshold = 0.6,
})

// Get embeddings for a student
getStudentEmbeddings({
  required String studentId,
  required String authToken,
})

// Match face against all enrolled students (1-to-many)
matchFace({
  required String photoPath,
  required String authToken,
})

// Check processing job status
getJobStatus({
  required String jobId,
  required String authToken,
})
```

### 5. **Photo Management Service** (`photo_management_service.dart`)
High-level orchestration service that coordinates all photo operations.

**Workflow Orchestration:**
1. **Capture & Store** → Save photo locally + Create DB record
2. **Upload** → Send to backend + Update with upload ID
3. **Process** → Request embeddings from backend
4. **Verify** → Compare faces during attendance

**Key Methods:**
```dart
// Save captured photo locally and to database
saveCapturedPhoto({
  required String sourceImagePath,
  required String studentId,
  Map<String, dynamic>? metadata,
})

// Upload photo to backend
uploadPhoto({
  required String photoId,
  required String authToken,
})

// Request embedding processing
requestEmbeddingProcessing({
  required String photoId,
  required String authToken,
})

// Verify student face during attendance
verifyStudentFace({
  required String studentId,
  required String photoPath,
  required String authToken,
})

// Delete photo (local and remote)
deletePhoto({
  required String photoId,
  String? authToken,
  bool deleteRemote = true,
})
```

### 6. **Database Extensions** (`database_helper.dart`)
Enhanced SQLite database schema with photos table.

**Photos Table Schema:**
```sql
CREATE TABLE photos (
  photo_id TEXT PRIMARY KEY,
  student_id TEXT NOT NULL,           -- Foreign key to students
  local_path TEXT NOT NULL,           -- Path on device
  cloud_path TEXT,                    -- Path in backend storage
  upload_id TEXT UNIQUE,              -- Upload ID from backend
  captured_at TEXT NOT NULL,          -- Capture timestamp
  uploaded_at TEXT,                   -- Upload timestamp
  photo_quality TEXT,                 -- 'good', 'fair', 'poor'
  face_detection_score INTEGER,       -- 0-100
  is_live_image INTEGER,              -- Anti-spoofing: 0 or 1
  embedding_id TEXT,                  -- Backend embedding ID
  is_processed INTEGER DEFAULT 0,     -- Embedding processing status
  processing_status TEXT DEFAULT 'pending',  -- 'pending', 'processing', 'completed', 'failed'
  created_at TEXT NOT NULL,
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Database Methods:**
```dart
// Save photo record
savePhoto({
  required String photoId,
  required String studentId,
  required String localPath,
  ...
})

// Get photos
getPhotoById(String photoId)
getStudentPhotos(String studentId)
getLatestStudentPhoto(String studentId)
getPendingUploadPhotos()
getPendingEmbeddingPhotos()

// Update photo
updatePhoto({
  required String photoId,
  ...
})

// Delete photo
deletePhoto(String photoId)
deleteAllStudentPhotos(String studentId)
```

## Data Flow

### 1. Photo Capture and Storage Flow
```
User captures photo (camera/gallery)
    ↓
PhotoStorageService.saveStudentPhoto()
    ↓
Returns: localPath
    ↓
PhotoManagementService.saveCapturedPhoto()
    ↓
DatabaseHelper.savePhoto() [Create DB record]
    ↓
Returns: Photo object with id, studentId, localPath
```

### 2. Photo Upload Flow
```
Photo stored locally with DB record
    ↓
PhotoManagementService.uploadPhoto(photoId, authToken)
    ↓
PhotoUploadService.uploadStudentPhoto(localPath, studentId)
    ↓
Backend receives photo → Stores in cloud
    ↓
Backend returns: {upload_id, cloud_path}
    ↓
DatabaseHelper.updatePhoto() [Update with uploadId, cloudPath, uploadedAt]
    ↓
Returns: Updated Photo object
```

### 3. Embedding Processing Flow
```
Photo uploaded to backend with uploadId
    ↓
PhotoManagementService.requestEmbeddingProcessing(photoId, authToken)
    ↓
EmbeddingRequestService.requestEmbeddingGeneration([uploadId])
    ↓
Backend async process:
   - Extract face from photo
   - Generate 128-dim FaceNet embedding
   - Store in embeddings database
   - Return: {job_id}
    ↓
App polls getJobStatus(jobId) periodically
    ↓
When complete, Backend returns:
   - embedding_id
   - face_detection_score (0-100)
   - photo_quality ('good'/'fair'/'poor')
   - is_live_image (anti-spoofing result)
    ↓
DatabaseHelper.updatePhoto() [Update with embeddingId, processingStatus=completed]
```

### 4. Student Face Verification Flow (During Attendance)
```
Teacher captures/selects student photo
    ↓
PhotoManagementService.verifyStudentFace(studentId, photoPath, authToken)
    ↓
EmbeddingRequestService.verifyFace()
    ↓
Backend process:
   - Extract face from captured photo
   - Generate embedding for captured face
   - Compare with all enrolled embeddings for student
   - Calculate similarity scores
   - Return: {verification_id, match_score, verification_status}
    ↓
Returns: FaceVerificationResult
    ↓
App checks: if match_score >= threshold → Mark student PRESENT
```

## Implementation Checklist

### ✅ Completed
- [x] PhotoStorageService - Local file management
- [x] PhotoUploadService - Backend upload API
- [x] EmbeddingRequestService - Embedding API calls
- [x] PhotoModel - Photo data models
- [x] PhotoManagementService - Orchestration service
- [x] Database extensions - Photos table and CRUD methods

### 📝 TODO - Backend API Endpoints
Configure these endpoints in PhotoUploadService and EmbeddingRequestService:

**Photo Upload Endpoints:**
```
POST   /api/v1/photos/upload              - Upload single photo
POST   /api/v1/photos/batch-upload        - Upload multiple photos
GET    /api/v1/photos/upload/{uploadId}   - Get upload status
DELETE /api/v1/photos/upload/{uploadId}   - Delete uploaded photo
```

**Embedding Endpoints:**
```
POST   /api/v1/embeddings/generate        - Request face embedding generation
POST   /api/v1/embeddings/verify           - Verify face (1-to-1 matching)
POST   /api/v1/embeddings/match            - Match face (1-to-many)
GET    /api/v1/embeddings/student/{id}    - Get student embeddings
GET    /api/v1/embeddings/jobs/{jobId}    - Check job status
POST   /api/v1/embeddings/reenroll        - Re-enroll with new embeddings
```

### 📝 TODO - UI Integration
Update screens to use new services:

```dart
// Photo capture and storage
1. photo_picker_screen.dart
   → Save photo using PhotoManagementService
2. take_attendance_screen.dart
   → Verify face using PhotoManagementService
   → Display verification results
3. upload_multiple_photos_screen.dart
   → Batch upload using PhotoManagementService
   → Show progress and status
4. update_profile_photo_screen.dart
   → Save profile photo using PhotoStorageService
```

### 📝 TODO - Configuration
Set base URLs in services:

```dart
// During app initialization (main.dart or splash screen)
PhotoUploadService.setBaseUrl('https://your-backend-api.com');
EmbeddingRequestService.setBaseUrl('https://your-backend-api.com');
```

### 📝 TODO - Database Optimization
```dart
// Create indices for better query performance
await db.execute('CREATE INDEX IF NOT EXISTS idx_photo_student ON photos(student_id)');
await db.execute('CREATE INDEX IF NOT EXISTS idx_photo_status ON photos(processing_status)');
await db.execute('CREATE INDEX IF NOT EXISTS idx_photo_upload_id ON photos(upload_id)');
```

## Usage Examples

### Save a Captured Photo
```dart
final photoMgmt = PhotoManagementService();
final photo = await photoMgmt.saveCapturedPhoto(
  sourceImagePath: '/tmp/photo.jpg',
  studentId: 'STU001',
  metadata: {'name': 'John Doe'},
);
// Returns: Photo with id, localPath set
```

### Upload Photos and Request Embeddings
```dart
// Upload single photo
final uploaded = await photoMgmt.uploadPhoto(
  photoId: photo.id,
  authToken: token,
);

// Request embedding processing
final jobId = await photoMgmt.requestEmbeddingProcessing(
  photoId: uploaded.id,
  authToken: token,
);

// Poll job status
bool processing = true;
while (processing) {
  final status = await photoMgmt.checkEmbeddingStatus(jobId, token);
  if (status?['status'] == 'completed') {
    processing = false;
  }
  await Future.delayed(Duration(seconds: 5));
}
```

### Verify Student Face
```dart
final result = await photoMgmt.verifyStudentFace(
  studentId: 'STU001',
  photoPath: '/path/to/captured.jpg',
  authToken: token,
  threshold: 0.6,
);

if (result?.isVerified ?? false) {
  print('✓ Face verified! Match score: ${result?.matchScore}');
  // Mark student as present
} else {
  print('✗ Face not verified');
  // Prompt for manual verification
}
```

### Batch Operations
```dart
// Get all pending upload photos
final db = DatabaseHelper();
final pendingPhotos = await db.getPendingUploadPhotos();

// Batch upload and track progress
final uploaded = await photoMgmt.batchUploadPhotos(
  photoIds: pendingPhotos.map((p) => p[columnPhotoId]).toList(),
  authToken: token,
  onProgress: (uploaded, total) {
    print('Uploaded $uploaded/$total');
  },
);
```

## Error Handling

### Common Issues and Solutions

**Issue: Photo file not found**
```dart
// Check if photo exists before upload
final exists = await photoStorage.photoExists(photoPath);
if (!exists) {
  print('Photo file has been deleted');
  // Remove from database
  await db.deletePhoto(photoId);
}
```

**Issue: Upload fails due to network**
```dart
// Implement retry logic
int retries = 0;
const maxRetries = 3;

while (retries < maxRetries) {
  try {
    final result = await photoMgmt.uploadPhoto(
      photoId: photoId,
      authToken: token,
    );
    if (result != null) break;
  } catch (e) {
    retries++;
    if (retries >= maxRetries) {
      print('Upload failed after $maxRetries retries');
    }
  }
}
```

**Issue: Embedding processing timeout**
```dart
// Set reasonable timeout for polling
final maxAttempts = 60; // 5 minutes with 5s intervals
int attempts = 0;

while (attempts < maxAttempts) {
  final status = await photoMgmt.checkEmbeddingStatus(jobId, token);
  if (status != null && 
      (status['status'] == 'completed' || status['status'] == 'failed')) {
    break;
  }
  attempts++;
  await Future.delayed(Duration(seconds: 5));
}
```

## Storage Management

### Monitor Storage Usage
```dart
final photoStorage = PhotoStorageService();
final totalBytes = await photoStorage.getStorageUsage();
final sizeStr = PhotoStorageService.formatStorageSize(totalBytes);
print('Photos storage: $sizeStr');

// Delete old photos if storage exceeds threshold
if (totalBytes > 500 * 1024 * 1024) { // 500 MB
  // Delete photos older than 30 days
  // Only locally, backend keeps embeddings
}
```

### Clean Up
```dart
// Delete single photo (local and remote)
await photoMgmt.deletePhoto(
  photoId: photoId,
  authToken: token,
  deleteRemote: true,
);

// Delete all student photos (except embeddings on backend)
await photoMgmt.deleteAllStudentPhotos(
  studentId: studentId,
  authToken: token,
  deleteRemote: false, // Keep embeddings on backend
);
```

## Security Considerations

1. **Local Storage**: Photos stored in app-specific directory (not accessible by other apps)
2. **Upload**: Use HTTPS with proper certificate validation
3. **Authentication**: Always use valid auth tokens
4. **Database**: Photos table has foreign key constraints
5. **Cleanup**: Properly delete photos when no longer needed
6. **Anti-Spoofing**: Backend verifies liveness for uploaded photos

## Performance Notes

1. **Local Storage**: Operations are fast (I/O bound)
2. **Network Upload**: Use batch uploads for multiple photos
3. **Embedding Processing**: Async backend processing - poll status periodically
4. **Database Queries**: Use indices for student_id, upload_id, processing_status
5. **Memory**: Load photos from disk on demand, don't cache in memory

## Testing Checklist

```
[ ] Save photo locally
[ ] Verify photo file exists in correct directory
[ ] Save photo record to database
[ ] Retrieve photo from database
[ ] Upload photo to backend (mock API)
[ ] Update photo with upload ID
[ ] Request embedding generation
[ ] Poll job status
[ ] Verify face with mock embeddings
[ ] Delete photo locally and remotely
[ ] Batch operations
[ ] Error handling and retries
[ ] Storage usage calculation
```
