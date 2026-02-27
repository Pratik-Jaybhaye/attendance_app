# Face Embeddings - Quick Reference & Code Snippets

## Quick Start

### 1. Enroll Single Student
```dart
import 'lib/services/face_embedding_service.dart';

final faceEmbed = FaceEmbeddingService();

List<double> embedding = [...]; // 128-dimensional vector

await faceEmbed.enrollStudentFace(
  studentId: 'STU001',
  studentName: 'John Doe',
  embeddingVector: embedding,
);
```

### 2. Load Embeddings for Class
```dart
List<String> classStudents = ['STU001', 'STU002', 'STU003'];
await faceEmbed.loadStudentEmbeddings(classStudents);
```

### 3. Preload All Embeddings
```dart
await faceEmbed.preloadAllEmbeddings(); // Do this during app startup
```

### 4. Check Enrollment Status
```dart
bool isEnrolled = await faceEmbed.isStudentEnrolled('STU001');
if (isEnrolled) {
  print('Student can be recognized');
}
```

### 5. Get Statistics
```dart
final stats = await faceEmbed.getEmbeddingStats();
print('Total: ${stats['totalEmbeddings']}');
print('Students: ${stats['enrolledStudents']}');
print('Size: ${stats['databaseSize']}');
```

---

## Common Patterns

### Pattern 1: Enrollment Flow
```dart
class EnrollmentFlow {
  final _faceEmbed = FaceEmbeddingService();

  Future<void> enrollStudent(String id, String name, List<double> embedding) async {
    // Validate
    if (!FaceEmbeddingService.isValidEmbedding(embedding)) {
      print('Invalid embedding');
      return;
    }

    // Enroll
    bool success = await _faceEmbed.enrollStudentFace(
      studentId: id,
      studentName: name,
      embeddingVector: embedding,
    );

    if (success) {
      print('✓ Enrollment successful');
    }
  }
}
```

### Pattern 2: Batch Enrollment
```dart
Future<void> bulkImportStudents(List<StudentData> students) async {
  final enrollments = students
      .map((s) => {
            'studentId': s.id,
            'studentName': s.name,
            'embeddingVector': s.faceEmbedding,
          })
      .toList();

  bool success = await faceEmbed.batchEnrollStudents(enrollments);
  print(success ? 'Batch import done' : 'Import failed');
}
```

### Pattern 3: Pre-matching Setup
```dart
Future<void> prepareForAttendanceTaking(String classId) async {
  // Get students for this class
  List<String> studentIds = await _getClassStudents(classId);
  
  // Load their embeddings into memory
  await faceEmbed.loadStudentEmbeddings(studentIds);
  
  // Ready for face recognition
  print('Ready for face recognition');
}
```

### Pattern 4: Compare Two Faces
```dart
void compareFaces(List<double> face1, List<double> face2) {
  // Normalize vectors
  final norm1 = FaceEmbeddingService.normalizeEmbedding(face1);
  final norm2 = FaceEmbeddingService.normalizeEmbedding(face2);
  
  // Calculate similarity
  double similarity = FaceEmbeddingService.cosineSimilarity(norm1, norm2);
  
  // Interpret result
  if (similarity > 0.85) {
    print('Very high match (${(similarity * 100).toStringAsFixed(1)}%)');
  } else if (similarity > 0.70) {
    print('Good match (${(similarity * 100).toStringAsFixed(1)}%)');
  } else {
    print('Poor match');
  }
}
```

### Pattern 5: Re-enrollment
```dart
Future<void> updateStudentFace(String studentId, String name, 
    List<List<double>> newEmbeddings) async {
  await faceEmbed.reenrollStudent(
    studentId: studentId,
    studentName: name,
    newEmbeddings: newEmbeddings, // Multiple photos for robustness
  );
  print('Student face updated');
}
```

### Pattern 6: Student Removal
```dart
Future<void> removeStudentFromSystem(String studentId) async {
  // Delete from face database
  await faceEmbed.removeStudent(studentId);
  
  // Delete from users table
  await DatabaseHelper().deleteUser(studentId);
  
  print('Student completely removed');
}
```

