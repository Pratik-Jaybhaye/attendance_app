/// Group Model
/// Represents a contact group/category
class Group {
  final String id;
  final String name;
  final String? description;
  final int? contactCount;
  final DateTime? createdAt;
  final bool isActive;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.contactCount,
    this.createdAt,
    this.isActive = true,
  });

  /// Factory constructor for creating Group from JSON
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? json['groupId'] ?? '',
      name: json['name'] ?? json['groupName'] ?? '',
      description: json['description'],
      contactCount: json['contactCount'] ?? json['contact_count'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      isActive: json['isActive'] == true || json['is_active'] == 1,
    );
  }

  /// Convert Group to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'contactCount': contactCount,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  String toString() => 'Group(id: $id, name: $name, count: $contactCount)';
}
