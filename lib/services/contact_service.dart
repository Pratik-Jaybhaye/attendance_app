/// ContactService handles contact-related API operations
/// Provides methods for managing contacts, groups, and notifications
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import '../models/group.dart';
import '../models/sub_group.dart';
import '../models/contact_notification.dart';
import '../models/otp_response.dart';

class ContactService {
  // TODO: Replace with your actual API base URL
  static const String apiBaseUrl = 'https://attendanceapi.acculekhaa.com';

  // ==================== GROUPS ====================

  /// Get all contact groups
  /// API Endpoint: POST /api/Contact/GetAllGroups
  /// Returns: List of Group objects or empty list on error
  static Future<List<Group>> getAllGroups({String? token}) async {
    try {
      print('ContactService: Fetching all groups');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Contact/GetAllGroups'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response formats
        List<dynamic> groupsList = [];
        if (data is Map) {
          groupsList = data['data'] ?? data['groups'] ?? data['result'] ?? [];
        } else if (data is List) {
          groupsList = data;
        }

        final groups = groupsList.map((g) => Group.fromJson(g)).toList();
        print('ContactService: Fetched ${groups.length} groups');
        return groups;
      } else {
        print('ContactService: Error fetching groups - ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('ContactService: Exception fetching groups - $e');
      return [];
    }
  }

  // ==================== SUB GROUPS ====================

  /// Get all sub-groups (optionally filtered by group ID)
  /// API Endpoint: POST /api/Contact/GetAllSubGroups
  /// Returns: List of SubGroup objects or empty list on error
  static Future<List<SubGroup>> getAllSubGroups({
    String? groupId,
    String? token,
  }) async {
    try {
      print('ContactService: Fetching all sub-groups');

      final body = {};
      if (groupId != null) {
        body['groupId'] = groupId;
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Contact/GetAllSubGroups'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> subGroupsList = [];
        if (data is Map) {
          subGroupsList =
              data['data'] ?? data['subGroups'] ?? data['result'] ?? [];
        } else if (data is List) {
          subGroupsList = data;
        }

        final subGroups = subGroupsList
            .map((sg) => SubGroup.fromJson(sg))
            .toList();
        print('ContactService: Fetched ${subGroups.length} sub-groups');
        return subGroups;
      } else {
        print(
          'ContactService: Error fetching sub-groups - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('ContactService: Exception fetching sub-groups - $e');
      return [];
    }
  }

  // ==================== GET CONTACTS ====================

  /// Get all contacts (optionally filtered by group or sub-group)
  /// API Endpoint: POST /api/Contact/GetContacts
  /// Returns: List of Contact objects or empty list on error
  static Future<List<Contact>> getContacts({
    String? groupId,
    String? subGroupId,
    int? limit,
    int? offset,
    String? token,
  }) async {
    try {
      print('ContactService: Fetching contacts');

      final body = {};
      if (groupId != null) body['groupId'] = groupId;
      if (subGroupId != null) body['subGroupId'] = subGroupId;
      if (limit != null) body['limit'] = limit;
      if (offset != null) body['offset'] = offset;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Contact/GetContacts'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> contactsList = [];
        if (data is Map) {
          contactsList =
              data['data'] ?? data['contacts'] ?? data['result'] ?? [];
        } else if (data is List) {
          contactsList = data;
        }

        final contacts = contactsList.map((c) => Contact.fromJson(c)).toList();
        print('ContactService: Fetched ${contacts.length} contacts');
        return contacts;
      } else {
        print(
          'ContactService: Error fetching contacts - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('ContactService: Exception fetching contacts - $e');
      return [];
    }
  }

  // ==================== ADD CONTACT ====================

  /// Add a new contact
  /// API Endpoint: POST /api/Contact/AddContact
  /// Parameters:
  ///   - name: Contact name (required)
  ///   - phoneNumber: Contact phone (required)
  ///   - email: Contact email (optional)
  ///   - groupId: Group ID (optional)
  ///   - subGroupId: Sub-group ID (optional)
  ///   - address: Contact address (optional)
  /// Returns: Contact object if successful, null otherwise
  static Future<Contact?> addContact({
    required String name,
    required String phoneNumber,
    String? email,
    String? groupId,
    String? subGroupId,
    String? address,
    String? token,
  }) async {
    try {
      print('ContactService: Adding new contact - $name');

      final body = {
        'name': name,
        'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (groupId != null) 'groupId': groupId,
        if (subGroupId != null) 'subGroupId': subGroupId,
        if (address != null) 'address': address,
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Contact/AddContact'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        Contact? contact;
        if (data is Map) {
          contact = Contact.fromJson(data['data'] ?? data);
        }

        if (contact != null) {
          print('ContactService: Contact added successfully - $name');
          return contact;
        }
      } else {
        print('ContactService: Error adding contact - ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('ContactService: Exception adding contact - $e');
      return null;
    }
  }

  // ==================== UPDATE CONTACT ====================

  /// Update an existing contact
  /// API Endpoint: POST /api/Contact/UpdateContact
  /// Parameters:
  ///   - id: Contact ID (required)
  ///   - name: Contact name (optional)
  ///   - phoneNumber: Contact phone (optional)
  ///   - email: Contact email (optional)
  ///   - groupId: Group ID (optional)
  ///   - subGroupId: Sub-group ID (optional)
  ///   - address: Contact address (optional)
  /// Returns: Contact object if successful, null otherwise
  static Future<Contact?> updateContact({
    required String id,
    String? name,
    String? phoneNumber,
    String? email,
    String? groupId,
    String? subGroupId,
    String? address,
    String? token,
  }) async {
    try {
      print('ContactService: Updating contact - $id');

      final body = {
        'id': id,
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (email != null) 'email': email,
        if (groupId != null) 'groupId': groupId,
        if (subGroupId != null) 'subGroupId': subGroupId,
        if (address != null) 'address': address,
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Contact/UpdateContact'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Contact? contact;
        if (data is Map) {
          contact = Contact.fromJson(data['data'] ?? data);
        }

        if (contact != null) {
          print('ContactService: Contact updated successfully - $id');
          return contact;
        }
      } else {
        print(
          'ContactService: Error updating contact - ${response.statusCode}',
        );
      }
      return null;
    } catch (e) {
      print('ContactService: Exception updating contact - $e');
      return null;
    }
  }

  // ==================== MARK ATTENDANCE ====================

  /// Mark attendance for a contact
  /// API Endpoint: POST /api/Contact/MarkAttendance
  /// Parameters:
  ///   - contactId: Contact ID (required)
  ///   - latitude: Location latitude (optional)
  ///   - longitude: Location longitude (optional)
  ///   - faceVerified: Whether face was verified (optional)
  /// Returns: true if successful, false otherwise
  static Future<bool> markAttendance({
    required String contactId,
    double? latitude,
    double? longitude,
    bool? faceVerified,
    String? token,
  }) async {
    try {
      print('ContactService: Marking attendance for contact - $contactId');

      final body = {
        'contactId': contactId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (faceVerified != null) 'faceVerified': faceVerified,
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Contact/MarkAttendance'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] ?? data['isSuccess'] ?? false;

        if (success) {
          print('ContactService: Attendance marked successfully - $contactId');
        }
        return success;
      } else {
        print(
          'ContactService: Error marking attendance - ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('ContactService: Exception marking attendance - $e');
      return false;
    }
  }

  // ==================== GET CONTACT DETAILS ====================

  /// Get detailed information about a specific contact
  /// API Endpoint: POST /api/Contact/GetContactDetails
  /// Parameters:
  ///   - contactId: Contact ID (required)
  /// Returns: Contact object if successful, null otherwise
  static Future<Contact?> getContactDetails({
    required String contactId,
    String? token,
  }) async {
    try {
      print('ContactService: Fetching contact details - $contactId');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Contact/GetContactDetails'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'contactId': contactId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Contact? contact;
        if (data is Map) {
          contact = Contact.fromJson(data['data'] ?? data);
        }

        if (contact != null) {
          print('ContactService: Fetched contact details - $contactId');
          return contact;
        }
      } else {
        print(
          'ContactService: Error fetching contact details - ${response.statusCode}',
        );
      }
      return null;
    } catch (e) {
      print('ContactService: Exception fetching contact details - $e');
      return null;
    }
  }

  // ==================== GET CONTACT NOTIFICATIONS ====================

  /// Get notifications for a specific contact
  /// API Endpoint: POST /api/Contact/GetContactNotifications
  /// Parameters:
  ///   - contactId: Contact ID (required)
  /// Returns: List of ContactNotification objects
  static Future<List<ContactNotification>> getContactNotifications({
    required String contactId,
    String? token,
  }) async {
    try {
      print('ContactService: Fetching notifications for contact - $contactId');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Contact/GetContactNotifications'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'contactId': contactId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> notificationsList = [];
        if (data is Map) {
          notificationsList =
              data['data'] ?? data['notifications'] ?? data['result'] ?? [];
        } else if (data is List) {
          notificationsList = data;
        }

        final notifications = notificationsList
            .map((n) => ContactNotification.fromJson(n))
            .toList();
        print(
          'ContactService: Fetched ${notifications.length} notifications for contact - $contactId',
        );
        return notifications;
      } else {
        print(
          'ContactService: Error fetching notifications - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('ContactService: Exception fetching notifications - $e');
      return [];
    }
  }

  // ==================== SEARCH CONTACT ====================

  /// Search contacts by name
  /// API Endpoint: GET /api/Contact/SearchCName
  /// Parameters:
  ///   - query: Search query (contact name)
  /// Returns: List of Contact objects matching the search
  static Future<List<Contact>> searchContacts({
    required String query,
    String? token,
  }) async {
    try {
      print('ContactService: Searching contacts - $query');

      final uri = Uri.parse(
        '$apiBaseUrl/api/Contact/SearchCName',
      ).replace(queryParameters: {'query': query});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> contactsList = [];
        if (data is Map) {
          contactsList =
              data['data'] ?? data['contacts'] ?? data['result'] ?? [];
        } else if (data is List) {
          contactsList = data;
        }

        final contacts = contactsList.map((c) => Contact.fromJson(c)).toList();
        print('ContactService: Found ${contacts.length} contacts for - $query');
        return contacts;
      } else {
        print(
          'ContactService: Error searching contacts - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('ContactService: Exception searching contacts - $e');
      return [];
    }
  }

  // ==================== SMS OPERATIONS ====================

  /// Send SMS reset code to phone number
  /// API Endpoint: GET /api/Contact/SendResetSMSByPhoneNo
  /// Parameters:
  ///   - phoneNumber: Phone number to send SMS to
  /// Returns: true if SMS sent successfully
  static Future<bool> sendResetSmsByPhoneNo({
    required String phoneNumber,
    String? token,
  }) async {
    try {
      print('ContactService: Sending reset SMS - $phoneNumber');

      final uri = Uri.parse(
        '$apiBaseUrl/api/Contact/SendResetSMSByPhoneNo',
      ).replace(queryParameters: {'phoneNumber': phoneNumber});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] ?? data['isSuccess'] ?? false;

        if (success) {
          print('ContactService: Reset SMS sent successfully - $phoneNumber');
        }
        return success;
      } else {
        print('ContactService: Error sending SMS - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('ContactService: Exception sending SMS - $e');
      return false;
    }
  }

  // ==================== OTP OPERATIONS ====================

  /// Update OTP attempt count for phone number
  /// API Endpoint: GET /api/Contact/UpdateOTPAttemptByPhoneNo
  /// Parameters:
  ///   - phoneNumber: Phone number
  /// Returns: OtpResponse with updated attempt count
  static Future<OtpResponse?> updateOtpAttemptByPhoneNo({
    required String phoneNumber,
    String? token,
  }) async {
    try {
      print('ContactService: Updating OTP attempt - $phoneNumber');

      final uri = Uri.parse(
        '$apiBaseUrl/api/Contact/UpdateOTPAttemptByPhoneNo',
      ).replace(queryParameters: {'phoneNumber': phoneNumber});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final otpResponse = OtpResponse.fromJson(data);
        print('ContactService: OTP attempt updated - $phoneNumber');
        return otpResponse;
      } else {
        print(
          'ContactService: Error updating OTP attempt - ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('ContactService: Exception updating OTP attempt - $e');
      return null;
    }
  }

  /// Update OTP confirmation status for phone number
  /// API Endpoint: GET /api/Contact/UpdateOTPConfirmationByPhoneNo
  /// Parameters:
  ///   - phoneNumber: Phone number
  ///   - otp: OTP code (optional, for verification)
  /// Returns: OtpResponse with confirmation status
  static Future<OtpResponse?> updateOtpConfirmationByPhoneNo({
    required String phoneNumber,
    String? otp,
    String? token,
  }) async {
    try {
      print('ContactService: Updating OTP confirmation - $phoneNumber');

      final queryParams = {'phoneNumber': phoneNumber};
      if (otp != null) queryParams['otp'] = otp;

      final uri = Uri.parse(
        '$apiBaseUrl/api/Contact/UpdateOTPConfirmationByPhoneNo',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final otpResponse = OtpResponse.fromJson(data);
        print('ContactService: OTP confirmation updated - $phoneNumber');
        return otpResponse;
      } else {
        print(
          'ContactService: Error updating OTP confirmation - ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('ContactService: Exception updating OTP confirmation - $e');
      return null;
    }
  }

  /// Get OTP by phone number
  /// API Endpoint: GET /api/Contact/GetOTPByPhoneNO
  /// Parameters:
  ///   - phoneNumber: Phone number
  /// Returns: OtpResponse with OTP details (null if not found)
  static Future<OtpResponse?> getOtpByPhoneNo({
    required String phoneNumber,
    String? token,
  }) async {
    try {
      print('ContactService: Getting OTP by phone number - $phoneNumber');

      final uri = Uri.parse(
        '$apiBaseUrl/api/Contact/GetOTPByPhoneNO',
      ).replace(queryParameters: {'phoneNumber': phoneNumber});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final otpResponse = OtpResponse.fromJson(data);
        print('ContactService: Retrieved OTP for phone - $phoneNumber');
        return otpResponse;
      } else {
        print('ContactService: Error getting OTP - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('ContactService: Exception getting OTP - $e');
      return null;
    }
  }
}
