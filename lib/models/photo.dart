/// Photo Model
/// Represents a student photo with metadata
class Photo {
  final String id;
  final String studentId;
  final String localPath; // Local file path on device
  final String? cloudPath; // Path in cloud/backend (after upload)
  final String? uploadId; // ID returned by backend after upload
  final DateTime capturedAt;
  final DateTime? uploadedAt;
  final String? photoQuality; // 'good', 'fair', 'poor'
  final int? faceDetectionScore; // 0-100, confidence of face detection
  final bool? isLiveImage; // Anti-spoofing check result
  final String? embeddingId; // ID of generated embeddings
  final bool? isProcessed; // Whether embeddings been processed
  final String?
  processingStatus; // 'pending', 'processing', 'completed', 'failed'

  Photo({
    required this.id,
    required this.studentId,
    required this.localPath,
    this.cloudPath,
    this.uploadId,
    required this.capturedAt,
    this.uploadedAt,
    this.photoQuality,
    this.faceDetectionScore,
    this.isLiveImage,
    this.embeddingId,
    this.isProcessed = false,
    this.processingStatus = 'pending',
  });

  /// Create Photo from JSON (for API responses)
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      localPath: json['local_path'] ?? '',
      cloudPath: json['cloud_path'],
      uploadId: json['upload_id'],
      capturedAt: DateTime.parse(
        json['captured_at'] ?? DateTime.now().toIso8601String(),
      ),
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : null,
      photoQuality: json['photo_quality'],
      faceDetectionScore: json['face_detection_score'],
      isLiveImage: json['is_live_image'],
      embeddingId: json['embedding_id'],
      isProcessed: json['is_processed'] ?? false,
      processingStatus: json['processing_status'] ?? 'pending',
    );
  }

  /// Convert Photo to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'local_path': localPath,
      'cloud_path': cloudPath,
      'upload_id': uploadId,
      'captured_at': capturedAt.toIso8601String(),
      'uploaded_at': uploadedAt?.toIso8601String(),
      'photo_quality': photoQuality,
      'face_detection_score': faceDetectionScore,
      'is_live_image': isLiveImage,
      'embedding_id': embeddingId,
      'is_processed': isProcessed,
      'processing_status': processingStatus,
    };
  }

  /// Create a copy with modified fields
  Photo copyWith({
    String? id,
    String? studentId,
    String? localPath,
    String? cloudPath,
    String? uploadId,
    DateTime? capturedAt,
    DateTime? uploadedAt,
    String? photoQuality,
    int? faceDetectionScore,
    bool? isLiveImage,
    String? embeddingId,
    bool? isProcessed,
    String? processingStatus,
  }) {
    return Photo(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      localPath: localPath ?? this.localPath,
      cloudPath: cloudPath ?? this.cloudPath,
      uploadId: uploadId ?? this.uploadId,
      capturedAt: capturedAt ?? this.capturedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      photoQuality: photoQuality ?? this.photoQuality,
      faceDetectionScore: faceDetectionScore ?? this.faceDetectionScore,
      isLiveImage: isLiveImage ?? this.isLiveImage,
      embeddingId: embeddingId ?? this.embeddingId,
      isProcessed: isProcessed ?? this.isProcessed,
      processingStatus: processingStatus ?? this.processingStatus,
    );
  }
}

/// Photo Upload Response Model
/// Represents the response from backend after photo upload
class PhotoUploadResponse {
  final String uploadId;
  final String studentId;
  final String cloudPath;
  final DateTime uploadedAt;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  PhotoUploadResponse({
    required this.uploadId,
    required this.studentId,
    required this.cloudPath,
    required this.uploadedAt,
    required this.success,
    this.errorMessage,
    this.metadata,
  });

