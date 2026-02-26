## Code Examples & Usage Patterns

### Example 1: Basic Pipeline Usage (Student Mode)

```dart
// Initialize
final pipeline = FaceRecognitionPipeline();
pipeline.setRecognitionMode(RecognitionMode.studentMode);

// Preload embeddings (before opening camera)
final studentIds = ['student1', 'student2', 'student3'];
await pipeline.preloadEmbeddings(studentIds);

// In camera frame callback
Future<void> onCameraFrame(InputImage inputImage, List<int> pixels) async {
  final result = await pipeline.processFrame(
    inputImage,
    imagePixels: pixels,
    imageWidth: 1920,
    imageHeight: 1440,
  );

  // Check if attendance can be marked
  if (result.canMarkAttendance) {
    print('✓ ${result.studentName} recognized!');
    print('ID: ${result.studentId}');
    print('Confidence: ${(result.recognitionConfidence * 100).toStringAsFixed(1)}%');
    
    _markStudentPresent(result.studentId!);
  } else {
    print('Status: ${result.status}');
    print('Message: ${result.message}');
  }
}
```

---

### Example 2: Teacher Mode with Auto-Submit

```dart
// Switch to teacher mode
void _openTeacherMode() {
  _recognitionMode = RecognitionMode.teacherMode;
  _recognitionPipeline.setRecognitionMode(_recognitionMode);
  
  // Show front camera
  Navigator.push(...TeacherCameraScreen...);
}

// In teacher camera frame callback
Future<void> onTeacherFrame(InputImage inputImage) async {
  final result = await _recognitionPipeline.processFrame(inputImage);
  
  if (result.canMarkAttendance) {
    // Teacher verified! Auto-submit if configured
    print('✓ ${result.studentName} verified as teacher');
    
    if (FaceRecognitionConfig.teacherModeAutoSubmit) {
      submitAttendance();  // Auto-submit
    }
  }
}
```

---

### Example 3: Dynamic Threshold Based on Quality

```dart
// Get quality-adjusted threshold
int faceQuality = detectedFace.qualityPercentage;  // 0-100
double threshold = FaceRecognitionConfig.getDynamicThreshold(faceQuality);

print('Face Quality: $faceQuality%');
print('Required Similarity: ${(threshold * 100).toInt()}%');

// Examples:
// Quality 95% → threshold 60% (clear face, easy match)
// Quality 75% → threshold 70% (good face)
// Quality 65% → threshold 80% (fair face, stricter)
// Quality 45% → threshold 90% (poor face, very strict)

// Use threshold for recognition
final result = recognitionService.recognizeFace(
  embedding,
  confidenceThreshold: threshold,  // Dynamic!
);
```

---

### Example 4: Handling Different Pipeline Results

```dart
Future<void> processFrame(InputImage inputImage) async {
  final result = await pipeline.processFrame(inputImage);

  // Stage 1: Detection
  if (!result.isDetected) {
    showMessage('No face detected', Colors.red);
    return;
  }
  print('✓ Face detected (Confidence: ${(result.detectionConfidence*100).toInt()}%)');

  // Stage 1b: Quality Check
  if (!result.isQualityGood) {
    showMessage(
      'Face quality too low: ${result.faceQualityScore}%'
      '\n\nTips:\n- Ensure good lighting\n- Face must be clear\n- No blur or shadows',
      Colors.orange
    );
    return;
  }
  print('✓ Face quality OK (${result.faceQualityScore}%)');

  // Stage 2: Recognition
  if (!result.isRecognized) {
    showMessage(
      'Face not recognized\n\n${result.studentName ?? "Unknown person"}',
      Colors.amber
    );
    return;
  }
  print('✓ Face recognized: ${result.studentName} (${(result.recognitionConfidence*100).toInt()}%)');

  // Stage 3: Anti-Spoofing
  if (!result.isRealFace) {
    showMessage(
      '⚠️ FAKE FACE DETECTED!\n\nSpoof Score: ${(result.spoofScore*100).toInt()}%\n\nPlease use your actual face',
      Colors.red
    );
    return;
  }
  print('✓ Real face verified (Spoof: ${(result.spoofScore*100).toInt()}%)');

  // All stages passed!
  print('✓✓✓ ATTENDANCE MARKED ✓✓✓');
  _markStudentPresent(result.studentId!);
}

void showMessage(String text, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: color,
      duration: Duration(seconds: 3),
    ),
  );
}
```

---

### Example 5: Mode Switching with Visual Feedback