### Pattern 7: Database Cleanup
```dart
Future<void> cleanupExpiredEmbeddings(DateTime beforeDate) async {
  final allEmbeddings = await DatabaseHelper().getAllFaceEmbeddings();
  
  for (var entry in allEmbeddings.entries) {
    final studentId = entry.key;
    final embeddings = entry.value;
    
    // Remove if last enrollment before date
    if (embeddings.isNotEmpty) {
      final lastEnrolled = embeddings.first['enrolledAt'] as DateTime;
      if (lastEnrolled.isBefore(beforeDate)) {
        await faceEmbed.removeStudent(studentId);
      }
    }
  }
}
```

---

## API Reference - Copy Paste Ready

### Initialize
```dart
final faceEmbed = FaceEmbeddingService();
```

### Enrollment Methods
```dart
// Single enrollment
await faceEmbed.enrollStudentFace(
  studentId: 'STU001',
  studentName: 'John Doe',
  embeddingVector: List<double>, // 128 values
);

// Batch enrollment
await faceEmbed.batchEnrollStudents([
  {
    'studentId': 'STU001',
    'studentName': 'John Doe',
    'embeddingVector': List<double>,
  },
  // ... more students
]);

// Re-enroll with new embeddings
await faceEmbed.reenrollStudent(
  studentId: 'STU001',
  studentName: 'John Doe',
  newEmbeddings: [List<double>, List<double>], // Multiple embeddings
);
```

### Query Methods
```dart
// Check if enrolled
bool enrolled = await faceEmbed.isStudentEnrolled('STU001');

// Get embedding count
int count = await faceEmbed.getStudentEmbeddingCount('STU001');

// Get statistics
Map<String, dynamic> stats = await faceEmbed.getEmbeddingStats();
```

### Loading Methods
```dart
// Load specific students
await faceEmbed.loadStudentEmbeddings(['STU001', 'STU002']);

// Preload all embeddings
await faceEmbed.preloadAllEmbeddings();

// Clear cache
faceEmbed.clearCache();
```

### Removal Methods
```dart
// Remove single student
await faceEmbed.removeStudent('STU001');
```

### Utility Methods
```dart
// Validate embedding
bool valid = FaceEmbeddingService.isValidEmbedding(embedding);

// Normalize embedding
List<double> normalized = 
    FaceEmbeddingService.normalizeEmbedding(embedding);

// Calculate similarity (0-1)
double similarity = FaceEmbeddingService.cosineSimilarity(
  embedding1, // List<double>
  embedding2, // List<double>
);

// Generate mock embedding (for testing)
List<double> mock = FaceEmbeddingService.generateMockEmbedding();
```

---

## Low-Level Database Operations

```dart
final db = DatabaseHelper();

// Save embedding
await db.saveFaceEmbedding(
  embeddingId: 'uuid-here',
  studentId: 'STU001',
  studentName: 'John Doe',
  embeddingVector: List<double>,
  enrolledAt: DateTime.now(),
);

// Get student embeddings
List<Map<String, dynamic>> embeddings = 
    await db.getStudentEmbeddings('STU001');

// Get all embeddings
Map<String, List<Map<String, dynamic>>> all = 
    await db.getAllFaceEmbeddings();

// Delete embedding
await db.deleteFaceEmbedding('embedding-id');

// Delete student embeddings
await db.deleteStudentEmbeddings('STU001');

// Get counts
int total = await db.getTotalFaceEmbeddingCount();
int forStudent = await db.getStudentEmbeddingCount('STU001');
```

---

## Integration with Face Recognition

