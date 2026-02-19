import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// Face Quality Score Model
class FaceQualityScore {
  final bool isBlur;
  final bool isLowLight;
  final bool isHeadPose;
  final double blurScore; // 0-1, higher = more blurry
  final double brightnessScore; // 0-1, higher = brighter
  final double headPoseScore; // 0-1, higher = poor pose

  FaceQualityScore({
    required this.isBlur,
    required this.isLowLight,
    required this.isHeadPose,
    this.blurScore = 0.0,
    this.brightnessScore = 0.0,
    this.headPoseScore = 0.0,
  });

  /// Check if face quality is good enough for recognition
  bool get isGoodQuality => !isBlur && !isLowLight && !isHeadPose;

  /// Get overall quality percentage (0-100)
  int get qualityPercentage {
    final qualityScore =
        (1.0 - (blurScore + brightnessScore + headPoseScore) / 3) * 100;
    return qualityScore.toInt().clamp(0, 100);
  }
}

/// Face Detection Service using ML Kit
/// Detects faces in camera frames with quality assessment
class FaceDetectionService {
  late FaceDetector _faceDetector;
  FaceDetectionService() {
    _initializeFaceDetector();
  }

  /// Initialize ML Kit Face Detector in ACCURATE mode
  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate, // Slower but more precise
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.1, // Minimum face size as proportion
        enableLandmarks: true,
      ),
    );
  }

  /// Detect faces in frame with quality assessment
  /// Returns list of detected faces with quality scores
  Future<List<Map<String, dynamic>>> detectFaces(InputImage inputImage) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);

      final detectedFaces = <Map<String, dynamic>>[];

      for (final face in faces) {
        final quality = assessFaceQuality(face);

        // Only return faces with reasonable quality
        if (quality.isGoodQuality || quality.qualityPercentage > 40) {
          detectedFaces.add({
            'face': face,
            'boundingBox': face.boundingBox,
            'landmarks': face.landmarks,
            'quality': quality,
            'confidence': _calculateDetectionConfidence(face),
            'headEulerAngleY': face.headEulerAngleY ?? 0,
            'headEulerAngleZ': face.headEulerAngleZ ?? 0,
          });
        }
      }

      return detectedFaces;
    } catch (e) {
      print('Error detecting faces: $e');
      return [];
    }
  }

  /// Assess face quality based on multiple factors
  /// Public wrapper to assess face quality
  FaceQualityScore assessFaceQuality(Face face) {
    // Check head pose (euler angles)
    final headEulerY = (face.headEulerAngleY ?? 0).abs();
    final headEulerZ = (face.headEulerAngleZ ?? 0).abs();
    final isHeadPose = headEulerY > 30 || headEulerZ > 30;
    final headPoseScore = ((headEulerY + headEulerZ) / 120).clamp(0.0, 1.0);

    // Check if face is smiling (brightness indicator)
    // Estimate blur (face tracking/landmark stability)
    final hasSufficientLandmarks = (face.landmarks.length) > 0;
    final isBlur = !hasSufficientLandmarks;
    final blurScore = isBlur ? 0.8 : 0.2;

    // Estimate low light (landmark visibility)
    final isLowLight = !hasSufficientLandmarks;
    final brightnessScore = isLowLight ? 0.7 : 0.2;

    return FaceQualityScore(
      isBlur: isBlur,
      isLowLight: isLowLight,
      isHeadPose: isHeadPose,
      blurScore: blurScore,
      brightnessScore: brightnessScore,
      headPoseScore: headPoseScore,
    );
  }

  /// Calculate detection confidence (0-1)
  double _calculateDetectionConfidence(Face face) {
    // Higher confidence if landmarks are detected (face is clear)
    final landmarkCount = face.landmarks.length;
    final maxLandmarks = 468; // ML Kit provides up to 468 landmarks
    final landmarkConfidence = landmarkCount / maxLandmarks;

    // Check if face tracking id exists
    final hasTrackingId = face.trackingId != null;
    final trackingConfidence = hasTrackingId ? 0.9 : 0.7;

    return ((landmarkConfidence * 0.5) + (trackingConfidence * 0.5)).clamp(
      0.0,
      1.0,
    );
  }

  /// Get approximate face center coordinates
  Map<String, double> getFaceCenter(Rect boundingBox) {
    return {
      'x': (boundingBox.left + boundingBox.right) / 2,
      'y': (boundingBox.top + boundingBox.bottom) / 2,
    };
  }

  /// Calculate IoU (Intersection over Union) to detect duplicate faces
  double calculateIoU(Rect box1, Rect box2) {
    final intersection = box1.intersect(box2);
    final intersectionArea = intersection.width * intersection.height;

    final union =
        (box1.width * box1.height) +
        (box2.width * box2.height) -
        intersectionArea;

    if (union <= 0) return 0;
    return intersectionArea / union;
  }

  /// Filter duplicate faces within IoU threshold (0.3 = 30% overlap)
  List<Map<String, dynamic>> filterDuplicateFaces(
    List<Map<String, dynamic>> detectedFaces, {
    double iouThreshold = 0.3,
  }) {
    if (detectedFaces.isEmpty) return [];

    final filtered = <Map<String, dynamic>>[];

    for (final faceData in detectedFaces) {
      final boundingBox = faceData['boundingBox'] as Rect;
      bool isDuplicate = false;

      for (final existingFace in filtered) {
        final existingBox = existingFace['boundingBox'] as Rect;
        final iou = calculateIoU(boundingBox, existingBox);

        if (iou > iouThreshold) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        filtered.add(faceData);
      }
    }

    return filtered;
  }

  /// Dispose face detector
  void dispose() {
    _faceDetector.close();
  }
}