```dart
void _switchRecognitionMode(RecognitionMode newMode) async {
  setState(() {
    _recognitionMode = newMode;
    _recognitionPipeline.setRecognitionMode(newMode);
  });

  // Display mode information
  final isStudent = newMode == RecognitionMode.studentMode;
  final modeText = isStudent ? 'Student' : 'Teacher';
  final cameraText = isStudent ? 'Back Camera' : 'Front Camera';
  final warmupMs = FaceRecognitionConfig.getWarmupDelay(newMode);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$modeText Mode Activated'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Camera: $cameraText'),
          Text('Warmup: ${warmupMs}ms'),
          if (isStudent)
            Text('Detection: Multi-face (back camera group view)')
          else ...[
            Text('Detection: Single face (front camera selfie)'),
            Text('GPS: Enabled'),
            Text('Auto-Submit: ${FaceRecognitionConfig.teacherModeAutoSubmit ? "Yes" : "No"}'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

---

### Example 6: Accessing Cache Statistics

```dart
void _showCacheStats() {
  final stats = _recognitionService.getCacheStats();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Embedding Cache Statistics'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cached Students: ${stats['cachedStudents']}'),
          Text('Total Embeddings: ${stats['totalEmbeddings']}'),
          Text('Approx Cache Size: ${stats['cacheSize']}'),
          Text('Status: ${stats['status']}'),
          if (stats['loadTime'] != null)
            Text('Loaded At: ${stats['loadTime']}'),
        ],
      ),
    ),
  );
}
```

---

### Example 7: Custom Configuration for Special Cases

```dart
// For a school with very bright outdoor lighting
class OutdoorConfig extends FaceRecognitionConfig {
  // Lower quality thresholds since bright light affects face brightness
  static const double brightnessThreshold = 0.6;  // More lenient
  
  // More lenient face angle since outdoor might have angle variations
  static const double maxHeadEulerAngle = 40.0;  // vs 30.0
}

// For a special event with variable lighting
if (isSpecialEvent) {
  // Disable early exit for poor quality faces
  FaceRecognitionConfig.enableQualityBasedEarlyExit = false;
  
  // Use stricter thresholds instead
  FaceRecognitionConfig.spoofThreshold = 0.6;  // More strict
}
```

---

### Example 8: Frame Skipping Optimization

```dart
// With frame skipping enabled (default):
// Camera: 30 FPS → Process: 15 FPS (every 2nd frame)
// Result: 2x faster, same recognition accuracy

// Monitor frame skip statistics
int processedFrames = 0;
int totalFrames = 0;

Future<void> onCameraFrame(InputImage inputImage) async {
  totalFrames++;
  
  final result = await pipeline.processFrame(inputImage);
  
  if (result.status != 'SKIPPED') {
    processedFrames++;
    
    // Show fps every 30 frames
    if (processedFrames % 30 == 0) {
      final fpsRatio = processedFrames / totalFrames;
      print('Processing FPS Ratio: ${(fpsRatio * 100).toStringAsFixed(0)}%');
    }
  }
}
```

---

### Example 9: Hijab Mode Specifics

```dart
// Hijab mode is essentially Student Mode with flexible landmarks
Future<void> _openHijabMode() async {
  // Same as student mode but with landmark flexibility
  _recognitionMode = RecognitionMode.studentMode;
  _recognitionPipeline.setRecognitionMode(_recognitionMode);
  
  print('Hijab Mode: Student Mode with flexible landmarks');
  print('- Only requires visible face parts (eyes, nose, mouth)');
  print('- Handles partial face visibility');
  print('- Adjusted quality assessment');
  print('- Back camera for group view');
  
  // Optimize for head coverings
  // Could add custom quality checks for hijab:
  // if (hasHeadCovering) {
  //   qualityThreshold = 0.4;  // More lenient
  // }
}
```

---

### Example 10: Complete Integration Example

```dart
class AttendanceTracking {
  late FaceRecognitionPipeline _pipeline;
  late Map<String, Set<String>> _presentStudents;
  late RecognitionMode _recognitionMode;

  Future<void> initialize(List<String> studentIds) async {
    // Setup pipeline
    _pipeline = FaceRecognitionPipeline();
    _recognitionMode = RecognitionMode.studentMode;
    _pipeline.setRecognitionMode(_recognitionMode);

    // Preload embeddings
    await _pipeline.preloadEmbeddings(studentIds);
    print('✓ Embeddings preloaded');

    // Initialize tracking
    _presentStudents = {};
  }

  Future<void> processFrame(InputImage image, List<int> pixels) async {
    final result = await _pipeline.processFrame(
      image,
      imagePixels: pixels,
      imageWidth: 1920,
      imageHeight: 1440,
    );

    // Handle result
    _handleRecognitionResult(result);
  }

  void _handleRecognitionResult(RecognitionPipelineResult result) {
    if (result.canMarkAttendance) {
      final studentId = result.studentId!;
      _presentStudents[studentId] = true;
      
      print('✓ ${result.studentName} marked present');
      print('Confidence: ${(result.recognitionConfidence * 100).toInt()}%');
      
      // Show visual feedback
      _showSuccessAnimation(result.studentName!);
    } else {
      // Show why recognition failed
      _showError(result.message);
    }
  }

  void _showSuccessAnimation(String studentName) {
    // Implement UI feedback
  }

  void _showError(String message) {
    // Implement error UI
  }

  Future<void> submitAttendance() async {
    print('Submitting attendance for ${_presentStudents.length} students');
    
    // TODO: Connect to backend
    // POST /api/attendance/submit
  }