```dart
final faceRecognition = FaceRecognitionService();

// Save embedding to database + cache
await faceRecognition.saveFaceEmbeddingToDatabase(
  embeddingId: 'uuid',
  studentId: 'STU001',
  studentName: 'John Doe',
  embeddingVector: List<double>,
  enrolledAt: DateTime.now(),
);

// Load embeddings from database
await faceRecognition.loadStudentEmbeddings(['STU001', 'STU002']);

// Recognize face (after loading embeddings)
Map<String, dynamic> result = faceRecognition.recognizeFace(
  faceEmbedding, // Your captured embedding
  confidenceThreshold: 0.7,
);

if (result['matched']) {
  print('Matched: ${result['topMatch']['studentName']}');
  print('Confidence: ${result['confidence']}');
}
```

---

## Error Handling

```dart
try {
  // Validate before enrolling
  if (!FaceEmbeddingService.isValidEmbedding(embedding)) {
    throw Exception('Invalid embedding dimension or values');
  }

  bool success = await faceEmbed.enrollStudentFace(
    studentId: 'STU001',
    studentName: 'John Doe',
    embeddingVector: embedding,
  );

  if (success) {
    print('✓ Enrolled successfully');
  } else {
    print('✗ Enrollment failed - database error');
  }
} catch (e) {
  print('Error: $e');
  // Handle error appropriately
}
```

---

## Performance Tips

1. **Preload on Startup**
   ```dart
   void main() async {
     await FaceEmbeddingService().preloadAllEmbeddings();
     runApp(MyApp());
   }
   ```

2. **Use Batch Operations**
   ```dart
   // Good - single transaction
   await faceEmbed.batchEnrollStudents(allStudents);
   
   // Avoid - multiple operations
   for (student in allStudents) {
     await faceEmbed.enrollStudentFace(...); // Slow!
   }
   ```

3. **Clear Cache When Not Needed**
   ```dart
   if (recognitionDone) {
     faceEmbed.clearCache(); // Free up memory
   }
   ```

4. **Load Only Required Students**
   ```dart
   // Good - load only class students
   await faceEmbed.loadStudentEmbeddings(classStudentIds);
   
   // Avoid - preload all if only need class
   await faceEmbed.preloadAllEmbeddings();
   ```

---

## Validation Checklist

```dart
// Before enrollment
✓ studentId is not empty
✓ studentName is not empty
✓ embedding.length == 128
✓ No NaN or Inf values in embedding
✓ Student not already enrolled (optional)

// Before matching
✓ Embeddings loaded into memory
✓ Captured embedding is valid 128-dim
✓ Confidence threshold set appropriately (0.6-0.9)

// Data integrity
✓ Foreign key relationships maintained
✓ Enrollment timestamps consistent
✓ No duplicate enrollments for same time
```

---

## Example: Complete Attendance Session

```dart
class AttendanceSession {
  final _faceEmbed = FaceEmbeddingService();
  final _faceRec = FaceRecognitionService();

  Future<void> startSession(String classId) async {
    print('📚 Starting attendance for class: $classId');
    
    // 1. Get class students
    final students = await _getClassStudents(classId);
    print('${students.length} students in class');
    
    // 2. Load their embeddings
    await _faceEmbed.loadStudentEmbeddings(students);
    print('✓ Loaded embeddings');
    
    // 3. Ready for recognition
    print('📷 Ready for face recognition');
  }

  Future<String?> recognizeStudent(List<double> faceEmbedding) async {
    // Validate embedding
    if (!FaceEmbeddingService.isValidEmbedding(faceEmbedding)) {
      return null;
    }

    // Perform recognition
    final result = _faceRec.recognizeFace(faceEmbedding);
    
    if (result['matched']) {
      return result['topMatch']['studentId'];
    }
    return null;
  }

  Future<void> endSession() async {
    _faceEmbed.clearCache();
    print('✓ Session ended, cache cleared');
  }
}

// Usage
final session = AttendanceSession();
await session.startSession('CLASS001');

final studentId = await session.recognizeStudent(capturedEmbedding);
if (studentId != null) {
  print('✓ Recognized: $studentId');
  // Mark attendance
}

await session.endSession();
```

---

**That's your complete face embeddings system! Copy-paste the snippets and adapt to your needs.** 🚀
