# API Quick Reference

Fast lookup guide for all API endpoints and common usage patterns.

## ContactService Quick Reference

### Import
```dart
import 'package:attendance_app/services/contact_service.dart';
import 'package:attendance_app/models/contact.dart';
```

### Groups & SubGroups
```dart
// Get all groups
List<Group> groups = await ContactService.getAllGroups();

// Get sub-groups
List<SubGroup> subGroups = await ContactService.getAllSubGroups(groupId: 'gid');
```

### Contacts CRUD
```dart
// Read
List<Contact> contacts = await ContactService.getContacts();
Contact? contact = await ContactService.getContactDetails(contactId: 'cid');
List<Contact> search = await ContactService.searchContacts(query: 'name');

// Create
Contact? newContact = await ContactService.addContact(
  name: 'Name',
  phoneNumber: '+123...',
);

// Update
Contact? updated = await ContactService.updateContact(id: 'cid', name: 'New Name');
```

### Attendance & Notifications
```dart
// Mark attendance
bool success = await ContactService.markAttendance(
  contactId: 'cid',
  latitude: 12.34,
  longitude: 56.78,
  faceVerified: true,
);

// Get notifications
List<ContactNotification> notifs = 
  await ContactService.getContactNotifications(contactId: 'cid');
```

### OTP & SMS
```dart
// Send SMS with reset code
bool sent = await ContactService.sendResetSmsByPhoneNo(
  phoneNumber: '+123...',
);

// Get OTP
OtpResponse? otp = await ContactService.getOtpByPhoneNo(
  phoneNumber: '+123...',
);

// Verify OTP
OtpResponse? confirmed = await ContactService.updateOtpConfirmationByPhoneNo(
  phoneNumber: '+123...',
  otp: '123456',
);

// Track attempts
OtpResponse? attempts = await ContactService.updateOtpAttemptByPhoneNo(
  phoneNumber: '+123...',
);
```

---

## CustomerService Quick Reference

### Import
```dart
import 'package:attendance_app/services/customer_service.dart';
import 'package:attendance_app/models/employee.dart';
```

### Employees CRUD
```dart
// Read
List<Employee> employees = await CustomerService.getAllEmployees();
List<Employee> search = await CustomerService.searchEmployees(query: 'name');
Employee? emp = await CustomerService.getEmployeeById(employeeId: 'eid');

// Create
Employee? newEmp = await CustomerService.addEmployee(
  name: 'John Doe',
  phoneNumber: '+123...',
  department: 'IT',
);

// Update
Employee? updated = await CustomerService.updateEmployee(
  id: 'eid',
  designation: 'Manager',
);

// Delete
bool deleted = await CustomerService.deleteEmployee(id: 'eid');
```

### Attendance
```dart
// Get employee attendance
Map<String, dynamic>? attendance = 
  await CustomerService.getEmployeeAttendance(
    employeeId: 'eid',
    fromDate: DateTime(2024, 1, 1),
    toDate: DateTime(2024, 1, 31),
  );

print('Present: ${attendance?['presentDays']} days');
print('Attendance: ${attendance?['attendance']}%');
```

---

## Common Patterns

### List View with Error Handling
```dart
@override
Widget build(BuildContext context) {
  return FutureBuilder<List<Contact>>(
    future: ContactService.getContacts(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('No contacts found'));
      }
      
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final contact = snapshot.data![index];
          return ListTile(
            title: Text(contact.name),
            subtitle: Text(contact.phoneNumber),
          );
        },
      );
    },
  );
}
```

### Form Submission with Loading State
```dart
bool isLoading = false;

Future<void> submitForm() async {
  setState(() => isLoading = true);
  
  try {
    final contact = await ContactService.addContact(
      name: nameController.text,
      phoneNumber: phoneController.text,
    );
    
    if (mounted) {
      if (contact != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contact added!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add contact')),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}
```

### Search with Debounce
```dart
Timer? _debounce;

void onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 500), () async {
    final results = await ContactService.searchContacts(query: query);
    setState(() {
      searchResults = results;
    });
  });
}

@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}
```

