import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/period.dart';

/// View Attendance Screen
/// This screen shows the current attendance status for all students
/// in the selected classes. Users can manually adjust attendance
/// (mark/unmark students) before final submission.
class ViewAttendanceScreen extends StatefulWidget {
  final List<ClassModel> selectedClasses;
  final Period selectedPeriod;
  final Map<String, Set<String>> presentStudents;

  const ViewAttendanceScreen({
    super.key,
    required this.selectedClasses,
    required this.selectedPeriod,
    required this.presentStudents,
  });

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  late Map<String, Set<String>> _presentStudents;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the attendance data
    _presentStudents = {
      for (var entry in widget.presentStudents.entries)
        entry.key: {...entry.value},
    };
  }

  /// Toggle attendance status for a student
  void _toggleStudentAttendance(String classId, String studentId) {
    setState(() {
      if (_presentStudents[classId]!.contains(studentId)) {
        _presentStudents[classId]!.remove(studentId);
      } else {
        _presentStudents[classId]!.add(studentId);
      }
    });
  }

  /// Go back to attendance taking screen with updated data
  void _goBack() {
    Navigator.pop(context, _presentStudents);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Information
            _buildSessionInfo(),
            const SizedBox(height: 20.0),

            // Students List by Class
            _buildStudentsListByClass(),
          ],
        ),
      ),
    );
  }

  /// Build session information card
  Widget _buildSessionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Period: ${widget.selectedPeriod.name}',
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Classes: ${widget.selectedClasses.map((c) => c.name).join(', ')}',
            style: const TextStyle(fontSize: 14.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Date: ${DateTime.now().toString().split(' ')[0]}',
            style: const TextStyle(fontSize: 14.0),
          ),
        ],
      ),
    );
  }

  /// Build students list grouped by class
  Widget _buildStudentsListByClass() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.selectedClasses.map((classModel) {
        final presentCount = _presentStudents[classModel.id]?.length ?? 0;
        final totalCount = classModel.students.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class header with count
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    classModel.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$presentCount/$totalCount',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),

            // Students in this class
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classModel.students.length,
              itemBuilder: (context, index) {
                final student = classModel.students[index];
                final isPresent = _presentStudents[classModel.id]!.contains(
                  student.id,
                );

                return _buildStudentCheckbox(
                  student.name,
                  student.rollNumber,
                  isPresent,
                  () => _toggleStudentAttendance(classModel.id, student.id),
                );
              },
            ),
            const SizedBox(height: 20.0),
          ],
        );
      }).toList(),
    );
  }

  /// Build student checkbox for attendance toggle
  Widget _buildStudentCheckbox(
    String name,
    String rollNumber,
    bool isPresent,
    VoidCallback onToggle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.shade50 : Colors.white,
        border: Border.all(
          color: isPresent ? Colors.green : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: CheckboxListTile(
        value: isPresent,
        onChanged: (_) => onToggle(),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Roll: $rollNumber'),
        activeColor: Colors.green,
      ),
    );
  }
}
