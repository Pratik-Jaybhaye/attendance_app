/// Face Recognition Configuration
/// Central configuration for all face detection, recognition, and anti-spoofing parameters
/// Based on the 3-stage pipeline architecture

/// Recognition Thresholds and Modes
enum RecognitionMode { studentMode, teacherMode }

class FaceRecognitionConfig {
  // ===========================================================================
  // STAGE 1: FACE DETECTION PARAMETERS
  // ===========================================================================

  /// Detection Mode - ACCURATE for precise detection (slower, more accurate)
  static const String detectionMode = 'ACCURATE';

  /// Camera Configuration
  static const int cameraResolutionWidth = 1920;
  static const int cameraResolutionHeight = 1440;

  /// Frame Processing
  /// Process every 2nd frame for balance between speed & accuracy
  static const int frameSkipInterval = 2;

  /// Minimum face size as proportion of frame (0.1 = 10%)
  /// Allows detection from 10-15 feet away
  static const double minFaceSize = 0.1;

  /// IoU (Intersection over Union) threshold for duplicate face filtering
  /// 0.3 = 30% overlap detection
  static const double iouThresholdForDuplicates = 0.3;

  /// Face Quality Assessment Thresholds
  static const double maxHeadEulerAngle = 30.0; // degrees
  static const double minLandmarkCount =
      50; // Sufficient landmarks for recognition

  // ===========================================================================
  // STAGE 2: FACE RECOGNITION PARAMETERS (FaceNet)
  // ===========================================================================

  /// Recognition Confidence Thresholds (dynamic based on quality)
  /// Quality 90+: 60% similarity required (high confidence face)
  /// Quality 75-90: 70% similarity required (good quality face)
  /// Quality 60-75: 80% similarity required (fair quality face)
  /// Quality <60: 90% similarity required (poor quality face - strict)

  static const double baselowQualityThreshold = 0.90;
  static const double fairQualityThreshold = 0.80;
  static const double goodQualityThreshold = 0.70;
  static const double highQualityThreshold = 0.60;

  /// Quality score boundaries
  static const int lowQualityBoundary = 60;
  static const int fairQualityBoundary = 75;
  static const int goodQualityBoundary = 90;

  /// Embedding Dimension (FaceNet output vector size)
  static const int embeddingDimension = 128;

  /// Number of top matches to return from recognition
  static const int topMatchesCount = 3;

  /// Embedding Cache Size (max embeddings to keep in memory)
  /// Configurable based on device RAM
  static const int maxCachedEmbeddings = 5000;

  // ===========================================================================
  // STAGE 3: ANTI-SPOOFING PARAMETERS (MobileFaceNet Lite)
  // ===========================================================================

  /// Enable/Disable anti-spoofing detection
  /// Set to false for testing without spoof detection
  static const bool enableAntiSpoofing = true;

  /// Spoof Detection Score Thresholds
  /// 0.0 = definitely real, 1.0 = definitely fake
  static const double spoofThreshold =
      0.5; // Faces score >= this are considered fake
  static const double realFaceThreshold =
      0.3; // High confidence real face threshold

  /// Spoof Detection Component Weights
  /// These control importance of different spoof detection methods
  static const Map<String, double> spoofWeights = {
    'textureScore': 0.3,
    'landmarkScore': 0.25,
    'frequencyScore': 0.25,
    'eyeReflectionScore': 0.1,
    'motionScore': 0.1,
  };

  // ===========================================================================
  // MODE-SPECIFIC CONFIGURATIONS
  // ===========================================================================

  /// STUDENT MODE (Multi-face recognition)
  /// - Back camera for better group view
  /// - Multiple faces detected simultaneously
  /// - Compares against all enrolled students
  /// - Flash support for low light
  /// - Frame skipping enabled for performance
  /// - IoU duplicate filtering enabled

  static const bool studentModeUseBackCamera = true;
  static const bool studentModeMultiFaceDetection = true;
  static const bool studentModeFlashSupport = true;
  static const int studentModeWarmupDelayMs =
      1500; // 1.5 seconds for back camera stabilization

  /// TEACHER MODE (Single-face verification)
  /// - Front camera (selfie mode) for teacher verification
  /// - Only processes ONE face (first/largest face detected)
  /// - Compares against single teacher embedding
  /// - GPS location verification (geofencing)
  /// - Auto-submits attendance when verified
  /// - No flash needed (front camera)
  /// - Stricter threshold for security

  static const bool teacherModeUseFrontCamera = true;
  static const bool teacherModeSingleFaceOnly = true;
  static const bool teacherModeEnableGeofencing = true;
  static const bool teacherModeAutoSubmit = true;
  static const int teacherModeWarmupDelayMs =
      500; // 0.5 seconds for front camera
  static const double teacherModeThresholdBoost =
      0.10; // Add 10% to all thresholds for security

