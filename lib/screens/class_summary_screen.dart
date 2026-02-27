import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/period.dart';
import '../models/student.dart';
import 'upload_multiple_photos_screen.dart';
import 'take_attendance_screen.dart';

/// Class Summary Screen
/// Displayed after selecting a period. Shows class statistics and allows
/// users to manage student photos before taking attendance.
/// 
/// Features:
/// - Display total students, with face data, pending count
/// - Show student photo with edit option
/// - Navigate to take attendance or photo upload
class ClassSummaryScreen extends StatefulWidget {
  final List<ClassModel> selectedClasses;
  final Period selectedPeriod;

  const ClassSummaryScreen({
    super.key,
    required this.selectedClasses,
    required this.selectedPeriod,
  });

  @override
  State<ClassSummaryScreen> createState() => _ClassSummaryScreenState();
}

class _ClassSummaryScreenState extends State<ClassSummaryScreen> {
  /// Current selected student for photo display
  Student? _currentSelectedStudent;

  @override
  void initState() {
    super.initState();
    // Initialize with first enrolled student
    _initializeFirstEnrolledStudent();
  }

  /// Initialize with first enrolled student from all classes
  void _initializeFirstEnrolledStudent() {
    for (var classModel in widget.selectedClasses) {
      for (var student in classModel.students) {
        if (student.enrollmentStatus == 'enrolled') {
          setState(() {
            _currentSelectedStudent = student;
          });
          return;
        }
      }
    }
    // If no enrolled student, select first student
    if (widget.selectedClasses.isNotEmpty &&
        widget.selectedClasses[0].students.isNotEmpty) {
      setState(() {
        _currentSelectedStudent = widget.selectedClasses[0].students[0];
      });
    }
  }

  /// Get total students across all selected classes
  int _getTotalStudents() {
    return widget.selectedClasses.fold(
      0,
      (sum, classModel) => sum + classModel.students.length,
    );
  }

  /// Get total students with face data (enrolled)
  int _getWithFaceDataCount() {
    int count = 0;
    for (var classModel in widget.selectedClasses) {
      count += classModel.enrolledStudentsCount;
    }
    return count;
  }

  /// Get total pending students
  int _getPendingCount() {
    int count = 0;
    for (var classModel in widget.selectedClasses) {
      count += classModel.pendingStudentsCount;
    }
    return count;
  }

  /// Navigate to upload multiple photos screen
  void _editPhotos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UploadMultiplePhotosScreen(
          student: _currentSelectedStudent ?? widget.selectedClasses[0].students[0],
          onPhotosUploaded: _onPhotosUploaded,
        ),
      ),
    );
  }

  /// Callback when photos are uploaded
  void _onPhotosUploaded() {
    // Refresh the student data if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photos uploaded successfully')),
    );
  }

  /// Navigate to take attendance screen
  void _proceedToTakeAttendance() {
    if (_getWithFaceDataCount() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enroll at least one student before taking attendance'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TakeAttendanceScreen(
          selectedClasses: widget.selectedClasses,
          selectedPeriod: widget.selectedPeriod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _getTotalStudents();
    final withFaceData = _getWithFaceDataCount();
    final pending = _getPendingCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Summary'),
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
            // Statistics Card
            _buildStatisticsCard(totalStudents, withFaceData, pending),
            const SizedBox(height: 24.0),

            // Student Photo Section
            _buildStudentPhotoSection(),
            const SizedBox(height: 24.0),

            // Class List
            _buildClassList(),
            const SizedBox(height: 24.0),

            // Take Attendance Button (Bottom Right)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _proceedToTakeAttendance,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Attendance'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  backgroundColor: Colors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build statistics card showing enrollment summary
  Widget _buildStatisticsCard(int total, int withFaceData, int pending) {
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
          _buildStatItem('Total Students', total.toString()),
          const SizedBox(height: 12.0),
          _buildStatItem('With Face Data', withFaceData.toString()),
          const SizedBox(height: 12.0),
          _buildStatItem('Pending', pending.toString()),
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
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  /// Build student photo section with edit button
  Widget _buildStudentPhotoSection() {
    if (_currentSelectedStudent == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text('No student selected'),
        ),
      );
    }

    final student = _currentSelectedStudent!;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Student Name
          Text(
            student.name,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          // Student Roll
          Text(
            'Roll: ${student.rollNumber}',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16.0),

          // Student Photo Placeholder
          Container(
            width: 150.0,
            height: 150.0,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: student.enrollmentStatus == 'enrolled'
                ? const Icon(Icons.person, size: 80.0, color: Colors.grey)
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_photo_alternate, size: 40.0, color: Colors.grey),
                    SizedBox(height: 8.0),
                    Text(
                      'No Photo',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 16.0),

          // Enrollment Status
          if (student.enrollmentStatus == 'enrolled')
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                '✓ Enrolled (${student.enrolledPhotosCount} photo${student.enrolledPhotosCount > 1 ? 's' : ''})',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (student.enrollmentStatus == 'pending')
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Text(
                '⏳ Pending',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                '✗ No Photo',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16.0),

          // Edit Photo Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _editPhotos,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build class list
  Widget _buildClassList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Classes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.selectedClasses.length,
          itemBuilder: (context, index) {
            final classModel = widget.selectedClasses[index];
            return _buildClassCard(classModel);
          },
        ),
      ],
    );
  }

  /// Build individual class card
  Widget _buildClassCard(ClassModel classModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                classModel.name,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '${classModel.students.length} students',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${classModel.enrolledStudentsCount} enrolled',
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '${classModel.pendingStudentsCount} pending',
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
