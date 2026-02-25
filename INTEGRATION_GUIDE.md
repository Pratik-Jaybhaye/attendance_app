# Integration Guide - Where to Add Database Functionality

This guide shows you exactly where to add the local database code to your existing screens.

---

## 1. TAKE ATTENDANCE SCREEN - Save After Marking

### File: `lib/screens/take_attendance_screen.dart`

#### Step 1: Add Imports at Top
```dart
import 'package:attendance_app/services/attendance_service.dart';
import 'package:attendance_app/models/attendance_record.dart';
import 'package:uuid/uuid.dart';  // Add this line
```

#### Step 2: Add Save Method to State Class
```dart
class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  // ... existing code ...

  // ADD THIS METHOD:
  Future<void> _saveAttendanceLocally() async {
    try {
      // Get student attendance data (adjust based on your implementation)
      final Map<String, bool> studentAttendanceMap = {};
      // TODO: Populate with your actual student attendance data
      // Example: studentAttendanceMap['student_id'] = isPresent;
      
      // Create attendance record
      final record = AttendanceRecord(
        id: const Uuid().v4(),
        classId: widget.classId,  // Adjust if your variable name is different
        periodId: widget.periodId,
        dateTime: DateTime.now(),
        studentAttendance: studentAttendanceMap,
        remarks: 'Face recognition capture',
        isSubmitted: false,
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
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back
        Navigator.pop(context, {
          'success': true,
          'recordId': record.id,
        });
      } else {
        throw Exception('Database save failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

#### Step 3: Call the Save Method
Replace your current save/submit button handler with:
```dart
// BEFORE: You might have something like:
// if (await markAttendance()) { ... }