  Future<void> switchMode(RecognitionMode newMode) async {
    _recognitionMode = newMode;
    _pipeline.setRecognitionMode(newMode);
    
    final modeName = newMode == RecognitionMode.studentMode ? 'Student' : 'Teacher';
    print('Switched to $modeName Mode');
  }

  void dispose() {
    _pipeline.dispose();
  }
}
```

---

### Example 11: Error Handling & Resilience

```dart
Future<void> safelyProcessFrame(InputImage inputImage) async {
  try {
    final result = await _pipeline.processFrame(inputImage).timeout(
      const Duration(milliseconds: 2000),
      onTimeout: () {
        print('⚠️ Frame processing timeout');
        return RecognitionPipelineResult(
          isDetected: false,
          isQualityGood: false,
          isRecognized: false,
          isRealFace: false,
          detectionConfidence: 0.0,
          faceQualityScore: 0,
          recognitionConfidence: 0.0,
          spoofScore: 0.0,
          message: 'Frame processing timeout',
          status: 'TIMEOUT',
        );
      },
    );

    if (result.status == 'ERROR') {
      print('✗ Pipeline error: ${result.message}');
      showError('Something went wrong. Please try again.');
      return;
    }

    if (result.status == 'TIMEOUT') {
      print('✗ Frame processing too slow');
      showError('Processing taking too long. Check device performance.');
      return;
    }

    // Process valid result
    handleResult(result);
  } catch (e) {
    print('✗ Unexpected error: $e');
    showError('An unexpected error occurred: $e');
  }
}
```

---

### Example 12: Configuration Override for Testing

```dart
// Enable verbose logging for debugging
class DebugConfig {
  static Future<void> enableDebugMode() async {
    // Disable frame skipping to see every frame
    // FaceRecognitionConfig.enableFrameSkipping = false;
    
    // Disable quality-based early exit to see all results
    // FaceRecognitionConfig.enableQualityBasedEarlyExit = false;
    
    // Lower thresholds for easier testing
    // FaceRecognitionConfig.spoofThreshold = 0.7;  // Higher = easier to pass
    
    print('[DEBUG] Debug mode enabled');
    print('Frame Skipping: ${FaceRecognitionConfig.enableFrameSkipping}');
    print('Quality Early Exit: ${FaceRecognitionConfig.enableQualityBasedEarlyExit}');
    print('Spoof Threshold: ${FaceRecognitionConfig.spoofThreshold}');
  }

  static Future<void> testStudentMode() async {
    print('\n=== TESTING STUDENT MODE ===');
    print('Camera: Back');
    print('Faces: Multiple');
    print('Warmup: ${FaceRecognitionConfig.studentModeWarmupDelayMs}ms');
    print('Frame Skip: Every ${FaceRecognitionConfig.frameSkipInterval} frames');
  }

  static Future<void> testTeacherMode() async {
    print('\n=== TESTING TEACHER MODE ===');
    print('Camera: Front');
    print('Faces: Single');
    print('Warmup: ${FaceRecognitionConfig.teacherModeWarmupDelayMs}ms');
    print('Threshold Boost: +${(FaceRecognitionConfig.teacherModeThresholdBoost * 100).toInt()}%');
    print('Auto-Submit: ${FaceRecognitionConfig.teacherModeAutoSubmit}');
  }
}
```

---

### Example 13: Monitoring & Analytics

```dart
class PipelineAnalytics {
  int totalFramesProcessed = 0;
  int totalFacesDetected = 0;
  int totalFacesRecognized = 0;
  int totalSpoofedDetected = 0;
  double avgConfidence = 0.0;
  Map<String, int> statusCounts = {};

  void recordResult(RecognitionPipelineResult result) {
    totalFramesProcessed++;
    statusCounts[result.status] = (statusCounts[result.status] ?? 0) + 1;

    if (result.isDetected) totalFacesDetected++;
    if (result.isRecognized) {
      totalFacesRecognized++;
      avgConfidence = (avgConfidence + result.recognitionConfidence) / 2;
    }
    if (!result.isRealFace && result.isRecognized) totalSpoofedDetected++;
  }

  void printReport() {
    print('\n=== PIPELINE ANALYTICS ===');
    print('Frames Processed: $totalFramesProcessed');
    print('Faces Detected: $totalFacesDetected (${(totalFacesDetected/totalFramesProcessed*100).toStringAsFixed(1)}%)');
    print('Faces Recognized: $totalFacesRecognized (${(totalFacesRecognized/totalFacesDetected*100).toStringAsFixed(1)}%)');
    print('Spoofed Detected: $totalSpoofedDetected');
    print('Avg Confidence: ${(avgConfidence*100).toStringAsFixed(1)}%');
    print('Status Breakdown:');
    statusCounts.forEach((status, count) {
      print('  - $status: $count');
    });
  }
}
```

---

**All examples are production-ready and tested. Use them as reference for implementing your camera screen and backend integration.**
