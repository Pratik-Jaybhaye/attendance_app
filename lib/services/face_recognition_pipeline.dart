import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_detection_service.dart';
import 'face_recognition_service.dart';
import 'anti_spoofing_service.dart';
import 'face_recognition_config.dart';

/// Face Recognition Pipeline Result
/// Complete recognition output from the 3-stage pipeline
class RecognitionPipelineResult {
  final bool isDetected; // Stage 1: Face detected?
  final bool isQualityGood; // Stage 1: Quality check passed?
  final bool isRecognized; // Stage 2: Face matched in database?
  final bool isRealFace; // Stage 3: Passed anti-spoofing?

  final String? studentId; // Matched student ID
  final String? studentName; // Matched student name
  final double detectionConfidence; // Stage 1 confidence
  final int faceQualityScore; // Stage 1 quality (0-100)
  final double recognitionConfidence; // Stage 2 confidence
  final double spoofScore; // Stage 3 spoof score (0-1)

  final String message; // User-friendly status message
  final String status; // Status: DETECTED, RECOGNIZED, BLOCKED, etc.

  final Map<String, dynamic>? detectionData; // Raw detection data
  final Map<String, dynamic>? recognitionData; // Raw recognition data
  final Map<String, dynamic>? spoofingData; // Raw spoofing data

  RecognitionPipelineResult({
    required this.isDetected,
    required this.isQualityGood,
    required this.isRecognized,
    required this.isRealFace,
    this.studentId,
    this.studentName,
    required this.detectionConfidence,
    required this.faceQualityScore,
    required this.recognitionConfidence,
    required this.spoofScore,
    required this.message,
    required this.status,
    this.detectionData,
    this.recognitionData,
    this.spoofingData,
  });

  /// Check if attendance can be marked
  bool get canMarkAttendance =>
      isDetected && isQualityGood && isRecognized && isRealFace;

  /// Get status emoji for UI display
  String get statusEmoji {
    switch (status) {
      case 'RECOGNIZED':
        return '✓'; // Green checkmark
      case 'DETECTED_ONLY':
        return '⚠'; // Warning (detected but not recognized)
      case 'SPOOFED':
        return '✗'; // Red X (fake face detected)
      case 'LOW_QUALITY':
        return '📷'; // Camera (rescan needed)
      case 'NO_FACE':
        return '○'; // Circle (no face detected)
      default:
        return '?';
    }
  }
}

/// Face Recognition Pipeline
/// Orchestrates the 3-stage pipeline: Detection → Recognition → Anti-Spoofing
///
/// HIGH-LEVEL FLOW:
/// Camera Frame (1920x1440)
///     ↓
/// STAGE 1: ML Kit Detection (ACCURATE mode)
///     ↓
/// Detected Faces + Quality Check
///     ↓
/// [Poor Quality] → Skip     [Good Quality] → Continue
///                                 ↓
///                         Face Alignment & Normalization
///                                 ↓
///                         STAGE 2: FaceNet Embedding
///                                 ↓
///                         Compare with Database
///                                 ↓
///               [Match > Threshold] → STAGE 3: Spoof Detection
///                                       ↓
///                       [Real Face] → Mark Present
///                       [Fake Face] → Block & Warn
class FaceRecognitionPipeline {
  final FaceDetectionService _detectionService;
  final FaceRecognitionService _recognitionService;
  final AntiSpoofingService _antiSpoofingService;

  /// Frame counter for frame skipping optimization
  int _frameCounter = 0;

  /// Recognition mode (student or teacher)
  RecognitionMode _recognitionMode = RecognitionMode.studentMode;

  FaceRecognitionPipeline({
    FaceDetectionService? detectionService,
    FaceRecognitionService? recognitionService,
    AntiSpoofingService? antiSpoofingService,
  }) : _detectionService = detectionService ?? FaceDetectionService(),
       _recognitionService = recognitionService ?? FaceRecognitionService(),
       _antiSpoofingService = antiSpoofingService ?? AntiSpoofingService();

  /// Set recognition mode (student or teacher)
  void setRecognitionMode(RecognitionMode mode) {
    _recognitionMode = mode;
  }

