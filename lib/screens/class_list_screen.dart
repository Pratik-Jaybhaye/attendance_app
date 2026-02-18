import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/student.dart';
import 'select_classes_screen.dart';

/// Class List / Acculekhaa Screen
/// This screen displays all students in a specific class with their enrollment status.
/// Users can see which students have face data enrolled and proceed to take attendance.
///
/// Screenshots reference: First screenshot showing class list with students
class ClassListScreen extends StatefulWidget {
  final String className;
  final ClassModel classData;

  const ClassListScreen({
    super.key,
    required this.className,
    required this.classData,
  });

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  late ClassModel _classData;

  @override
  void initState() {
    super.initState();
    _classData = widget.classData;
  }

  /// Navigate to attendance taking screen
  void _takeAttendance() {
    Navigator.of(
      context,
    ).pushNamed('/take-attendance', arguments: {'classData': _classData});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_classData.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Statistics Card
            _buildStatisticsCard(),
            const SizedBox(height: 24.0),

            // Student List
            Text(
              'Students in ${_classData.name}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            _buildStudentList(),
            const SizedBox(height: 24.0),

            // Take Attendance Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _classData.enrolledStudentsCount > 0
                    ? _takeAttendance
                    : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Attendance'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build statistics card showing enrollment summary
  Widget _buildStatisticsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.purple.shade100,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          _buildStatItem(
            'Total Students',
            _classData.students.length.toString(),
          ),
          const SizedBox(height: 8.0),
          _buildStatItem(
            'With Face Data',
            _classData.enrolledStudentsCount.toString(),
          ),
          const SizedBox(height: 8.0),
          _buildStatItem('Pending', _classData.pendingStudentsCount.toString()),
        ],
      ),
    );
  }

  /// Build individual statistic item
  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Build list of students with their enrollment status
  Widget _buildStudentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _classData.students.length,
      itemBuilder: (context, index) {
        final student = _classData.students[index];
        return _buildStudentCard(student);
      },
    );
  }

  /// Build individual student card
  Widget _buildStudentCard(Student student) {
    final statusColor = student.enrollmentStatus == 'enrolled'
        ? Colors.green
        : student.enrollmentStatus == 'pending'
        ? Colors.orange
        : Colors.red;

    final statusText = student.enrollmentStatus == 'no_photo'
        ? 'No photo'
        : student.enrollmentStatus == 'enrolled'
        ? 'Enrolled (${student.enrolledPhotosCount} photos)'
        : 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Student Avatar
            CircleAvatar(
              radius: 32.0,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: student.profileImagePath != null
                  ? AssetImage(student.profileImagePath!)
                  : null,
              child: student.profileImagePath == null
                  ? Icon(Icons.person, size: 32.0, color: Colors.grey.shade700)
                  : null,
            ),
            const SizedBox(width: 12.0),

            // Student Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Roll: ${student.rollNumber}',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Status Indicator with Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    student.enrollmentStatus == 'enrolled'
                        ? Icons.check_circle
                        : student.enrollmentStatus == 'pending'
                        ? Icons.schedule
                        : Icons.cancel,
                    color: statusColor,
                    size: 16.0,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
