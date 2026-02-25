# Local Database Setup for Attendance Storage

## Overview
This guide explains how to use the local SQLite database to save and manage attendance records in your Flutter attendance app.

## Features Implemented

### 1. **Database Helper** (`database_helper.dart`)
The `DatabaseHelper` class provides complete CRUD (Create, Read, Update, Delete) operations for attendance records.

#### Database Schema

**Table: `attendance_records`**
- `id` (TEXT, PRIMARY KEY): Unique record identifier
- `class_id` (TEXT): Class identifier
- `period_id` (TEXT): Period/Time slot identifier
- `date_time` (TEXT): Timestamp of attendance
- `remarks` (TEXT): Optional notes
- `is_submitted` (INTEGER): Sync status (0=not submitted, 1=submitted to backend)
- `created_at` (TEXT): Creation timestamp
- `updated_at` (TEXT): Last update timestamp

**Table: `student_attendance`**
- `id` (INTEGER, AUTO): Auto-increment ID
- `attendance_id` (TEXT, FOREIGN KEY): Reference to attendance_records
- `student_id` (TEXT): Student identifier
- `is_present` (INTEGER): Attendance status (0=absent, 1=present)

### 2. **Updated Attendance Service** (`attendance_service.dart`)
Added local database methods to `AttendanceService` class for easy integration.

---

## Usage Examples

### Basic Setup
The database is automatically initialized on first use. No additional setup required!

### Saving Attendance Records

#### Save Single Attendance Record
```dart
import 'package:attendance_app/models/attendance_record.dart';
import 'package:attendance_app/services/attendance_service.dart';

// Create an attendance record
final attendanceRecord = AttendanceRecord(
  id: 'attendance_${DateTime.now().millisecondsSinceEpoch}',
  classId: 'class_1',
  periodId: 'period_1',
  dateTime: DateTime.now(),
  studentAttendance: {
    'student_1': true,   // Present
    'student_2': false,  // Absent
    'student_3': true,   // Present
  },
  remarks: 'Morning session',
  isSubmitted: false,
);

// Save to local database
final saved = await AttendanceService.saveAttendanceLocally(attendanceRecord);
if (saved) {
  print('Attendance saved successfully!');
} else {
  print('Failed to save attendance');
}
```

#### Save Batch Attendance Records
```dart
// Save multiple records at once (more efficient)
final records = [
  AttendanceRecord(...),
  AttendanceRecord(...),
  AttendanceRecord(...),
];

final saved = await AttendanceService.saveBatchAttendanceLocally(records);
```

---

### Retrieving Attendance Records

#### Get All Attendance Records
```dart
final allRecords = await AttendanceService.getAllAttendanceLocally();

for (final record in allRecords) {
  print('Class: ${record.classId}');
  print('Present: ${record.presentCount}');
  print('Absent: ${record.absentCount}');
}
```

#### Get Attendance by Record ID
```dart
final record = await AttendanceService.getAttendanceLocallyById('attendance_123');

if (record != null) {
  print('Record found: ${record.id}');
  print('Date: ${record.dateTime}');
}
```

#### Get Attendance by Class
```dart
final classAttendance = await AttendanceService.getAttendanceByClassLocally('class_1');

print('Total attendance records for class: ${classAttendance.length}');
```

#### Get Attendance by Date Range
```dart
final startDate = DateTime(2024, 2, 1);
final endDate = DateTime(2024, 2, 28);

final records = await AttendanceService.getAttendanceByDateRangeLocally(
  startDate,
  endDate,
);

print('Records in February: ${records.length}');
```

#### Get Unsubmitted Records (for sync)
```dart
// Get records that haven't been synced with backend
final unsubmitted = await AttendanceService.getUnsubmittedAttendanceLocally();

print('Unsubmitted records: ${unsubmitted.length}');
```

---

### Updating Attendance Records

#### Update Attendance Record
```dart
// Fetch existing record
var record = await AttendanceService.getAttendanceLocallyById('attendance_123');

if (record != null) {
  // Modify the record
  record.studentAttendance['student_1'] = false; // Change from present to absent
  
  // Save changes
  final updated = await AttendanceService.updateAttendanceLocally(record);
  if (updated) {
    print('Record updated successfully');
  }
}
```

#### Mark as Submitted (After Syncing with Backend)
```dart
// After successfully uploading to backend
final marked = await AttendanceService.markAttendanceAsSubmittedLocally('attendance_123');

if (marked) {
  print('Record marked as submitted');
}
```

---

### Deleting Attendance Records

#### Delete Single Record
```dart
final deleted = await AttendanceService.deleteAttendanceLocally('attendance_123');

if (deleted) {
  print('Record deleted successfully');
}
```

---

### Syncing with Backend

