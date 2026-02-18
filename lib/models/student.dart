/// Student Model
/// Represents a student with enrollment status and face detection data
class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String? profileImagePath;

  /// Number of photos enrolled for face detection
  final int enrolledPhotosCount;

  /// Status of face enrollment
  /// - "enrolled" - Face data successfully enrolled
  /// - "pending" - Face enrollment in progress
  /// - "no_photo" - No photo uploaded yet
  final String enrollmentStatus;

  /// Whether this student is marked present in current attendance
  bool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.profileImagePath,
    this.enrolledPhotosCount = 0,
    this.enrollmentStatus = 'no_photo',
    this.isPresent = false,
  });

  /// Factory constructor for creating Student from JSON (for API responses)
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      profileImagePath: json['profileImagePath'],
      enrolledPhotosCount: json['enrolledPhotosCount'] ?? 0,
      enrollmentStatus: json['enrollmentStatus'] ?? 'no_photo',
      isPresent: json['isPresent'] ?? false,
    );
  }

  /// Convert Student to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
      'profileImagePath': profileImagePath,
      'enrolledPhotosCount': enrolledPhotosCount,
      'enrollmentStatus': enrollmentStatus,
      'isPresent': isPresent,
    };
  }
}