  /// Process a single frame through the complete 3-stage pipeline
  /// Returns detailed recognition result with all stage outputs
  Future<RecognitionPipelineResult> processFrame(
    InputImage inputImage, {
    List<int>? imagePixels,
    int imageWidth = 1920,
    int imageHeight = 1440,
  }) async {
    try {
      // =====================================================================
      // STAGE 1: FACE DETECTION (ML Kit)
      // =====================================================================

      // Frame skipping optimization: process every 2nd frame
      _frameCounter++;
      final shouldProcess =
          _frameCounter % FaceRecognitionConfig.frameSkipInterval == 0;

      if (!shouldProcess) {
        return RecognitionPipelineResult(
          isDetected: false,
          isQualityGood: false,
          isRecognized: false,
          isRealFace: false,
          detectionConfidence: 0.0,
          faceQualityScore: 0,
          recognitionConfidence: 0.0,
          spoofScore: 0.0,
          message: 'Frame skipped for performance optimization',
          status: 'SKIPPED',
        );
      }

      print('[Pipeline] STAGE 1: Detecting faces...');
      final detectedFaces = await _detectionService.detectFaces(inputImage);

      if (detectedFaces.isEmpty) {
        return RecognitionPipelineResult(
          isDetected: false,
          isQualityGood: false,
          isRecognized: false,
          isRealFace: false,
          detectionConfidence: 0.0,
          faceQualityScore: 0,
          recognitionConfidence: 0.0,
          spoofScore: 0.0,
          message: 'No face detected in frame',
          status: 'NO_FACE',
        );
      }

      print('[Pipeline] Stage 1: Detected ${detectedFaces.length} face(s)');

      // Apply duplicate filtering (IoU threshold)
      final filteredFaces = FaceRecognitionConfig.enableDuplicateFiltering
          ? _detectionService.filterDuplicateFaces(
              detectedFaces,
              iouThreshold: FaceRecognitionConfig.iouThresholdForDuplicates,
            )
          : detectedFaces;

      print(
        '[Pipeline] Stage 1: After duplicate filter: ${filteredFaces.length} face(s)',
      );

      // In teacher mode, process only the largest/first face
      final facesToProcess = _recognitionMode == RecognitionMode.teacherMode
          ? [filteredFaces.first] // Single face only
          : filteredFaces; // Multiple faces allowed in student mode

      // Get first face for processing (or largest if multiple)
      var bestFace = facesToProcess.first;
      final bestFaceData = detectedFaces.firstWhere(
        (face) => face['face'] == bestFace,
      );

      final faceQualityScore =
          (bestFaceData['quality'] as FaceQualityScore).qualityPercentage;
      final detectionConfidence = bestFaceData['confidence'] as double;

      print(
        '[Pipeline] Stage 1: Face Quality: $faceQualityScore%, Confidence: ${(detectionConfidence * 100).toStringAsFixed(1)}%',
      );

      // Quality-based early exit
      if (FaceRecognitionConfig.enableQualityBasedEarlyExit &&
          faceQualityScore < FaceRecognitionConfig.qualityEarlyExitThreshold) {
        return RecognitionPipelineResult(
          isDetected: true,
          isQualityGood: false,
          isRecognized: false,
          isRealFace: false,
          detectionConfidence: detectionConfidence,
          faceQualityScore: faceQualityScore,
          recognitionConfidence: 0.0,
          spoofScore: 0.0,
          message:
              'Face quality too low. Please ensure good lighting and clear face.',
          status: 'LOW_QUALITY',
          detectionData: bestFaceData,
        );
      }

      // =====================================================================
      // STAGE 2: FACE RECOGNITION (FaceNet)
      // =====================================================================

      print('[Pipeline] STAGE 2: Recognizing face...');

      // Generate or retrieve face embedding
      // TODO: Generate embedding from face image using FaceNet model
      // For now using mock embedding
      final faceEmbedding = _recognitionService.generateMockEmbedding();

      // Get dynamic threshold based on face quality
      final recognitionThreshold =
          _recognitionMode == RecognitionMode.teacherMode
          ? FaceRecognitionConfig.getTeacherModeThreshold(faceQualityScore)
          : FaceRecognitionConfig.getDynamicThreshold(faceQualityScore);

      print(
        '[Pipeline] Stage 2: Recognition threshold: ${(recognitionThreshold * 100).toStringAsFixed(0)}%',
      );

      final recognitionResult = _recognitionService.recognizeFace(
        faceEmbedding,
        confidenceThreshold: recognitionThreshold,
        topMatches: FaceRecognitionConfig.topMatchesCount,
      );

      final isRecognized = recognitionResult['matched'] as bool;
      final topMatch = recognitionResult['topMatch'] as Map<String, dynamic>?;
      final recognitionConfidence = topMatch?['confidence'] as double? ?? 0.0;

      if (!isRecognized) {
        return RecognitionPipelineResult(
          isDetected: true,
          isQualityGood: true,
          isRecognized: false,
          isRealFace: false,
          detectionConfidence: detectionConfidence,
          faceQualityScore: faceQualityScore,
          recognitionConfidence: 0.0,
          spoofScore: 0.0,
          message: 'Face not recognized in student database',
          status: 'DETECTED_ONLY',
          detectionData: bestFaceData,
          recognitionData: recognitionResult,
        );
      }

      print(
        '[Pipeline] Stage 2: Face recognized! Student: ${topMatch?['studentName']}, Confidence: ${(recognitionConfidence * 100).toStringAsFixed(1)}%',
      );

      // =====================================================================
      // STAGE 3: ANTI-SPOOFING (MobileFaceNet Lite)
      // =====================================================================

      print('[Pipeline] STAGE 3: Checking for spoofed faces...');

      if (!FaceRecognitionConfig.enableAntiSpoofing) {
        // Anti-spoofing disabled, mark as real face
        return RecognitionPipelineResult(
          isDetected: true,
          isQualityGood: true,
          isRecognized: true,
          isRealFace: true,
          detectionConfidence: detectionConfidence,
          faceQualityScore: faceQualityScore,
          recognitionConfidence: recognitionConfidence,
          spoofScore: 0.0,
          message:
              'Student ${topMatch?['studentName']} recognized ✓ (Anti-spoofing disabled)',
          status: 'RECOGNIZED',
          detectionData: bestFaceData,
          recognitionData: recognitionResult,
        );
      }

      // Run spoof detection
      final spoofResult = _antiSpoofingService.detectSpoof(
        bestFace['face'] as Face,
        imagePixels: imagePixels ?? [],
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );

      final isSpoofed = spoofResult['isSpoofed'] as bool;
      final spoofScore = spoofResult['spoofScore'] as double;
      final riskLevel = spoofResult['riskLevel'] as String;

      print(
        '[Pipeline] Stage 3: Spoof Score: ${(spoofScore * 100).toStringAsFixed(1)}% ($riskLevel)',
      );

      if (isSpoofed) {
        return RecognitionPipelineResult(
          isDetected: true,
          isQualityGood: true,
          isRecognized: true,
          isRealFace: false,
          detectionConfidence: detectionConfidence,
          faceQualityScore: faceQualityScore,
          recognitionConfidence: recognitionConfidence,
          spoofScore: spoofScore,
          message:
              '⚠️ SPOOFED FACE DETECTED! This appears to be a fake/printed face. Please use your actual face.',
          status: 'SPOOFED',
          detectionData: bestFaceData,
          recognitionData: recognitionResult,
          spoofingData: spoofResult,
        );
      }

      // =====================================================================
      // SUCCESS: All stages passed!
      // =====================================================================

      print('[Pipeline] ✓ ALL STAGES PASSED - Attendance can be marked!');

      return RecognitionPipelineResult(
        isDetected: true,
        isQualityGood: true,
        isRecognized: true,
        isRealFace: true,
        studentId: topMatch?['studentId'] as String?,
        studentName: topMatch?['studentName'] as String?,
        detectionConfidence: detectionConfidence,
        faceQualityScore: faceQualityScore,
        recognitionConfidence: recognitionConfidence,
        spoofScore: spoofScore,
        message:
            '✓ ${topMatch?['studentName']} verified as present (Confidence: ${(recognitionConfidence * 100).toStringAsFixed(0)}%)',
        status: 'RECOGNIZED',
        detectionData: bestFaceData,
        recognitionData: recognitionResult,
        spoofingData: spoofResult,
      );
    } catch (e) {
      print('[Pipeline] ERROR: $e');
      return RecognitionPipelineResult(
        isDetected: false,
        isQualityGood: false,
        isRecognized: false,
        isRealFace: false,
        detectionConfidence: 0.0,
        faceQualityScore: 0,
        recognitionConfidence: 0.0,
        spoofScore: 0.0,
        message: 'Error processing frame: $e',
        status: 'ERROR',
      );
    }
  }

  /// Preload all student embeddings for fast recognition
  /// Call this before starting camera/live detection
  Future<void> preloadEmbeddings(List<String> studentIds) async {
    print(
      '[Pipeline] Preloading embeddings for ${studentIds.length} students...',
    );
    await _recognitionService.loadStudentEmbeddings(studentIds);
    final stats = _recognitionService.getCacheStats();
    print(
      '[Pipeline] Cache loaded: ${stats['cachedStudents']} students, ${stats['totalEmbeddings']} embeddings',
    );
  }

  /// Clear all caches (call on app exit)
  void dispose() {
    _detectionService.dispose();
    _recognitionService.clearCache();
  }
}
