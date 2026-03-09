/// Employee Model
/// Represents an employee record from Customer API
class Employee {
  final String id;
  final String name;
  final String? employeeCode;
  final String? email;
  final String? phoneNumber;
  final String? department;
  final String? designation;
  final String? status;
  final DateTime? joinDate;
  final String? profileImagePath;
  final DateTime? createdAt;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    this.employeeCode,
    this.email,
    this.phoneNumber,
    this.department,
    this.designation,
    this.status,
    this.joinDate,
    this.profileImagePath,
    this.createdAt,
    this.isActive = true,
  });

  /// Factory constructor for creating Employee from JSON
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? json['employeeId'] ?? '',
      name: json['name'] ?? json['employeeName'] ?? '',
      employeeCode: json['employeeCode'] ?? json['employee_code'],
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      department: json['department'],
      designation: json['designation'] ?? json['role'],
      status: json['status'],
      joinDate: json['joinDate'] != null
          ? DateTime.tryParse(json['joinDate'])
          : null,
      profileImagePath:
          json['profileImagePath'] ??
          json['profile_image_path'] ??
          json['avatar'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      isActive: json['isActive'] == true || json['is_active'] == 1,
    );
  }

  /// Convert Employee to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeCode': employeeCode,
      'email': email,
      'phoneNumber': phoneNumber,
      'department': department,
      'designation': designation,
      'status': status,
      'joinDate': joinDate?.toIso8601String(),
      'profileImagePath': profileImagePath,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  String toString() =>
      'Employee(id: $id, name: $name, code: $employeeCode, dept: $department)';
}
