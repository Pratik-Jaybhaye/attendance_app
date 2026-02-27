/// Self-Attendance Log Model
/// Represents a student's self-marked attendance with face embeddings
///
/// This model stores:
/// - Student ID and name
/// - Face embeddings (128-dimensional vector)
/// - Timestamp when attendance was marked
/// - Location data (latitude, longitude)
/// - Face quality and verification status
class SelfAttendanceLog {
  final String id; // Unique ID for this log entry
  final String studentId; // Reference to student
  final String studentName; // Student's full name
  final List<double> faceEmbedding; // 128-dimensional face vector
  final DateTime markedAt; // When attendance was marked
  final double? latitude; // Location latitude
  final double? longitude; // Location longitude
  final double? faceQualityScore; // Quality score of detected face (0-100)
  final bool
  faceVerified; // Whether face was successfully detected and verified
  final String? remarks; // Optional remarks

  SelfAttendanceLog({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.faceEmbedding,
    required this.markedAt,
    this.latitude,
    this.longitude,
    this.faceQualityScore,
    this.faceVerified = false,
    this.remarks,
  });

  /// Factory constructor for creating from JSON
  factory SelfAttendanceLog.fromJson(Map<String, dynamic> json) {
    // Parse embedding vector from string
    List<double> embedding = [];
    if (json['faceEmbedding'] is String) {
      try {
        final cleanedString = (json['faceEmbedding'] as String)
            .replaceAll('[', '')
            .replaceAll(']', '');
        final parts = cleanedString.split(',');
        embedding = parts.map((part) => double.parse(part.trim())).toList();
      } catch (e) {
        print('Error parsing embedding: $e');
      }
    } else if (json['faceEmbedding'] is List) {
      embedding = List<double>.from(json['faceEmbedding']);
    }

    return SelfAttendanceLog(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      faceEmbedding: embedding,
      markedAt: json['markedAt'] is String
          ? DateTime.parse(json['markedAt'] as String)
          : json['markedAt'] ?? DateTime.now(),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      faceQualityScore: json['faceQualityScore'] as double?,
      faceVerified: json['faceVerified'] as bool? ?? false,
      remarks: json['remarks'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'faceEmbedding': faceEmbedding,
      'markedAt': markedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'faceQualityScore': faceQualityScore,
      'faceVerified': faceVerified,
      'remarks': remarks,
    };
  }
}
