/// API Usage Examples
///
/// This file contains practical examples of how to use the ContactService
/// and CustomerService APIs in your Flutter application.

// ===========================
// IMPORT STATEMENTS
// ===========================
import 'package:attendance_app/services/contact_service.dart';
import 'package:attendance_app/services/customer_service.dart';

// ===========================
// CONTACT SERVICE EXAMPLES
// ===========================

class ContactServiceExamples {
  /// Example 1: Fetch all contact groups
  Future<void> exampleGetAllGroups() async {
    try {
      final groups = await ContactService.getAllGroups(
        token: 'your_auth_token', // Optional auth token
      );

      print('Found ${groups.length} groups:');
      for (final group in groups) {
        print('  - ${group.name} (${group.contactCount} contacts)');
      }
    } catch (e) {
      print('Error fetching groups: $e');
    }
  }

  /// Example 2: Fetch all sub-groups within a specific group
  Future<void> exampleGetAllSubGroups() async {
    try {
      final subGroups = await ContactService.getAllSubGroups(
        groupId: 'group_123',
        token: 'your_auth_token',
      );

      print('Found ${subGroups.length} sub-groups:');
      for (final subGroup in subGroups) {
        print('  - ${subGroup.name} in group ${subGroup.groupId}');
      }
    } catch (e) {
      print('Error fetching sub-groups: $e');
    }
  }

