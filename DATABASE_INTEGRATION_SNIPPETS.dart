// Quick Integration Guide - Copy these code snippets to your screens

// ============================================================
// 1. SAVE ATTENDANCE AFTER CAPTURING
// ============================================================
// Add this to your take_attendance_screen.dart or wherever you mark attendance

import 'package:attendance_app/models/attendance_record.dart';
import 'package:attendance_app/services/attendance_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

Future<void> saveAttendanceAfterCapture({
  required String classId,
  required String periodId,
  required Map<String, bool> studentAttendanceMap,
}) async {
  try {
    // Create attendance record with all captured data
    final attendanceRecord = AttendanceRecord(
      id: const Uuid().v4(),
      classId: classId,
      periodId: periodId,
      dateTime: DateTime.now(),
      studentAttendance: studentAttendanceMap,
      remarks: 'Captured using face recognition',
      isSubmitted: false,
    );

    // Save to local database
    final isSaved = await AttendanceService.saveAttendanceLocally(
      attendanceRecord,
    );

    if (isSaved) {
      print('✓ Attendance saved to local database');
      // Show success to user
      // Navigator.pop(context, {'success': true});
    } else {
      print('✗ Failed to save attendance');
      // Show error to user
    }
  } catch (e) {
    print('Error saving attendance: $e');
  }
}

// ============================================================
// 2. RETRIEVE AND DISPLAY ATTENDANCE RECORDS
// ============================================================
// Add this to your attendance_logs_screen.dart

class AttendanceRecordsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
          return const Center(child: Text('No attendance records found'));
        }

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final dateStr = record.dateTime.toString().split('.')[0];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                title: Text('${record.classId} - $dateStr'),
                subtitle: Text(
                  'Present: ${record.presentCount} | Absent: ${record.absentCount}',
                ),
                trailing: record.isSubmitted
                    ? const Chip(label: Text('Synced'))
                    : const Chip(
                        label: Text('Local'),
                        backgroundColor: Colors.orange,
                      ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Period: ${record.periodId}'),
                        const SizedBox(height: 8),
                        Text('Remarks: ${record.remarks}'),
                        const SizedBox(height: 12),
                        const Text(
                          'Student Attendance:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...record.studentAttendance.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  entry.value ? Icons.check : Icons.close,
                                  color: entry.value
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${entry.key}: ${entry.value ? 'Present' : 'Absent'}',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// 3. GET ATTENDANCE FOR SPECIFIC CLASS
// ============================================================

Future<void> displayClassAttendance(String classId) async {
  final records = await AttendanceService.getAttendanceByClassLocally(classId);

  print('Total records for class: ${records.length}');
  for (final record in records) {
    print(
      '${record.dateTime}: ${record.presentCount} present, ${record.absentCount} absent',
    );
  }
}

// ============================================================
// 4. SYNC DATA WITH BACKEND
// ============================================================
// Call this when internet is available

Future<void> syncAttendanceWithBackend(String? authToken) async {
  try {
    print('Starting sync...');

    final synced = await AttendanceService.syncAttendanceWithBackend(
      token: authToken,
    );

    if (synced) {
      print('✓ All records synced successfully');
      // Show success message to user
    } else {
      print('✗ Sync failed');
      // Show error message to user
    }
  } catch (e) {
    print('Error during sync: $e');
  }
}

// ============================================================
// 5. CHECK STATISTICS
// ============================================================

Future<void> printAttendanceStats() async {
  final totalCount = await AttendanceService.getTotalAttendanceCountLocally();
  print('Total attendance records in database: $totalCount');

  final unsubmitted = await AttendanceService.getUnsubmittedAttendanceLocally();
  print('Pending sync records: ${unsubmitted.length}');
}

// ============================================================
// 6. COMPLETE SCREEN INTEGRATION EXAMPLE
// ============================================================

/*
Example: Complete Take Attendance Screen with Database Save

import 'package:flutter/material.dart';
import 'package:attendance_app/models/attendance_record.dart';
import 'package:attendance_app/models/student.dart';
import 'package:attendance_app/services/attendance_service.dart';
import 'package:uuid/uuid.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final String classId;
  final String periodId;
  final List<Student> students;

  const TakeAttendanceScreen({
    required this.classId,
    required this.periodId,
    required this.students,
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
    // Initialize with all students marked as absent by default
    studentAttendance = {
      for (var student in widget.students) student.id: false,
    };
  }

  void _toggleStudentAttendance(String studentId) {
    setState(() {
      studentAttendance[studentId] = !studentAttendance[studentId]!;
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    try {
      // Create attendance record
      final record = AttendanceRecord(
        id: const Uuid().v4(),
        classId: widget.classId,
        periodId: widget.periodId,
        dateTime: DateTime.now(),
        studentAttendance: studentAttendance,
        remarks: 'Marked using face recognition',
        isSubmitted: false,
      );

      // Save to local database
      final saved = await AttendanceService.saveAttendanceLocally(record);

      if (!mounted) return;

      if (saved) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Attendance saved locally'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Return to previous screen
        Navigator.of(context).pop({
          'success': true,
          'recordId': record.id,
        });
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Failed to save attendance'),
            backgroundColor: Colors.red,
          ),
        );
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
    final presentCount = studentAttendance.values.where((v) => v).length;
    final absentCount = studentAttendance.length - presentCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Present'),
                    Text(
                      '$presentCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Absent'),
                    Text(
                      '$absentCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Student List
          Expanded(
            child: ListView.builder(
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                final isPresent = studentAttendance[student.id] ?? false;

                return CheckboxListTile(
                  title: Text(student.name),
                  subtitle: Text(student.rollNumber),
                  value: isPresent,
                  onChanged: (_) {
                    _toggleStudentAttendance(student.id);
                  },
                  secondary: isPresent
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
                );
              },
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAttendance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save Attendance',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

*/

// ============================================================
// 7. DISPLAY STATISTICS IN DASHBOARD
// ============================================================

class AttendanceDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        AttendanceService.getTotalAttendanceCountLocally(),
        AttendanceService.getUnsubmittedAttendanceLocally(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final totalCount = snapshot.data?[0] as int? ?? 0;
        final unsubmittedCount = (snapshot.data?[1] as List?)?.length ?? 0;

        return Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Total Records'),
                trailing: Text(
                  '$totalCount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Pending Sync'),
                trailing: Text(
                  '$unsubmittedCount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
