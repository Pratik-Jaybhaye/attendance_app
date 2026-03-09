/// SubGroup Model
/// Represents a sub-category within a group
class SubGroup {
  final String id;
  final String name;
  final String? groupId;
  final String? description;
  final int? contactCount;
  final DateTime? createdAt;
  final bool isActive;

  SubGroup({
    required this.id,
    required this.name,
    this.groupId,
    this.description,
    this.contactCount,
    this.createdAt,
    this.isActive = true,
  });

  /// Factory constructor for creating SubGroup from JSON
  factory SubGroup.fromJson(Map<String, dynamic> json) {
    return SubGroup(
      id: json['id'] ?? json['subGroupId'] ?? '',
      name: json['name'] ?? json['subGroupName'] ?? '',
      groupId: json['groupId'] ?? json['group_id'],
      description: json['description'],
      contactCount: json['contactCount'] ?? json['contact_count'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      isActive: json['isActive'] == true || json['is_active'] == 1,
    );
  }

  /// Convert SubGroup to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'groupId': groupId,
      'description': description,
      'contactCount': contactCount,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  String toString() =>
      'SubGroup(id: $id, name: $name, groupId: $groupId, count: $contactCount)';
}