  /// Example 3: Get all contacts with optional filtering
  Future<void> exampleGetContacts() async {
    try {
      // Get all contacts
      final allContacts = await ContactService.getContacts(
        token: 'your_auth_token',
      );
      print('Total contacts: ${allContacts.length}');

      // Get contacts from a specific group with pagination
      final groupContacts = await ContactService.getContacts(
        groupId: 'group_123',
        limit: 20,
        offset: 0,
        token: 'your_auth_token',
      );
      print('Contacts in group: ${groupContacts.length}');
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  /// Example 4: Add a new contact
  Future<void> exampleAddContact() async {
    try {
      final newContact = await ContactService.addContact(
        name: 'John Doe',
        phoneNumber: '+1234567890',
        email: 'john@example.com',
        groupId: 'group_123',
        subGroupId: 'subgroup_456',
        address: '123 Main St, City',
        token: 'your_auth_token',
      );

      if (newContact != null) {
        print('Contact added successfully!');
        print('Contact ID: ${newContact.id}');
      } else {
        print('Failed to add contact');
      }
    } catch (e) {
      print('Error adding contact: $e');
    }
  }

  /// Example 5: Update an existing contact
  Future<void> exampleUpdateContact() async {
    try {
      final updatedContact = await ContactService.updateContact(
        id: 'contact_123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        phoneNumber: '+1234567891',
        address: '456 Oak Ave, City',
        token: 'your_auth_token',
      );

      if (updatedContact != null) {
        print('Contact updated successfully!');
        print('Updated name: ${updatedContact.name}');
      }
    } catch (e) {
      print('Error updating contact: $e');
    }
  }

  /// Example 6: Mark attendance for a contact
  Future<void> exampleMarkAttendance() async {
    try {
      final success = await ContactService.markAttendance(
        contactId: 'contact_123',
        latitude: 40.7128,
        longitude: -74.0060,
        faceVerified: true,
        token: 'your_auth_token',
      );

      if (success) {
        print('Attendance marked successfully!');
      } else {
        print('Failed to mark attendance');
      }
    } catch (e) {
      print('Error marking attendance: $e');
    }
  }

  /// Example 7: Get detailed information about a contact
  Future<void> exampleGetContactDetails() async {
    try {
      final contact = await ContactService.getContactDetails(
        contactId: 'contact_123',
        token: 'your_auth_token',
      );

      if (contact != null) {
        print('Contact Details:');
        print('Name: ${contact.name}');
        print('Phone: ${contact.phoneNumber}');
        print('Email: ${contact.email}');
        print('Group: ${contact.groupId}');
      }
    } catch (e) {
      print('Error fetching contact details: $e');
    }
  }

  /// Example 8: Get notifications for a contact
  Future<void> exampleGetContactNotifications() async {
    try {
      final notifications = await ContactService.getContactNotifications(
        contactId: 'contact_123',
        token: 'your_auth_token',
      );

      print('Notifications for contact:');
      for (final notification in notifications) {
        print('  - ${notification.title}: ${notification.message}');
        print('    Type: ${notification.type}, Read: ${notification.isRead}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  /// Example 9: Search contacts by name
  Future<void> exampleSearchContacts() async {
    try {
      final results = await ContactService.searchContacts(
        query: 'John',
        token: 'your_auth_token',
      );

      print('Search results for "John": ${results.length} contacts found');
      for (final contact in results) {
        print('  - ${contact.name} (${contact.phoneNumber})');
      }
    } catch (e) {
      print('Error searching contacts: $e');
    }
  }

  /// Example 10: Send reset SMS to a phone number
  Future<void> exampleSendResetSms() async {
    try {
      final success = await ContactService.sendResetSmsByPhoneNo(
        phoneNumber: '+1234567890',
        token: 'your_auth_token',
      );

      if (success) {
        print('Reset SMS sent successfully!');
      } else {
        print('Failed to send SMS');
      }
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }

  /// Example 11: OTP workflow
  Future<void> exampleOtpWorkflow() async {
    try {
      const phoneNumber = '+1234567890';
      const otpCode = '123456';

      // Step 1: Send reset SMS/OTP
      print('Step 1: Sending OTP...');
      await ContactService.sendResetSmsByPhoneNo(
        phoneNumber: phoneNumber,
        token: 'your_auth_token',
      );

      // Step 2: Get OTP by phone number (optional - to verify)
      print('Step 2: Retrieving OTP...');
      final otpResponse = await ContactService.getOtpByPhoneNo(
        phoneNumber: phoneNumber,
        token: 'your_auth_token',
      );

      if (otpResponse != null) {
        print('OTP sent to: ${otpResponse.phoneNumber}');
        print('Attempts: ${otpResponse.attempts}/${otpResponse.maxAttempts}');
      }

      // Step 3: Update OTP attempt (when user enters wrong OTP)
      print('Step 3: Updating OTP attempt...');
      final updatedAttempt = await ContactService.updateOtpAttemptByPhoneNo(
        phoneNumber: phoneNumber,
        token: 'your_auth_token',
      );

      if (updatedAttempt != null) {
        print(
          'Remaining attempts: ${updatedAttempt.maxAttempts! - updatedAttempt.attempts!}',
        );
      }

      // Step 4: Confirm OTP
      print('Step 4: Confirming OTP...');
      final confirmResponse =
          await ContactService.updateOtpConfirmationByPhoneNo(
            phoneNumber: phoneNumber,
            otp: otpCode,
            token: 'your_auth_token',
          );

      if (confirmResponse != null && confirmResponse.isConfirmed) {
        print('OTP verified successfully!');
      } else {
        print('OTP verification failed');
      }
    } catch (e) {
      print('Error in OTP workflow: $e');
    }
  }
}

// ===========================
// CUSTOMER SERVICE EXAMPLES
// ===========================

class CustomerServiceExamples {
  /// Example 1: Get all employees with pagination
  Future<void> exampleGetAllEmployees() async {
    try {
      final employees = await CustomerService.getAllEmployees(
        limit: 20,
        offset: 0,
        //department:'IT',
        status: 'active',
        token: 'your_auth_token',
      );

      print('Fetched ${employees.length} employees');
      for (final employee in employees) {
        print('  - ${employee.name} (${employee.employeeCode})');
        print('    Department: ${employee.department}');
        print('    Email: ${employee.email}');
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
  }

  /// Example 2: Get employee by ID
  Future<void> exampleGetEmployeeById() async {
    try {
      final employee = await CustomerService.getEmployeeById(
        employeeId: 'emp_123',
        token: 'your_auth_token',
      );

      if (employee != null) {
        print('Employee Details:');
        print('Name: ${employee.name}');
        print('Code: ${employee.employeeCode}');
        print('Department: ${employee.department}');
        print('Designation: ${employee.designation}');
        print('Join Date: ${employee.joinDate}');
      }
    } catch (e) {
      print('Error fetching employee: $e');
    }
  }

  /// Example 3: Search employees
  Future<void> exampleSearchEmployees() async {
    try {
      final results = await CustomerService.searchEmployees(
        query: 'John',
        token: 'your_auth_token',
      );

      print('Search results: ${results.length} employees found');
      for (final employee in results) {
        print('  - ${employee.name} (${employee.designation})');
      }
    } catch (e) {
      print('Error searching employees: $e');
    }
  }

  /// Example 4: Add a new employee
  Future<void> exampleAddEmployee() async {
    try {
      final newEmployee = await CustomerService.addEmployee(
        name: 'Jane Smith',
        employeeCode: 'EMP001',
        email: 'jane.smith@company.com',
        phoneNumber: '+1234567890',
        department: 'Engineering',
        designation: 'Senior Developer',
        joinDate: DateTime(2024, 1, 15),
        token: 'your_auth_token',
      );

      if (newEmployee != null) {
        print('Employee added successfully!');
        print('Employee ID: ${newEmployee.id}');
      }
    } catch (e) {
      print('Error adding employee: $e');
    }
  }

  /// Example 5: Update an employee
  Future<void> exampleUpdateEmployee() async {
    try {
      final updatedEmployee = await CustomerService.updateEmployee(
        id: 'emp_123',
        name: 'Jane Doe',
        email: 'jane.doe@company.com',
        designation: 'Principal Developer',
        status: 'active',
        token: 'your_auth_token',
      );

      if (updatedEmployee != null) {
        print('Employee updated successfully!');
      }
    } catch (e) {
      print('Error updating employee: $e');
    }
  }

  /// Example 6: Delete an employee
  Future<void> exampleDeleteEmployee() async {
    try {
      final success = await CustomerService.deleteEmployee(
        id: 'emp_123',
        token: 'your_auth_token',
      );

      if (success) {
        print('Employee deleted successfully!');
      } else {
        print('Failed to delete employee');
      }
    } catch (e) {
      print('Error deleting employee: $e');
    }
  }

  /// Example 7: Get employee attendance
  Future<void> exampleGetEmployeeAttendance() async {
    try {
      final attendance = await CustomerService.getEmployeeAttendance(
        employeeId: 'emp_123',
        fromDate: DateTime(2024, 1, 1),
        toDate: DateTime(2024, 1, 31),
        token: 'your_auth_token',
      );

      if (attendance != null) {
        print('Attendance Data:');
        print('Total Days: ${attendance['totalDays']}');
        print('Present: ${attendance['presentDays']}');
        print('Absent: ${attendance['absentDays']}');
        print('Average: ${attendance['attendance']}%');
      }
    } catch (e) {
      print('Error fetching attendance: $e');
    }
  }
}

// ===========================
// INTEGRATION IN SCREENS
// ===========================

class ContactsScreenExample {
  /// How to integrate ContactService in a StatefulWidget screen
  /*
  class ContactsScreen extends StatefulWidget {
    @override
    State<ContactsScreen> createState() => _ContactsScreenState();
  }

  class _ContactsScreenState extends State<ContactsScreen> {
    late List<Contact> contacts = [];
    bool isLoading = false;
    String? errorMessage;

    @override
    void initState() {
      super.initState();
      _loadContacts();
    }

    Future<void> _loadContacts() async {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final loadedContacts = await ContactService.getContacts(
          token: 'your_auth_token',
        );

        setState(() {
          contacts = loadedContacts;
        });
      } catch (e) {
        setState(() {
          errorMessage = 'Failed to load contacts: $e';
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }

    Future<void> _addContact(String name, String phone) async {
      final newContact = await ContactService.addContact(
        name: name,
        phoneNumber: phone,
        token: 'your_auth_token',
      );

      if (newContact != null) {
        setState(() {
          contacts.add(newContact);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contact added successfully!')),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text('Contacts')),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        title: Text(contact.name),
                        subtitle: Text(contact.phoneNumber),
                        onTap: () {
                          // Navigate to contact details
                        },
                      );
                    },
                  ),
      );
    }
  }
  */
}