  /// Create from JSON response
  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json) {
    return PhotoUploadResponse(
      uploadId: json['upload_id'] ?? '',
      studentId: json['student_id'] ?? '',
      cloudPath: json['cloud_path'] ?? '',
      uploadedAt: DateTime.parse(
        json['uploaded_at'] ?? DateTime.now().toIso8601String(),
      ),
      success: json['success'] ?? true,
      errorMessage: json['error_message'],
      metadata: json['metadata'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'upload_id': uploadId,
      'student_id': studentId,
      'cloud_path': cloudPath,
      'uploaded_at': uploadedAt.toIso8601String(),
      'success': success,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }
}

/// Embedding Response Model
/// Represents face embeddings response from backend
class EmbeddingResponse {
  final String embeddingId;
  final String studentId;
  final String uploadId;
  final List<double>? embeddingVector; // 128-dimensional face vector
  final int faceDetectionScore; // 0-100
  final String photoQuality; // 'good', 'fair', 'poor'
  final bool isLiveImage; // Anti-spoofing verification
  final String processingStatus; // 'completed', 'failed'
  final String? errorMessage;
  final DateTime processedAt;

  EmbeddingResponse({
    required this.embeddingId,
    required this.studentId,
    required this.uploadId,
    this.embeddingVector,
    required this.faceDetectionScore,
    required this.photoQuality,
    required this.isLiveImage,
    required this.processingStatus,
    this.errorMessage,
    required this.processedAt,
  });

  /// Create from JSON response
  factory EmbeddingResponse.fromJson(Map<String, dynamic> json) {
    // Parse embedding vector if present
    List<double>? embedding;
    if (json['embedding_vector'] != null) {
      embedding = List<double>.from(
        (json['embedding_vector'] as List).map((x) => (x as num).toDouble()),
      );
    }

    return EmbeddingResponse(
      embeddingId: json['embedding_id'] ?? '',
      studentId: json['student_id'] ?? '',
      uploadId: json['upload_id'] ?? '',
      embeddingVector: embedding,
      faceDetectionScore: json['face_detection_score'] ?? 0,
      photoQuality: json['photo_quality'] ?? 'unknown',
      isLiveImage: json['is_live_image'] ?? false,
      processingStatus: json['processing_status'] ?? 'pending',
      errorMessage: json['error_message'],
      processedAt: DateTime.parse(
        json['processed_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'embedding_id': embeddingId,
      'student_id': studentId,
      'upload_id': uploadId,
      'embedding_vector': embeddingVector,
      'face_detection_score': faceDetectionScore,
      'photo_quality': photoQuality,
      'is_live_image': isLiveImage,
      'processing_status': processingStatus,
      'error_message': errorMessage,
      'processed_at': processedAt.toIso8601String(),
    };
  }
}

/// Face Verification Result Model
/// Represents the result of face verification during attendance
class FaceVerificationResult {
  final String verificationId;
  final String studentId;
  final String matchedEmbeddingId;
  final double matchScore; // 0.0 to 1.0, higher is more similar
  final String verificationStatus; // 'matched', 'not_matched', 'unknown_face'
  final DateTime verifiedAt;
  final String? detailedMessage;

  FaceVerificationResult({
    required this.verificationId,
    required this.studentId,
    required this.matchedEmbeddingId,
    required this.matchScore,
    required this.verificationStatus,
    required this.verifiedAt,
    this.detailedMessage,
  });

  /// Create from JSON
  factory FaceVerificationResult.fromJson(Map<String, dynamic> json) {
    return FaceVerificationResult(
      verificationId: json['verification_id'] ?? '',
      studentId: json['student_id'] ?? '',
      matchedEmbeddingId: json['matched_embedding_id'] ?? '',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      verificationStatus: json['verification_status'] ?? 'unknown',
      verifiedAt: DateTime.parse(
        json['verified_at'] ?? DateTime.now().toIso8601String(),
      ),
      detailedMessage: json['detailed_message'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'verification_id': verificationId,
      'student_id': studentId,
      'matched_embedding_id': matchedEmbeddingId,
      'match_score': matchScore,
      'verification_status': verificationStatus,
      'verified_at': verifiedAt.toIso8601String(),
      'detailed_message': detailedMessage,
    };
  }

  /// Check if verification was successful
  bool get isVerified => verificationStatus == 'matched' && matchScore >= 0.6;
}
