/// Attendance Record Model
/// Represents attendance data for a class on a specific date/period
class AttendanceRecord {
  final String id;
  final String classId;
  final String periodId;
  final DateTime dateTime;

  /// Map of student ID to attendance status (true = present, false = absent)
  final Map<String, bool> studentAttendance;

  /// Optional remarks for the attendance session
  final String remarks;

  /// Whether this record has been submitted/synced to backend
  bool isSubmitted;

  AttendanceRecord({
    required this.id,
    required this.classId,
    required this.periodId,
    required this.dateTime,
    this.studentAttendance = const {},
    this.remarks = '',
    this.isSubmitted = false,
  });

  /// Get count of students marked present
  int get presentCount {
    return studentAttendance.values.where((isPresent) => isPresent).length;
  }

  /// Get count of students marked absent
  int get absentCount {
    return studentAttendance.values.where((isPresent) => !isPresent).length;
  }

  /// Factory constructor for creating AttendanceRecord from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      classId: json['classId'] ?? '',
      periodId: json['periodId'] ?? '',
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toString()),
      studentAttendance: Map<String, bool>.from(
        json['studentAttendance'] ?? {},
      ),
      remarks: json['remarks'] ?? '',
      isSubmitted: json['isSubmitted'] ?? false,
    );
  }

  /// Convert AttendanceRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'periodId': periodId,
      'dateTime': dateTime.toIso8601String(),
      'studentAttendance': studentAttendance,
      'remarks': remarks,
      'isSubmitted': isSubmitted,
    };
  }
}