### OTP Verification Flow
```dart
Future<void> verifyOtp(String phoneNumber, String otpCode) async {
  // Verify OTP
  final response = await ContactService.updateOtpConfirmationByPhoneNo(
    phoneNumber: phoneNumber,
    otp: otpCode,
  );

  if (response?.isConfirmed ?? false) {
    // OTP verified, proceed
    print('OTP verified successfully');
  } else {
    // Check attempts
    final attempts = await ContactService.updateOtpAttemptByPhoneNo(
      phoneNumber: phoneNumber,
    );
    print('Remaining attempts: ${attempts?.maxAttempts! - attempts!.attempts!}');
  }
}
```

---

## All Models

### Contact
```dart
Contact(
  id: 'contact_id',
  name: 'John Doe',
  phoneNumber: '+1234567890',
  email: 'john@example.com',
  groupId: 'group_id',
  subGroupId: 'subgroup_id',
  address: '123 Main St',
  profileImagePath: 'assets/image.png',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  isActive: true,
)
```

### Employee
```dart
Employee(
  id: 'emp_id',
  name: 'Jane Smith',
  employeeCode: 'EMP001',
  email: 'jane@company.com',
  phoneNumber: '+1234567890',
  department: 'Engineering',
  designation: 'Senior Developer',
  status: 'active',
  joinDate: DateTime(2024, 1, 15),
  profileImagePath: 'assets/avatar.png',
  createdAt: DateTime.now(),
  isActive: true,
)
```

### Group
```dart
Group(
  id: 'group_id',
  name: 'Friends',
  description: 'Close friends group',
  contactCount: 15,
  createdAt: DateTime.now(),
  isActive: true,
)
```

### SubGroup
```dart
SubGroup(
  id: 'subgroup_id',
  name: 'College Friends',
  groupId: 'group_id',
  description: 'Friends from college',
  contactCount: 8,
  createdAt: DateTime.now(),
  isActive: true,
)
```

### ContactNotification
```dart
ContactNotification(
  id: 'notif_id',
  contactId: 'contact_id',
  contactName: 'John Doe',
  title: 'Attendance Marked',
  message: 'Attendance marked at 9:00 AM',
  type: 'attendance',
  createdAt: DateTime.now(),
  isRead: false,
  readAt: null,
)
```

### OtpResponse
```dart
OtpResponse(
  otpId: 'otp_id',
  phoneNumber: '+1234567890',
  otp: '123456',
  attempts: 0,
  maxAttempts: 5,
  expiryTime: DateTime.now().add(Duration(minutes: 10)),
  isConfirmed: false,
  success: true,
  message: 'OTP sent successfully',
)
```

---

## Configuration Checklist

- [ ] Update API base URL in `contact_service.dart`
- [ ] Update API base URL in `customer_service.dart`
- [ ] Set up authentication token management
- [ ] Add error handling for network failures
- [ ] Implement retry logic if needed
- [ ] Add loading states in UI
- [ ] Test all endpoints with sample data
- [ ] Handle different response formats from API
- [ ] Add logging for debugging
- [ ] Test with and without authentication tokens

---

## Environment Variables (Optional)

For better security, consider using environment variables:

```dart
// Create a config.dart file
const String API_BASE_URL = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'https://attendanceapi.acculekhaa.com');

// Then use in services
static const String apiBaseUrl = API_BASE_URL;
```

Build command:
```bash
flutter run --dart-define=API_BASE_URL=https://your-api.com
```

---

## Testing Endpoints

### Using Postman

**POST /api/Contact/GetAllGroups**
```json
{}
```

**POST /api/Contact/AddContact**
```json
{
  "name": "John Doe",
  "phoneNumber": "+1234567890",
  "email": "john@example.com"
}
```

**GET /api/Contact/SearchCName**
```
?query=John
```

**GET /api/Contact/SendResetSMSByPhoneNo**
```
?phoneNumber=%2B1234567890
```

---

## Troubleshooting

### "No internet connection"
- Check device network connectivity
- Verify API URL is correct
- Check firewall/proxy settings

### "401 Unauthorized"
- Verify authentication token is valid
- Check token expiration
- Refresh token if needed

### "400 Bad Request"
- Check request body format
- Verify all required fields are present
- Check field data types

### "500 Server Error"
- Check server logs
- Verify API version compatibility
- Contact API provider

### "Connection timeout"
- Increase timeout duration in http package
- Check server response time
- Implement retry logic

---

## Need Help?

Refer to:
1. `API_INTEGRATION_COMPLETE.md` - Detailed documentation
2. `API_SERVICE_EXAMPLES.dart` - Code examples
3. API documentation from backend team
4. Postman collection for API testing
