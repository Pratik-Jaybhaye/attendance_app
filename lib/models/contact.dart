/// Contact Model
/// Represents a contact with personal and professional information
class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? groupId;
  final String? subGroupId;
  final String? address;
  final String? profileImagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.groupId,
    this.subGroupId,
    this.address,
    this.profileImagePath,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Factory constructor for creating Contact from JSON
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? json['contactId'] ?? '',
      name: json['name'] ?? json['contactName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      email: json['email'],
      groupId: json['groupId'] ?? json['group_id'],
      subGroupId: json['subGroupId'] ?? json['sub_group_id'],
      address: json['address'],
      profileImagePath: json['profileImagePath'] ?? json['profile_image_path'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      isActive: json['isActive'] == true || json['is_active'] == 1,
    );
  }

  /// Convert Contact to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'groupId': groupId,
      'subGroupId': subGroupId,
      'address': address,
      'profileImagePath': profileImagePath,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create a copy of Contact with modified fields
  Contact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? groupId,
    String? subGroupId,
    String? address,
    String? profileImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      groupId: groupId ?? this.groupId,
      subGroupId: subGroupId ?? this.subGroupId,
      address: address ?? this.address,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'Contact(id: $id, name: $name, phone: $phoneNumber, email: $email)';
}