#### Sync Unsubmitted Records
```dart
// When internet is available, sync unsubmitted records
final synced = await AttendanceService.syncAttendanceWithBackend(
  token: 'your_auth_token',
);

if (synced) {
  print('All records synced with backend');
}
```

---

### Utility Operations

#### Get Total Attendance Count
```dart
final totalCount = await AttendanceService.getTotalAttendanceCountLocally();
print('Total attendance records: $totalCount');
```

---

## Integration with UI - Complete Example

### In Your Take Attendance Screen

```dart
import 'package:flutter/material.dart';
import 'package:attendance_app/models/attendance_record.dart';
import 'package:attendance_app/services/attendance_service.dart';
import 'package:uuid/uuid.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final String classId;
  final String periodId;
  
  const TakeAttendanceScreen({
    required this.classId,
    required this.periodId,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  late Map<String, bool> studentAttendance;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    studentAttendance = {};
    // Load your students here and initialize attendance map
  }

  /// Save attendance to local database
  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    try {
      // Create attendance record
      final record = AttendanceRecord(
        id: const Uuid().v4(), // Generate unique ID
        classId: widget.classId,
        periodId: widget.periodId,
        dateTime: DateTime.now(),
        studentAttendance: studentAttendance,
        remarks: 'Marked using face recognition',
        isSubmitted: false, // Will be set to true after syncing with backend
      );

      // Save to local database
      final saved = await AttendanceService.saveAttendanceLocally(record);

      if (saved) {
        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Attendance saved locally'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back or proceed to next screen
        Navigator.of(context).pop({'success': true, 'recordId': record.id});
      } else {
        throw Exception('Failed to save attendance');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Attendance')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: studentAttendance.length,
              itemBuilder: (context, index) {
                final studentId = studentAttendance.keys.elementAt(index);
                final isPresent = studentAttendance[studentId] ?? false;

                return CheckboxListTile(
                  title: Text(studentId),
                  value: isPresent,
                  onChanged: (value) {
                    setState(() {
                      studentAttendance[studentId] = value ?? false;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAttendance,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Attendance'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Viewing Saved Attendance Records

```dart
import 'package:flutter/material.dart';
import 'package:attendance_app/services/attendance_service.dart';

class AttendanceLogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Logs')),
      body: FutureBuilder(
        future: AttendanceService.getAllAttendanceLocally(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return const Center(child: Text('No attendance records'));
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(record.classId),
                  subtitle: Text(
                    'Date: ${record.dateTime.toString().split('.')[0]}\n'
                    'Present: ${record.presentCount}, Absent: ${record.absentCount}',
                  ),
                  trailing: Chip(
                    label: Text(record.isSubmitted ? 'Synced' : 'Local'),
                    backgroundColor: record.isSubmitted ? Colors.green : Colors.orange,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## Syncing Strategy

### Recommended Flow:

1. **Capture Attendance** → Save locally immediately
2. **Show Confirmation** → Tell user it's saved locally
3. **When Online** → Sync with backend using `syncAttendanceWithBackend()`
4. **On Success** → Mark as submitted using `markAttendanceAsSubmittedLocally()`

```dart
// Example sync workflow
Future<void> syncOfflineData() async {
  // Check internet connection
  final hasInternet = await checkInternetConnection();
  
  if (hasInternet) {
    // Sync unsubmitted records
    final synced = await AttendanceService.syncAttendanceWithBackend(
      token: getAuthToken(),
    );
    
    if (synced) {
      // Show success message
      print('All records synced!');
    }
  }
}
```

---

## Important Notes

1. **Automatic Initialization**: The database is created and initialized automatically
2. **Singleton Pattern**: `DatabaseHelper` uses a singleton pattern, ensuring only one database connection
3. **Thread Safe**: SQLite operations are safe for concurrent access
4. **Offline First**: Save locally first, sync with backend when possible
5. **Data Persistence**: All data persists even after app restart
6. **Backup**: Consider backing up the database periodically in production

---

## Dependencies Added

Make sure these are in your `pubspec.yaml`:
```yaml
dependencies:
  sqflite: ^2.2.8+4
  path: ^1.8.3
  uuid: ^4.0.0  # For generating unique IDs
```

Install dependencies:
```bash
flutter pub get
```

---

## Troubleshooting

### Database Not Persisting
- Ensure app has file system permissions
- Check device storage space

### Slow Performance
- Consider pagination when retrieving large number of records
- Use `getAttendanceByDateRangeLocally()` instead of `getAllAttendanceLocally()` for large datasets

### Sync Issues
- Check internet connection
- Verify authentication token is valid
- Review server errors in logs

---

## Future Enhancements

- Implement encryption for sensitive data
- Add backup and restore functionality
- Implement data pagination
- Add search and filter capabilities
- Implement scheduled sync with retry logic
