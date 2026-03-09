/// CustomerService handles customer/employee-related API operations
/// Provides methods for managing employees
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';

class CustomerService {
  // TODO: Replace with your actual API base URL
  static const String apiBaseUrl = 'https://attendanceapi.acculekhaa.com';

  // ==================== EMPLOYEES ====================

  /// Get all employees
  /// API Endpoint: POST /api/Customer/GetAllEmployees
  /// Returns: List of Employee objects or empty list on error
  static Future<List<Employee>> getAllEmployees({
    int? limit,
    int? offset,
    String? departmentId,
    String? status,
    String? token,
  }) async {
    try {
      print('CustomerService: Fetching all employees');

      final body = {};
      if (limit != null) body['limit'] = limit;
      if (offset != null) body['offset'] = offset;
      if (departmentId != null) body['departmentId'] = departmentId;
      if (status != null) body['status'] = status;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Customer/GetAllEmployees'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> employeesList = [];
        if (data is Map) {
          employeesList =
              data['data'] ?? data['employees'] ?? data['result'] ?? [];
        } else if (data is List) {
          employeesList = data;
        }

        final employees = employeesList
            .map((e) => Employee.fromJson(e))
            .toList();
        print('CustomerService: Fetched ${employees.length} employees');
        return employees;
      } else {
        print(
          'CustomerService: Error fetching employees - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('CustomerService: Exception fetching employees - $e');
      return [];
    }
  }

  /// Get employee by ID
  /// Returns: Employee object if found, null otherwise
  static Future<Employee?> getEmployeeById({
    required String employeeId,
    String? token,
  }) async {
    try {
      print('CustomerService: Fetching employee - $employeeId');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Customer/GetEmployeeDetails'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'employeeId': employeeId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Employee? employee;
        if (data is Map) {
          employee = Employee.fromJson(data['data'] ?? data);
        }

        if (employee != null) {
          print('CustomerService: Fetched employee - $employeeId');
          return employee;
        }
      } else {
        print(
          'CustomerService: Error fetching employee - ${response.statusCode}',
        );
      }
      return null;
    } catch (e) {
      print('CustomerService: Exception fetching employee - $e');
      return null;
    }
  }

  /// Search employees by name or employee code
  /// Returns: List of Employee objects matching the search
  static Future<List<Employee>> searchEmployees({
    required String query,
    String? token,
  }) async {
    try {
      print('CustomerService: Searching employees - $query');

      final uri = Uri.parse(
        '$apiBaseUrl/api/Customer/SearchEmployee',
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

        List<dynamic> employeesList = [];
        if (data is Map) {
          employeesList =
              data['data'] ?? data['employees'] ?? data['result'] ?? [];
        } else if (data is List) {
          employeesList = data;
        }

        final employees = employeesList
            .map((e) => Employee.fromJson(e))
            .toList();
        print(
          'CustomerService: Found ${employees.length} employees for - $query',
        );
        return employees;
      } else {
        print(
          'CustomerService: Error searching employees - ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('CustomerService: Exception searching employees - $e');
      return [];
    }
  }

  /// Add a new employee
  /// Returns: Employee object if successful, null otherwise
  static Future<Employee?> addEmployee({
    required String name,
    String? employeeCode,
    String? email,
    String? phoneNumber,
    String? department,
    String? designation,
    DateTime? joinDate,
    String? token,
  }) async {
    try {
      print('CustomerService: Adding new employee - $name');

      final body = {
        'name': name,
        if (employeeCode != null) 'employeeCode': employeeCode,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (department != null) 'department': department,
        if (designation != null) 'designation': designation,
        if (joinDate != null) 'joinDate': joinDate.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Customer/AddEmployee'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        Employee? employee;
        if (data is Map) {
          employee = Employee.fromJson(data['data'] ?? data);
        }

        if (employee != null) {
          print('CustomerService: Employee added successfully - $name');
          return employee;
        }
      } else {
        print(
          'CustomerService: Error adding employee - ${response.statusCode}',
        );
      }
      return null;
    } catch (e) {
      print('CustomerService: Exception adding employee - $e');
      return null;
    }
  }

  /// Update an existing employee
  /// Returns: Employee object if successful, null otherwise
  static Future<Employee?> updateEmployee({
    required String id,
    String? name,
    String? email,
    String? phoneNumber,
    String? department,
    String? designation,
    String? status,
    String? token,
  }) async {
    try {
      print('CustomerService: Updating employee - $id');

      final body = {
        'id': id,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (department != null) 'department': department,
        if (designation != null) 'designation': designation,
        if (status != null) 'status': status,
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Customer/UpdateEmployee'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Employee? employee;
        if (data is Map) {
          employee = Employee.fromJson(data['data'] ?? data);
        }

        if (employee != null) {
          print('CustomerService: Employee updated successfully - $id');
          return employee;
        }
      } else {
        print(
          'CustomerService: Error updating employee - ${response.statusCode}',
        );
      }
      return null;
    } catch (e) {
      print('CustomerService: Exception updating employee - $e');
      return null;
    }
  }

  /// Delete an employee (typically sets status to inactive)
  /// Returns: true if successful, false otherwise
  static Future<bool> deleteEmployee({
    required String id,
    String? token,
  }) async {
    try {
      print('CustomerService: Deleting employee - $id');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Customer/DeleteEmployee'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] ?? data['isSuccess'] ?? false;

        if (success) {
          print('CustomerService: Employee deleted successfully - $id');
        }
        return success;
      } else {
        print(
          'CustomerService: Error deleting employee - ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('CustomerService: Exception deleting employee - $e');
      return false;
    }
  }

  /// Get employee attendance record
  /// Returns: Map with attendance data
  static Future<Map<String, dynamic>?> getEmployeeAttendance({
    required String employeeId,
    DateTime? fromDate,
    DateTime? toDate,
    String? token,
  }) async {
    try {
      print('CustomerService: Fetching employee attendance - $employeeId');

      final body = {
        'employeeId': employeeId,
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Customer/GetEmployeeAttendance'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('CustomerService: Fetched attendance for employee - $employeeId');
        return data;
      } else {
        print(
          'CustomerService: Error fetching employee attendance - ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('CustomerService: Exception fetching employee attendance - $e');
      return null;
    }
  }
}
