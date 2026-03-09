/// ContactNotification Model
/// Represents a notification for a contact
class ContactNotification {
  final String id;
  final String contactId;
  final String? contactName;
  final String title;
  final String message;
  final String? type; // 'sms', 'email', 'attendance', etc.
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  ContactNotification({
    required this.id,
    required this.contactId,
    this.contactName,
    required this.title,
    required this.message,
    this.type,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
  });

  /// Factory constructor for creating ContactNotification from JSON
  factory ContactNotification.fromJson(Map<String, dynamic> json) {
    return ContactNotification(
      id: json['id'] ?? json['notificationId'] ?? '',
      contactId: json['contactId'] ?? json['contact_id'] ?? '',
      contactName: json['contactName'] ?? json['contact_name'],
      title: json['title'] ?? '',
      message: json['message'] ?? json['notificationMessage'] ?? '',
      type: json['type'] ?? json['notificationType'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true || json['is_read'] == 1,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
    );
  }

  /// Convert ContactNotification to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'contactName': contactName,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'ContactNotification(id: $id, contactId: $contactId, title: $title, type: $type)';
}
