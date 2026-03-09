# API Integration Guide

Complete guide to using the Contact and Customer APIs in your Flutter attendance app.

## Table of Contents

1. [Overview](#overview)
2. [Setup & Configuration](#setup--configuration)
3. [Contact Service](#contact-service)
4. [Customer Service](#customer-service)
5. [Authentication](#authentication)
6. [Error Handling](#error-handling)
7. [Common Patterns](#common-patterns)

## Overview

This project includes two main API services:

- **ContactService**: Manages contacts, groups, and OTP operations
- **CustomerService**: Manages employees and attendance records

All API calls return typed Dart objects for type safety and easier integration.

## Setup & Configuration

### 1. Update API Base URL

In both `contact_service.dart` and `customer_service.dart`, update the API base URL:

```dart
static const String apiBaseUrl = 'https://your-api-domain.com';
```

### 2. Update pubspec.yaml (if needed)

The project already includes the `http` package:

```yaml
dependencies:
  http: ^1.2.0
```

### 3. Handle Authentication

Most endpoints support optional authentication tokens:

```dart
final contacts = await ContactService.getContacts(
  token: 'your_jwt_token',
);
```

## Contact Service

### Available Models

- **Contact**: Individual contact with phone, email, groupId, etc.
- **Group**: Contact category/group
- **SubGroup**: Sub-category within a group
- **ContactNotification**: Notification for a contact
- **OtpResponse**: OTP-related response data

### API Endpoints

#### 1. Get All Groups

```dart
final groups = await ContactService.getAllGroups(
  token: 'your_token',
);

// Usage
if (groups.isNotEmpty) {
  print('Found ${groups.length} groups');
  for (var group in groups) {
    print('${group.name}: ${group.contactCount} contacts');
  }
}
```

**Endpoint**: `POST /api/Contact/GetAllGroups`

#### 2. Get All SubGroups

```dart
final subGroups = await ContactService.getAllSubGroups(
  groupId: 'group_123',  // Optional: filter by group
  token: 'your_token',
);
```

**Endpoint**: `POST /api/Contact/GetAllSubGroups`

#### 3. Get Contacts

```dart
// Get all contacts
final allContacts = await ContactService.getContacts();

// Get contacts from specific group with pagination
final groupContacts = await ContactService.getContacts(
  groupId: 'group_id',
  subGroupId: 'subgroup_id',
  limit: 20,
  offset: 0,
  token: 'your_token',
);
```

**Endpoint**: `POST /api/Contact/GetContacts`

#### 4. Add Contact

```dart
final newContact = await ContactService.addContact(
  name: 'John Doe',
  phoneNumber: '+1234567890',
  email: 'john@example.com',
  groupId: 'group_123',
  subGroupId: 'subgroup_456',
  address: '123 Main St',
  token: 'your_token',
);

if (newContact != null) {
  print('Contact ${newContact.name} added with ID: ${newContact.id}');
}
```

**Endpoint**: `POST /api/Contact/AddContact`

#### 5. Update Contact

```dart
final updated = await ContactService.updateContact(
  id: 'contact_id',
  name: 'Jane Doe',
  phoneNumber: '+9876543210',
  email: 'jane@example.com',
  token: 'your_token',
);

if (updated != null) {
  print('Contact updated');
}
```

**Endpoint**: `POST /api/Contact/UpdateContact`

#### 6. Mark Attendance

```dart
final success = await ContactService.markAttendance(
  contactId: 'contact_id',
  latitude: 40.7128,
  longitude: -74.0060,
  faceVerified: true,
  token: 'your_token',
);

if (success) {
  print('Attendance marked successfully');
}
```

**Endpoint**: `POST /api/Contact/MarkAttendance`

#### 7. Get Contact Details

```dart
final contact = await ContactService.getContactDetails(
  contactId: 'contact_id',
  token: 'your_token',
);

if (contact != null) {
  print('${contact.name} - ${contact.phoneNumber}');
}
```

**Endpoint**: `POST /api/Contact/GetContactDetails`

#### 8. Get Contact Notifications

```dart
final notifications = await ContactService.getContactNotifications(
  contactId: 'contact_id',
  token: 'your_token',
);

for (var notification in notifications) {
  print('${notification.title}: ${notification.message}');
  print('Read: ${notification.isRead}');
}
```

**Endpoint**: `POST /api/Contact/GetContactNotifications`

#### 9. Search Contacts

```dart
final results = await ContactService.searchContacts(
  query: 'John',
  token: 'your_token',
);

print('Found ${results.length} contacts matching "John"');
```

**Endpoint**: `GET /api/Contact/SearchCName`

#### 10. Send Reset SMS

```dart
final success = await ContactService.sendResetSmsByPhoneNo(
  phoneNumber: '+1234567890',
  token: 'your_token',
);

if (success) {
  print('SMS sent successfully');
}
```

**Endpoint**: `GET /api/Contact/SendResetSMSByPhoneNo`

#### 11. Update OTP Attempt

```dart
final otpResponse = await ContactService.updateOtpAttemptByPhoneNo(
  phoneNumber: '+1234567890',
  token: 'your_token',
);

if (otpResponse != null) {
  print('Attempts: ${otpResponse.attempts}/${otpResponse.maxAttempts}');
}
```

**Endpoint**: `GET /api/Contact/UpdateOTPAttemptByPhoneNo`

#### 12. Confirm OTP

```dart
final response = await ContactService.updateOtpConfirmationByPhoneNo(
  phoneNumber: '+1234567890',
  otp: '123456',
  token: 'your_token',
);

if (response?.isConfirmed ?? false) {
  print('OTP verified');
}
```

**Endpoint**: `GET /api/Contact/UpdateOTPConfirmationByPhoneNo`

#### 13. Get OTP by Phone

```dart
final otpResponse = await ContactService.getOtpByPhoneNo(
  phoneNumber: '+1234567890',
  token: 'your_token',
);

if (otpResponse != null) {
  print('OTP expires at: ${otpResponse.expiryTime}');
}
```

**Endpoint**: `GET /api/Contact/GetOTPByPhoneNO`

## Customer Service

### Available Models

- **Employee**: Employee record with details like department, designation, etc.

### API Endpoints

#### 1. Get All Employees

```dart
final employees = await CustomerService.getAllEmployees(
  limit: 20,
  offset: 0,
  departmentId: 'dept_123',  // Optional
  status: 'active',          // Optional
  token: 'your_token',
);

for (var emp in employees) {
  print('${emp.name} - ${emp.designation}');
}
```

**Endpoint**: `POST /api/Customer/GetAllEmployees`

#### 2. Get Employee by ID

```dart
final employee = await CustomerService.getEmployeeById(
  employeeId: 'emp_123',
  token: 'your_token',
);

if (employee != null) {
  print('${employee.name} joined on ${employee.joinDate}');
}
```

**Additional Endpoint**: `POST /api/Customer/GetEmployeeDetails`

#### 3. Search Employees

```dart
final results = await CustomerService.searchEmployees(
  query: 'John',
  token: 'your_token',
);

print('Found ${results.length} employees');
```

**Additional Endpoint**: `GET /api/Customer/SearchEmployee`

#### 4. Add Employee

```dart
final newEmployee = await CustomerService.addEmployee(
  name: 'Jane Smith',
  employeeCode: 'EMP001',
  email: 'jane@company.com',
  phoneNumber: '+1234567890',
  department: 'Engineering',
  designation: 'Senior Developer',
  joinDate: DateTime(2024, 1, 15),
  token: 'your_token',
);

if (newEmployee != null) {
  print('Employee added: ${newEmployee.id}');
}
```

**Additional Endpoint**: `POST /api/Customer/AddEmployee`

#### 5. Update Employee

```dart
final updated = await CustomerService.updateEmployee(
  id: 'emp_123',
  name: 'Jane Doe',
  designation: 'Principal Developer',
  status: 'active',
  token: 'your_token',
);
```

**Additional Endpoint**: `POST /api/Customer/UpdateEmployee`

#### 6. Delete Employee

```dart
final success = await CustomerService.deleteEmployee(
  id: 'emp_123',
  token: 'your_token',
);

if (success) {
  print('Employee deleted');
}
```

**Additional Endpoint**: `POST /api/Customer/DeleteEmployee`

#### 7. Get Employee Attendance

```dart
final attendance = await CustomerService.getEmployeeAttendance(
  employeeId: 'emp_123',
  fromDate: DateTime(2024, 1, 1),
  toDate: DateTime(2024, 1, 31),
  token: 'your_token',
);

if (attendance != null) {
  print('Present: ${attendance['presentDays']} days');
  print('Attendance: ${attendance['attendance']}%');
}
```

**Additional Endpoint**: `POST /api/Customer/GetEmployeeAttendance`

## Authentication

### Using Tokens

Most endpoints accept an optional `token` parameter for authentication:

```dart
// With authentication
final contacts = await ContactService.getContacts(
  token: userToken,
);

// Without authentication (if API allows)
final contacts = await ContactService.getContacts();
```

### Token Management

Implement a token storage mechanism (using `flutter_secure_storage`):

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
```

Usage:

```dart
final token = await TokenManager.getToken();
if (token != null) {
  final contacts = await ContactService.getContacts(token: token);
}
```

## Error Handling

All service methods handle errors gracefully:

```dart
try {
  final contacts = await ContactService.getContacts();
  
  if (contacts.isEmpty) {
    print('No contacts found');
  }
} catch (e) {
  print('Error: $e');
}
```

### Common Status Codes

- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `404`: Not Found
- `500`: Server Error

### Retry Logic

Implement retry logic for network failures:

```dart
Future<List<Contact>> getContactsWithRetry({int retries = 3}) async {
  for (int attempt = 0; attempt < retries; attempt++) {
    try {
      return await ContactService.getContacts();
    } catch (e) {
      if (attempt == retries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 ^ attempt));
    }
  }
  return [];
}
```

## Common Patterns

### Pattern 1: Load Data in Widget

```dart
class ContactsListWidget extends StatefulWidget {
  @override
  State<ContactsListWidget> createState() => _ContactsListWidgetState();
}

class _ContactsListWidgetState extends State<ContactsListWidget> {
  late Future<List<Contact>> contactsFuture;

  @override
  void initState() {
    super.initState();
    contactsFuture = ContactService.getContacts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Contact>>(
      future: contactsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final contacts = snapshot.data ?? [];
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(contacts[index].name),
                subtitle: Text(contacts[index].phoneNumber),
              );
            },
          );
        }
      },
    );
  }
}
```

### Pattern 2: Form Submission

```dart
void submitAddContactForm(String name, String phone) async {
  if (name.isEmpty || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill all fields')),
    );
    return;
  }

  final contact = await ContactService.addContact(
    name: name,
    phoneNumber: phone,
    token: userToken,
  );

  if (contact != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contact added successfully')),
    );
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add contact')),
    );
  }
}
```

### Pattern 3: Pagination

```dart
class PaginatedContacts {
  List<Contact> contacts = [];
  int offset = 0;
  final int limit = 20;
  bool hasMore = true;

