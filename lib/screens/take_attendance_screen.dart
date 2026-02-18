import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/period.dart';

/// Take Attendance Screen
/// Main screen for capturing student attendance using face recognition.
/// Features:
/// - Live camera capture (Standard and Hijab modes)
/// - Class overview with total, present, and remaining students
/// - View current attendance progress
/// - Submit attendance to backend
///
/// Screenshots reference: Fifth screenshot showing Take Attendance interface
class TakeAttendanceScreen extends StatefulWidget {
  final List<ClassModel> selectedClasses;
  final Period selectedPeriod;

  const TakeAttendanceScreen({
    super.key,
    required this.selectedClasses,
    required this.selectedPeriod,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  /// Track which students are marked present
  /// Map: classId -> Set of student IDs marked present
  late Map<String, Set<String>> _presentStudents;

  @override
  void initState() {
    super.initState();
    _initializePresentStudentsMap();
  }

  /// Initialize the present students tracking map
  void _initializePresentStudentsMap() {
    _presentStudents = {};
    for (var classModel in widget.selectedClasses) {
      _presentStudents[classModel.id] = {};
    }
  }

  /// Get total count of all students across selected classes
  int _getTotalStudents() {
    return widget.selectedClasses.fold(
      0,
      (sum, classModel) => sum + classModel.students.length,
    );
  }

  /// Get total count of students marked present
  int _getPresentCount() {
    return _presentStudents.values.fold(
      0,
      (sum, studentSet) => sum + studentSet.length,
    );
  }

  /// Get remaining students (not yet marked present)
  int _getRemainingCount() {
    return _getTotalStudents() - _getPresentCount();
  }

  /// Open camera to capture student photos (Standard mode)
  void _openLiveCameraStandard() {
    // TODO: Connect to Camera and Face Detection Package
    // Steps:
    // 1. Request camera permission
    // 2. Initialize camera
    // 3. Capture photos of students in real-time
    // 4. Use Google ML Kit Face Detection to detect faces
    // 5. Match detected faces with enrolled student faces
    // 6. Automatically update attendance when match found
    // 7. Navigate to camera screen

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening camera in Standard mode...'),
        duration: Duration(seconds: 2),
      ),
    );

    // TODO: Uncomment when camera service is ready
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => CameraScreen(
    //       mode: 'standard',
    //       classes: widget.selectedClasses,
    //       onStudentDetected: _markStudentPresent,
    //     ),
    //   ),
    // );
  }

  /// Open camera to capture student photos (Hijab mode)
  /// Optimized for detecting faces with hijab/head coverings
  void _openLiveCameraHijab() {
    // TODO: Connect to Camera and Face Detection Package
    // This mode is optimized for detecting faces with hijab or head coverings
    // Steps:
    // 1. Request camera permission
    // 2. Initialize camera with optimized face detection for hijab mode
    // 3. Capture photos focusing on visible face parts
    // 4. Use adjusted ML Kit face detection model
    // 5. Match detected faces with enrolled student faces
    // 6. Update attendance accordingly

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening camera in Hijab mode...'),
        duration: Duration(seconds: 2),
      ),
    );

    // TODO: Uncomment when camera service is ready
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => CameraScreen(
    //       mode: 'hijab',
    //       classes: widget.selectedClasses,
    //       onStudentDetected: _markStudentPresent,
    //     ),
    //   ),
    // );
  }

  /// Mark a student as present based on face detection result
  ///
  /// [classId] - ID of the class the student belongs to
  /// [studentId] - ID of the detected student
  void _markStudentPresent(String classId, String studentId) {
    setState(() {
      _presentStudents[classId]?.add(studentId);
    });
  }

  /// Navigate to view attendance details
  void _viewAttendance() {
    // TODO: Create ViewAttendanceScreen showing:
    // - List of students with attendance status
    // - Ability to manually mark/unmark students
    // - Option to submit attendance

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View Attendance - Coming Soon')),
    );
  }

  /// Submit attendance to backend
  void _submitAttendance() {
    // TODO: Connect to Backend API
    // Endpoint: POST /api/attendance/submit
    // Send:
    // - Selected classes
    // - Selected period
    // - Student attendance data
    // - Remarks (if any)

    // Validate that some attendance has been taken
    if (_getPresentCount() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark at least one student as present'),
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Period: ${widget.selectedPeriod.name}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Total Present: ${_getPresentCount()}/${_getTotalStudents()}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Submit to backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance submitted successfully'),
                ),
              );
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _getTotalStudents();
    final presentCount = _getPresentCount();
    final remainingCount = _getRemainingCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Start Info Card
            _buildQuickStartCard(),
            const SizedBox(height: 20.0),

            // Camera Capture Section
            _buildCapturePhotosSection(),
            const SizedBox(height: 20.0),

            // Class Overview Section
            _buildClassOverviewSection(
              totalStudents,
              presentCount,
              remainingCount,
            ),
            const SizedBox(height: 20.0),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewAttendance,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Attendance'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: presentCount > 0 ? _submitAttendance : null,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build Quick Start information card
  Widget _buildQuickStartCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.purple.shade700),
              const SizedBox(width: 8.0),
              Text(
                'Quick Start:',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildQuickStartStep(
            '1.',
            'Use Live Camera to capture student photos',
          ),
          const SizedBox(height: 8.0),
          _buildQuickStartStep(
            '2.',
            'Ensure faces are well-lit and clearly visible',
          ),
          const SizedBox(height: 8.0),
          _buildQuickStartStep('3.', 'View and submit attendance'),
        ],
      ),
    );
  }

  /// Build individual quick start step
  Widget _buildQuickStartStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8.0),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14.0))),
      ],
    );
  }

  /// Build camera capture buttons section
  Widget _buildCapturePhotosSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capture Photos',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),

          // Standard mode button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openLiveCameraStandard,
              icon: const Icon(Icons.videocam),
              label: const Text('Live Camera - Standard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                backgroundColor: Colors.purple,
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Hijab mode button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openLiveCameraHijab,
              icon: const Icon(Icons.videocam),
              label: const Text('Live Camera - Hijab'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build class overview statistics section
  Widget _buildClassOverviewSection(int total, int present, int remaining) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class Overview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20.0),

          // Statistics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Total', total.toString(), Colors.purple),
              _buildStatBox('Present', present.toString(), Colors.green),
              _buildStatBox('Remaining', remaining.toString(), Colors.red),
            ],
          ),
          const SizedBox(height: 20.0),

          // View Attendance Link
          Center(
            child: GestureDetector(
              onTap: _viewAttendance,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.purple.shade700,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'View Attendance',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual statistic box
  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
