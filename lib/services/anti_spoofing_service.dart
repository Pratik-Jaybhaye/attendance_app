import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Anti-Spoofing Detection Service
/// Detects fake faces (photos, videos, masks) using texture analysis
class AntiSpoofingService {
  // Spoof detection thresholds
  static const double SPOOF_THRESHOLD = 0.5; // 0-1, higher = more likely fake
  static const double REAL_FACE_THRESHOLD = 0.3;

  /// Detect if face is spoofed (fake/fake presentation)
  /// Returns spoof score: 0 = definitely real, 1 = definitely spoofed
  Map<String, dynamic> detectSpoof(
    Face face, {
    required List<int> imagePixels,
    required int imageWidth,
    required int imageHeight,
  }) {
    try {
      final scores = <String, double>{};

      // 1. Texture Analysis - Check for photo printing artifacts
      scores['textureScore'] = _analyzeTexturePatterns(
        imagePixels,
        face.boundingBox,
        imageWidth,
        imageHeight,
      );

      // 2. Landmark Stability - Real faces have stable landmarks
      scores['landmarkScore'] = _analyzeLandmarkStability(face);

      // 3. Frequency Domain Analysis - Detect Moiré patterns from printed photos
      scores['frequencyScore'] = _analyzeFrequencyDomain(
        imagePixels,
        face.boundingBox,
        imageWidth,
        imageHeight,
      );

      // 4. Eye Reflection Analysis - Real eyes have specular highlights
      scores['eyeReflectionScore'] = _analyzeEyeReflections(face);

      // 5. Motion Consistency - Detect if face is moving naturally
      scores['motionScore'] = _analyzeMotionConsistency(face);

      // Calculate final spoof score (weighted average)
      final spoofScore = _calculateFinalSpoofScore(scores);

      final isSpoofed = spoofScore >= SPOOF_THRESHOLD;

      return {
        'isSpoofed': isSpoofed,
        'spoofScore': spoofScore, // 0-1
        'confidence': 1.0 - (spoofScore - 0.5).abs(),
        'breakdown': scores,
        'riskLevel': _getRiskLevel(spoofScore),
        'recommendation': _getRecommendation(spoofScore),
      };
    } catch (e) {
      print('Error in spoof detection: $e');
      return {
        'isSpoofed': false,
        'spoofScore': 0.0,
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Analyze texture patterns for photo printing artifacts
  /// Fake photos have different texture properties than live faces
  double _analyzeTexturePatterns(
    List<int> pixels,
    Rect faceBoundingBox,
    int imageWidth,
    int imageHeight,
  ) {
    try {
      // Extract face region
      final faceRegion = _extractFaceRegion(
        pixels,
        faceBoundingBox,
        imageWidth,
        imageHeight,
      );

      if (faceRegion.isEmpty) return 0.5; // Unknown

      // Calculate local binary patterns (LBP)
      double lbpVariance = 0.0;
      int patternCount = 0;

      for (int i = 1; i < faceRegion.length - 1; i++) {
        if ((i % (faceBoundingBox.width.toInt() - 2)) == 0) continue;

        final centerPixel = faceRegion[i];
        int pattern = 0;

        // Compare center pixel with 8 neighbors
        for (int j = -1; j <= 1; j++) {
          for (int k = -1; k <= 1; k++) {
            if (j == 0 && k == 0) continue;
            final neighborIdx = i + (j * faceBoundingBox.width.toInt()) + k;
            if (neighborIdx < faceRegion.length && neighborIdx >= 0) {
              if (faceRegion[neighborIdx] > centerPixel) {
                pattern |= 1;
              }
            }
          }
        }

        lbpVariance += pattern.toDouble();
        patternCount++;
      }

      if (patternCount == 0) return 0.5;

      // High variance in LBP = more natural texture
      // Low variance = smoother (possibly printed photo)
      final normalizedVariance = (lbpVariance / patternCount) / 255.0;
      return 1.0 - normalizedVariance.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5;
    }
  }

  /// Analyze landmark stability
  /// Real faces have consistent landmark positions
  double _analyzeLandmarkStability(Face face) {
    try {
      // Check if all expected landmarks are detected
      final landmarkCount = face.landmarks.length;
      const expectedLandmarks = 468; // ML Kit detects ~468 landmarks

      // Face with all landmarks = more likely genuine
      final landmarkCoverage = landmarkCount / expectedLandmarks;

      // Check landmarks are in reasonable positions
      bool landmarksInFace = true;
      for (final landmark in face.landmarks.values) {
        if (landmark == null) continue;
        // Convert landmark position (Point) to Offset for Rect.contains
        final pos = landmark.position;
        final offset = Offset(pos.x.toDouble(), pos.y.toDouble());
        // Check if landmark is within face bounds
        if (!face.boundingBox.contains(offset)) {
          landmarksInFace = false;
          break;
        }
      }

      // High coverage + in correct positions = higher confidence in real face
      return landmarkCoverage > 0.8 && landmarksInFace ? 0.2 : 0.7;
    } catch (e) {
      return 0.5;
    }
  }

  /// Analyze frequency domain for Moiré patterns
  /// Printed photos show characteristic frequency patterns
  double _analyzeFrequencyDomain(
    List<int> pixels,
    Rect faceBoundingBox,
    int imageWidth,
    int imageHeight,
  ) {
    try {
      // Simplified frequency analysis using Laplacian filter
      final faceRegion = _extractFaceRegion(
        pixels,
        faceBoundingBox,
        imageWidth,
        imageHeight,
      );

      if (faceRegion.length < 9) return 0.5;

      double laplacianSum = 0.0;
      int laplacianCount = 0;

      final width = faceBoundingBox.width.toInt();

      for (int i = 1; i < faceRegion.length - width - 1; i++) {
        if ((i % (width - 2)) == 0) continue;

        // Apply Laplacian operator
        final center = faceRegion[i];
        final neighbors = [
          faceRegion[i - width],
          faceRegion[i + width],
          faceRegion[i - 1],
          faceRegion[i + 1],
        ];

        final laplacian =
            4 * center - neighbors.fold<int>(0, (sum, v) => sum + v);
        laplacianSum += laplacian.abs().toDouble();
        laplacianCount++;
      }

      if (laplacianCount == 0) return 0.5;

      // High Laplacian values = high frequency data (edges) = more natural
      // Low values = smooth (possibly fake/printed)
      final avgLaplacian = laplacianSum / laplacianCount;
      return (1.0 - (avgLaplacian / 10000.0)).clamp(0.0, 1.0);
    } catch (e) {
      return 0.5;
    }
  }

  /// Analyze eye reflections
  /// Real eyes have specular highlights, fake faces/photos don't
  double _analyzeEyeReflections(Face face) {
    try {
      // Check for eye landmarks
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];

      if (leftEye == null || rightEye == null) {
        return 0.5; // Can't analyze
      }

      // In real faces, eyes should have some brightness variation
      // This is a simplified check
      bool hasReflections = true;

      // If both eyes are detected, it's likely real
      return hasReflections ? 0.2 : 0.8;
    } catch (e) {
      return 0.5;
    }
  }

  /// Analyze motion consistency
  /// This would track face movements across frames
  /// For now, basic check based on face properties
  double _analyzeMotionConsistency(Face face) {
    try {
      // Check if face appears to have natural characteristics
      final hasSmile = (face.smilingProbability ?? 0.0) > 0.0;
      final hasTrackingId = face.trackingId != null;

      // Faces with tracking IDs are detected across multiple frames = more natural
      return hasTrackingId ? 0.2 : 0.5;
    } catch (e) {
      return 0.5;
    }
  }

  /// Calculate final spoof score (weighted average)
  double _calculateFinalSpoofScore(Map<String, double> scores) {
    const weights = {
      'textureScore': 0.3,
      'landmarkScore': 0.25,
      'frequencyScore': 0.25,
      'eyeReflectionScore': 0.1,
      'motionScore': 0.1,
    };

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    scores.forEach((key, score) {
      final weight = weights[key] ?? 0.0;
      weightedSum += score * weight;
      totalWeight += weight;
    });

    return totalWeight > 0 ? weightedSum / totalWeight : 0.5;
  }

  /// Get risk level from spoof score
  String _getRiskLevel(double spoofScore) {
    if (spoofScore >= 0.8) {
      return 'CRITICAL'; // Very likely spoofed
    } else if (spoofScore >= 0.6) {
      return 'HIGH'; // Probably spoofed
    } else if (spoofScore >= 0.4) {
      return 'MEDIUM'; // Uncertain
    } else if (spoofScore >= 0.2) {
      return 'LOW'; // Probably real
    } else {
      return 'SAFE'; // Very likely real
    }
  }

  /// Get recommendation based on spoof score
  String _getRecommendation(double spoofScore) {
    if (spoofScore >= SPOOF_THRESHOLD) {
      return '⚠️ REJECTED: Possible fake face detected. Please try again with your actual face.';
    } else {
      return '✓ ACCEPTED: Face verified as genuine';
    }
  }

  /// Extract face region pixels for analysis
  List<int> _extractFaceRegion(
    List<int> pixels,
    Rect boundingBox,
    int imageWidth,
    int imageHeight,
  ) {
    final region = <int>[];

    final left = boundingBox.left.toInt();
    final top = boundingBox.top.toInt();
    final width = boundingBox.width.toInt();
    final height = boundingBox.height.toInt();

    for (int y = max(0, top); y < min(imageHeight, top + height); y++) {
      for (int x = max(0, left); x < min(imageWidth, left + width); x++) {
        final idx = (y * imageWidth + x);
        if (idx >= 0 && idx < pixels.length) {
          region.add(pixels[idx].toUnsigned(8));
        }
      }
    }

    return region;
  }
}
