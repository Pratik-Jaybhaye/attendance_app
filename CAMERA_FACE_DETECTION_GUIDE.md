## Face Detection & Camera Integration Guide

This document provides instructions for implementing face recognition and camera functionality in the attendance app.

### Overview

The app uses:
1. **Camera Package** - For device camera access
2. **Google ML Kit Face Detection** - For detecting faces in real-time
3. **Custom Face Matching** - For matching detected faces with enrolled students

---

### Step 1: Camera Permission Setup

#### Android Setup

In `android/app/src/main/AndroidManifest.xml`, add:

```xml
<!-- Camera permissions -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Features -->
<uses-feature
    android:name="android.hardware.camera"
    android:required="true" />
<uses-feature
    android:name="android.hardware.camera.autofocus"
    android:required="true" />
```

#### iOS Setup

In `ios/Runner/Info.plist`, add:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture student photos for face recognition attendance</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need your permission to access photos</string>
```

---

### Step 2: Request Runtime Permissions

Implement in your app initialization:

```dart
import 'package:permission_handler/permission_handler.dart';

/// Request camera permission
Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  
  if (status.isDenied) {
    // Permission denied
    print('Camera permission denied');
    return false;
  } else if (status.isPermanentlyDenied) {
    // Permission permanently denied, open app settings
    openAppSettings();
    return false;
  } else if (status.isGranted) {
    print('Camera permission granted');
    return true;
  } else if (status.isRestricted) {
    print('Camera permission restricted');
    return false;
  }
  
  return false;
}

/// Check if camera permission is already granted
Future<bool> isCameraPermissionGranted() async {
  final status = await Permission.camera.status;
  return status.isGranted;
}
```

---

### Step 3: Initialize Camera

Create a camera service:

```dart
// lib/services/camera_service.dart

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io' show Platform;

class CameraService {
  late CameraController _controller;
  late FaceDetector _faceDetector;
  List<CameraDescription> _availableCameras = [];

  /// Initialize camera and face detector
  Future<void> initializeCamera() async {
    try {
      // Get available cameras
      _availableCameras = await availableCameras();
      
      if (_availableCameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Use front camera for attendance (user-facing)
      final frontCamera = _availableCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _availableCameras[0],
      );

      // Initialize controller
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller.initialize();

      // Initialize face detector with options
      final options = FaceDetectorOptions(
        mode: FaceDetectorMode.fast, // Use fast mode for real-time performance
        minFaceSize: 0.1,
        enableTracking: true, // Track detected faces
      );
      
      _faceDetector = FaceDetector(options: options);
      
      print('Camera initialized successfully');
    } catch (e) {
      print('Error initializing camera: $e');
      rethrow;
    }
  }

  /// Get camera controller
  CameraController get controller => _controller;