// AFTER: 
ElevatedButton(
  onPressed: () async {
    // First verify attendance is marked
    if (studentAttendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark attendance first')),
      );
      return;
    }
    
    // Then save to database
    await _saveAttendanceLocally();
  },
  child: const Text('Save & Submit Attendance'),
)
```

---

## 2. ATTENDANCE LOGS SCREEN - Display Saved Records

### File: `lib/screens/attendance_logs_screen.dart` or `lib/screens/view_attendance_screen.dart`

#### Step 1: Add Imports
```dart
import 'package:attendance_app/services/attendance_service.dart';
```

#### Step 2: Replace/Update Your Records Display
```dart
class AttendanceLogsScreen extends StatelessWidget {
  const AttendanceLogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Logs')),
      body: FutureBuilder(
        // CHANGE THIS: Use the new database method
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
            return const Center(
              child: Text('No attendance records found'),
            );
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final dateStr = record.dateTime.toString().split('.')[0];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(record.classId),
                  subtitle: Text(
                    'Date: $dateStr\n'
                    'Present: ${record.presentCount} | Absent: ${record.absentCount}',
                  ),
                  trailing: Chip(
                    label: Text(record.isSubmitted ? 'Synced' : 'Local'),
                    backgroundColor: record.isSubmitted 
                        ? Colors.green[100] 
                        : Colors.orange[100],
                  ),
                  onTap: () {
                    // Show details
                    _showRecordDetails(context, record);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRecordDetails(BuildContext context, dynamic record) {
    // Show detailed view of the record
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attendance Details - ${record.classId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${record.dateTime}'),
            Text('Period: ${record.periodId}'),
            Text('Present: ${record.presentCount}'),
            Text('Absent: ${record.absentCount}'),
            if (record.remarks.isNotEmpty) Text('Remarks: ${record.remarks}'),
            Text('Status: ${record.isSubmitted ? "Synced" : "Local"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. FILTER BY CLASS - If You Have a Class-Specific View

### File: `lib/screens/class_list_screen.dart` or similar

```dart
// When navigating to view attendance for a specific class:
FutureBuilder(
  future: AttendanceService.getAttendanceByClassLocally('class_123'),
  builder: (context, snapshot) {
    // Same builder code as above
    // ...
  },
)
```

---

## 4. HOME/DASHBOARD SCREEN - Show Summary Statistics

### File: `lib/screens/home_screen.dart`

#### Add to Your Dashboard
```dart
FutureBuilder(
  future: Future.wait([
    AttendanceService.getTotalAttendanceCountLocally(),
    AttendanceService.getUnsubmittedAttendanceLocally(),
  ]),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }

    final totalRecords = snapshot.data?[0] as int? ?? 0;
    final unsubmittedCount = (snapshot.data?[1] as List?)?.length ?? 0;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Total Records'),
                    Text(
                      '$totalRecords',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Pending Sync'),
                    Text(
                      '$unsubmittedCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (unsubmittedCount > 0)
          ElevatedButton(
            onPressed: () => _syncWithBackend(context),
            child: const Text('Sync Now'),
          ),
      ],
    );
  },
)
```

#### Add Sync Method
```dart
Future<void> _syncWithBackend(BuildContext context) async {
  // Show loading
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Syncing...')),
  );

  // Get auth token (adjust based on your auth implementation)
  final token = getAuthToken(); // Your method

  // Sync
  final synced = await AttendanceService.syncAttendanceWithBackend(
    token: token,
  );

  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(synced ? '✓ Sync successful' : '✗ Sync failed'),
      backgroundColor: synced ? Colors.green : Colors.red,
    ),
  );

  // Refresh UI
  setState(() {});
}
```

---

## 5. SETTINGS/CLEANUP SCREEN - Delete Old Records (Optional)

### Add to Your Settings Screen
```dart
ListTile(
  title: const Text('Clear Old Attendance'),
  subtitle: const Text('Delete records older than 90 days'),
  onTap: () => _clearOldAttendance(context),
)

// Add method:
Future<void> _clearOldAttendance(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear Old Records?'),
      content: const Text('Delete attendance records older than 90 days?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
    final deleted = await DatabaseHelper().deleteOldAttendanceRecords(ninetyDaysAgo);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deleted ? 'Old records deleted' : 'Error deleting records'),
      ),
    );
  }
}
```

---

## 6. DATE RANGE FILTER - Show Attendance for Specific Period

### Example Usage:
```dart
Future<void> _showAttendanceForDateRange() async {
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2024, 1, 1),
    lastDate: DateTime.now(),
  );

  if (picked != null) {
    final records = await AttendanceService.getAttendanceByDateRangeLocally(
      picked.start,
      picked.end,
    );
    
    // Display records
    _displayRecords(records);
  }
}
```

---

## Summary of Changes

| Screen | Change | Priority |
|--------|--------|----------|
| Take Attendance | Add save to database | 🔴 HIGH |
| Attendance Logs | Display from database | 🔴 HIGH |
| Home/Dashboard | Show stats | 🟡 MEDIUM |
| Settings | Optional cleanup | 🟢 LOW |

---

## Testing Your Integration

After adding the code:

1. **Build the app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Save**:
   - Mark attendance in your app
   - Click save
   - Check for success message

3. **Test Retrieve**:
   - Go to attendance logs
   - Verify records appear

4. **Test Offline**:
   - Disable internet (if not using API yet)
   - Mark attendance
   - Verify it saves locally

---

## Troubleshooting Integration

### App won't compile
- Run `flutter clean && flutter pub get`
- Check imports are correct
- Check dependencies in pubspec.yaml

### Records not saving
- Check logcat/debug console for error messages
- Verify `saveAttendanceLocally()` is being called
- Check you're creating valid AttendanceRecord objects

### Records not displaying
- Verify database has records (check database_helper.dart logs)
- Check `getAllAttendanceLocally()` is being called
- Verify your FutureBuilder is wired correctly

### Sync not working
- Check if you're calling `syncAttendanceWithBackend()` with a valid token
- Update sync method with actual API endpoint when backend is ready

---

## Full Example Workflow

```dart
// User Flow:
// 1. User goes to Take Attendance Screen
// 2. Marks attendance for students using face recognition
// 3. Clicks "Save" button
// 4. _saveAttendanceLocally() is called
// 5. Record saved to SQLite database
// 6. Success message shown
// 7. User navigates back
// 
// 8. User goes to Attendance Logs Screen
// 9. Screen shows all records from database
// 10. User can see local vs synced records
// 
// 11. When internet available, user clicks "Sync"
// 12. syncAttendanceWithBackend() uploads all unsynced records
// 13. Records marked as submitted in database
```

---

## Next: Connect Backend

When your backend API is ready:

1. Update `syncAttendanceWithBackend()` in `attendance_service.dart`
2. Replace mock implementation with actual API calls
3. Each record will be uploaded and marked as submitted

See `LOCAL_DATABASE_SETUP.md` for API integration examples.

---

**You're all set to integrate local database into your app!** 🎉
