import 'student.dart';

/// Class Model
/// Represents a class/section with its students
class ClassModel {
  final String id;
  final String name;
  final String grade;

  /// List of all students in this class
  final List<Student> students;

  ClassModel({
    required this.id,
    required this.name,
    required this.grade,
    this.students = const [],
  });

  /// Get count of students with face data enrolled
  int get enrolledStudentsCount {
    return students.where((s) => s.enrollmentStatus == 'enrolled').length;
  }

  /// Get count of students with pending enrollment
  int get pendingStudentsCount {
    return students.where((s) => s.enrollmentStatus == 'pending').length;
  }

  /// Get count of students without any photo
  int get noPhotoStudentsCount {
    return students.where((s) => s.enrollmentStatus == 'no_photo').length;
  }

  /// Factory constructor for creating ClassModel from JSON
  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      students:
          (json['students'] as List<dynamic>?)
              ?.map((s) => Student.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert ClassModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'students': students.map((s) => s.toJson()).toList(),
    };
  }
}