  Future<void> loadMore() async {
    if (!hasMore) return;

    final newContacts = await ContactService.getContacts(
      limit: limit,
      offset: offset,
    );

    if (newContacts.length < limit) {
      hasMore = false;
    }

    contacts.addAll(newContacts);
    offset += newContacts.length;
  }
}
```

### Pattern 4: Search with Debounce

```dart
import 'dart:async';

class SearchContactsWidget extends StatefulWidget {
  @override
  State<SearchContactsWidget> createState() => _SearchContactsWidgetState();
}

class _SearchContactsWidgetState extends State<SearchContactsWidget> {
  Timer? _searchTimer;
  List<Contact> searchResults = [];

  void searchContacts(String query) {
    _searchTimer?.cancel();
    
    _searchTimer = Timer(Duration(milliseconds: 500), () async {
      final results = await ContactService.searchContacts(query: query);
      setState(() {
        searchResults = results;
      });
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: searchContacts,
      decoration: InputDecoration(hintText: 'Search contacts'),
    );
  }
}
```

---

## Summary of All Endpoints

| Service | Endpoint | Method | Purpose |
|---------|----------|--------|---------|
| Contact | `/api/Contact/GetAllGroups` | POST | Get all groups |
| Contact | `/api/Contact/GetAllSubGroups` | POST | Get all sub-groups |
| Contact | `/api/Contact/GetContacts` | POST | Get contacts |
| Contact | `/api/Contact/AddContact` | POST | Add new contact |
| Contact | `/api/Contact/UpdateContact` | POST | Update contact |
| Contact | `/api/Contact/MarkAttendance` | POST | Mark attendance |
| Contact | `/api/Contact/GetContactDetails` | POST | Get contact details |
| Contact | `/api/Contact/GetContactNotifications` | POST | Get notifications |
| Contact | `/api/Contact/SearchCName` | GET | Search contacts |
| Contact | `/api/Contact/SendResetSMSByPhoneNo` | GET | Send SMS |
| Contact | `/api/Contact/UpdateOTPAttemptByPhoneNo` | GET | Update OTP attempt |
| Contact | `/api/Contact/UpdateOTPConfirmationByPhoneNo` | GET | Confirm OTP |
| Contact | `/api/Contact/GetOTPByPhoneNO` | GET | Get OTP |
| Customer | `/api/Customer/GetAllEmployees` | POST | Get all employees |