  // ===========================================================================
  // PERFORMANCE OPTIMIZATIONS
  // ===========================================================================

  /// Embedding Cache Configuration
  /// Pre-load all student embeddings to RAM for O(1) lookup
  static const bool enableEmbeddingCache = true;
  static const int cacheRefreshIntervalMinutes = 30;

  /// Frame Processing Strategy
  /// true = process every Nth frame | false = process all frames
  static const bool enableFrameSkipping = true;

  /// Duplicate Face Filtering
  /// Uses IoU (Intersection over Union) to avoid processing same face twice
  static const bool enableDuplicateFiltering = true;

  /// Quality-Based Early Exit
  /// Skip processing faces that are clearly too poor quality
  static const bool enableQualityBasedEarlyExit = true;
  static const int qualityEarlyExitThreshold = 30; // Skip if quality < 30%

  // ===========================================================================
  // PIPELINE EXECUTION PARAMETERS
  // ===========================================================================

  /// Complete Face Recognition Pipeline Timeout
  /// Maximum time for detection → recognition → spoof detection
  static const int pipelineTimeoutMs = 2000;

  /// Detection Timeout (ML Kit Face Detection)
  static const int detectionTimeoutMs = 500;

  /// Recognition Timeout (Embedding generation and matching)
  static const int recognitionTimeoutMs = 1000;

  /// Spoof Detection Timeout
  static const int spoofDetectionTimeoutMs = 500;

  /// Minimum confidence for automatic acceptance in student mode
  /// Below this confidence, manual review is recommended
  static const double autoAcceptanceThreshold = 0.75;

  // ===========================================================================
  // RECOGNITION PIPELINE FLOW
  // ===========================================================================

  /// The 3-stage pipeline:
  ///
  /// STAGE 1: Detection (ML Kit)
  /// Camera Frame (1920x1440)
  ///   ↓
  /// ML Kit Detection (ACCURATE mode)
  ///   ↓
  /// Quality Assessment
  ///   ↓
  /// IoU Duplicate Filtering
  ///
  /// STAGE 2: Recognition (FaceNet)
  /// [Quality Check]
  ///   ├─ Poor Quality → Skip
  ///   └─ Good Quality → Continue
  ///       ↓
  ///     Face Alignment
  ///       ↓
  ///     Mirror if Back Camera
  ///       ↓
  ///     FaceNet Embedding (128-dim)
  ///       ↓
  ///     Compare with Cached Embeddings
  ///       ↓
  ///     Dynamic Threshold Match
  ///
  /// STAGE 3: Anti-Spoofing (MobileFaceNet Lite)
  /// [If Match Found]
  ///   ↓
  /// Spoof Detection Analysis
  ///   ├─ Texture Analysis
  ///   ├─ Landmark Stability
  ///   ├─ Frequency Domain
  ///   ├─ Eye Reflection
  ///   └─ Motion Consistency
  ///       ↓
  ///   [Real Face] → Mark Present
  ///   [Fake Face] → Block & Warn

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Get dynamic recognition threshold based on face quality score
  /// Quality scores: 0-100 (100 = perfect quality)
  static double getDynamicThreshold(int qualityScore) {
    if (qualityScore >= goodQualityBoundary) {
      return highQualityThreshold; // 90+ quality: 60% threshold
    } else if (qualityScore >= fairQualityBoundary) {
      return goodQualityThreshold; // 75-90 quality: 70% threshold
    } else if (qualityScore >= lowQualityBoundary) {
      return fairQualityThreshold; // 60-75 quality: 80% threshold
    } else {
      return baselowQualityThreshold; // <60 quality: 90% threshold (strict)
    }
  }

  /// Get recognition threshold for teacher mode (with boost for security)
  static double getTeacherModeThreshold(int qualityScore) {
    final baseThreshold = getDynamicThreshold(qualityScore);
    return (baseThreshold + teacherModeThresholdBoost).clamp(0.0, 1.0);
  }

  /// Get warmup delay based on mode
  static int getWarmupDelay(RecognitionMode mode) {
    return mode == RecognitionMode.studentMode
        ? studentModeWarmupDelayMs
        : teacherModeWarmupDelayMs;
  }

  /// Check if should use back camera
  static bool useBackCamera(RecognitionMode mode) {
    return mode == RecognitionMode.studentMode
        ? studentModeUseBackCamera
        : !teacherModeUseFrontCamera;
  }

  /// Check if should detect multiple faces
  static bool allowMultipleFaces(RecognitionMode mode) {
    return mode == RecognitionMode.studentMode;
  }
}