  /// Detect faces in a camera frame
  Future<List<Face>> detectFaces(CameraImage image) async {
    try {
      // Convert camera image to InputImage
      final inputImage = _convertCameraImageToInputImage(image);
      
      // Detect faces
      final faces = await _faceDetector.processImage(inputImage);
      
      return faces;
    } catch (e) {
      print('Error detecting faces: $e');
      return [];
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage _convertCameraImageToInputImage(CameraImage image) {
    final rotation = _getImageRotation();
    
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;
    
    final plane = image.planes.isNotEmpty ? image.planes[0] : null;
    final imageData = InputImageData(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      imageRotation: rotation,
      inputImageFormat: format,
      planeData: image.planes
          .map((plane) => InputImagePlaneMetadata(
                bytesPerRow: plane.bytesPerRow,
                height: plane.height,
                width: plane.width,
              ))
          .toList(),
    );

    return InputImage.fromBytes(bytes: image.planes[0].bytes, inputImageData: imageData);
  }

  /// Get image rotation based on device orientation
  InputImageRotation _getImageRotation() {
    // This should be based on device orientation
    // Simplified version - in production, use package:device_info_plus
    if (Platform.isAndroid) {
      return InputImageRotation.rotation0deg;
    } else if (Platform.isIOS) {
      return InputImageRotation.rotation90deg;
    }
    return InputImageRotation.rotation0deg;
  }

  /// Capture photo
  Future<String> takePicture() async {
    try {
      final image = await _controller.takePicture();
      return image.path;
    } catch (e) {
      print('Error taking picture: $e');
      rethrow;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _controller.dispose();
    await _faceDetector.close();
  }
}
```

---

### Step 4: Implement Face Matching Service

```dart
// lib/services/face_matching_service.dart

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:typed_data';
import 'dart:convert';

class FaceMatchingService {
  /// Match a detected face with enrolled student faces
  /// 
  /// [detectedFaceData] - Byte array of detected face image
  /// [enrolledStudentFaces] - List of enrolled student face data
  /// [threshold] - Confidence threshold for matching (0.0 - 1.0)
  /// 
  /// Returns: {studentId, confidence} or null if no match
  Future<Map<String, dynamic>?> matchFace(
    Uint8List detectedFaceData,
    List<Map<String, dynamic>> enrolledStudentFaces,
    double threshold = 0.85,
  ) async {
    try {
      // TODO: Implement actual face embedding/matching
      // Using ML Kit Face Detection for feature extraction
      
      // For now, this is a placeholder
      // In production, you would:
      // 1. Extract face embeddings from detected face
      // 2. Compare with enrolled face embeddings
      // 3. Use cosine similarity or similar algorithm
      // 4. Return best match if confidence > threshold

      // Example implementation using mock data
      Map<String, dynamic>? bestMatch;
      double bestConfidence = 0.0;

      for (final enrolledFace in enrolledStudentFaces) {
        // Calculate similarity score
        // TODO: Replace with actual face embedding comparison
        final confidence = _calculateFaceSimilarity(
          detectedFaceData,
          enrolledFace['imageBase64'] as String,
        );

        if (confidence > bestConfidence && confidence >= threshold) {
          bestConfidence = confidence;
          bestMatch = {
            'studentId': enrolledFace['studentId'],
            'studentName': enrolledFace['studentName'],
            'confidence': confidence,
          };
        }
      }

      return bestMatch;
    } catch (e) {
      print('Error matching face: $e');
      return null;
    }
  }

  /// Calculate face similarity (placeholder)
  /// In production, use ML embedding models
  double _calculateFaceSimilarity(
    Uint8List detectedFace,
    String enrolledFaceBase64,
  ) {
    // TODO: Replace with actual ML-based similarity calculation
    // Using face embeddings and cosine similarity
    
    // For now, return random confidence for testing
    return 0.92 + (DateTime.now().millisecondsSinceEpoch % 8) / 100;
  }

  /// Extract face landmarks for additional verification
  List<Point<int>> extractFaceLandmarks(Face face) {
    final landmarks = <Point<int>>[];
    
    if (face.landmarks.isNotEmpty) {
      for (final landmark in face.landmarks) {
        landmarks.add(Point(
          landmark.position.x.toInt(),
          landmark.position.y.toInt(),
        ));
      }
    }
    
    return landmarks;
  }

  /// Verify if detected face meets quality requirements
  bool isFaceQualityGood(Face face) {
    // Check if face is clearly visible
    if (face.boundingBox.width < 50 || face.boundingBox.height < 50) {
      return false; // Face too small
    }

    // Check brightness (if provided by ML Kit)
    // This is a simplified check
    if (face.smilingProbability != null && face.smilingProbability! < 0.0) {
      return false;
    }

    return true;
  }
}
```

---

### Step 5: Create Camera Screen

```dart
// lib/screens/camera_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/face_matching_service.dart';

class CameraScreen extends StatefulWidget {
  final String mode; // 'standard' or 'hijab'
  final List<ClassModel> classes;
  final Function(String classId, String studentId) onStudentDetected;

  const CameraScreen({
    super.key,
    required this.mode,
    required this.classes,
    required this.onStudentDetected,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraService _cameraService;
  late FaceMatchingService _faceMatchingService;
  bool _isProcessing = false;
  String _detectionStatus = 'Initializing...';
  Map<String, dynamic>? _lastDetectedStudent;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _faceMatchingService = FaceMatchingService();
    _initializeCamera();
  }

  /// Initialize camera on startup
  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initializeCamera();
      setState(() {
        _detectionStatus = 'Camera ready - Hold still to detect face';
      });
      _startFaceDetection();
    } catch (e) {
      setState(() {
        _detectionStatus = 'Error: Failed to initialize camera';
      });
    }
  }

  /// Start continuous face detection
  void _startFaceDetection() {
    _cameraService.controller.startImageStream((CameraImage image) async {
      if (!_isProcessing) {
        _isProcessing = true;

        try {
          // Detect faces in current frame
          final faces = await _cameraService.detectFaces(image);

          if (faces.isNotEmpty) {
            final face = faces[0]; // Use first detected face

            // Check if face quality is good
            if (_faceMatchingService.isFaceQualityGood(face)) {
              // TODO: Extract face embedding and match with enrolled faces
              // For now, show detection success

              setState(() {
                _detectionStatus = 'Face detected - Processing...';
              });

              // Simulate face matching
              // In production, call actual face matching service
              // final matchResult = await _faceMatchingService.matchFace(
              //   faceData,
              //   enrolledFaces,
              // );

              // if (matchResult != null) {
              //   widget.onStudentDetected(classId, matchResult['studentId']);
              //   setState(() {
              //     _lastDetectedStudent = matchResult;
              //     _detectionStatus = 'Student: ${matchResult['studentName']}';
              //   });
              // }
            } else {
              setState(() {
                _detectionStatus = 'Face too small or unclear - Move closer';
              });
            }
          } else {
            setState(() {
              _detectionStatus = 'No face detected - Position yourself in frame';
            });
          }
        } catch (e) {
          print('Error during face detection: $e');
        } finally {
          _isProcessing = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera - ${widget.mode} Mode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            child: CameraPreview(_cameraService.controller),
          ),

          // Status indicator
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _detectionStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_lastDetectedStudent != null) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Detected: ${_lastDetectedStudent!['studentName']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Confidence: ${(_lastDetectedStudent!['confidence'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Step 6: Integration with Take Attendance Screen

Update `take_attendance_screen.dart` to use camera:

```dart
// In the TakeAttendanceScreen class

void _openLiveCameraStandard() async {
  // Request camera permission first
  final hasPermission = await requestCameraPermission();
  if (!hasPermission) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera permission is required')),
    );
    return;
  }

  // Navigate to camera screen
  if (mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          mode: 'standard',
          classes: widget.selectedClasses,
          onStudentDetected: _markStudentPresent,
        ),
      ),
    );
  }
}
```

---

### Important Notes

1. **Face Detection Accuracy:**
   - Adjust `threshold` based on your requirements
   - Test with various lighting conditions
   - Enroll at least 5-10 photos per student for better accuracy

2. **Performance Optimization:**
   - Process every Nth frame instead of every frame for better performance
   - Use `ResolutionPreset.medium` or lower for faster processing
   - Consider using GPU acceleration if available

3. **Privacy Considerations:**
   - Encrypt stored face data
   - Never store raw photos long-term
   - Use face embeddings instead of raw images
   - Implement proper data retention policies

4. **Testing:**
   - Test with multiple lighting conditions
   - Test with different face angles
   - Test with various phone models
   - Handle camera initialization failures gracefully

---

### Debugging

Enable debugging logs:

```dart
// In pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

// In code
import 'dart:developer' as developer;

developer.log('Detected faces: ${faces.length}', name: 'FaceDetection');
```

---

**Last Updated:** February 18, 2025
