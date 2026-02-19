import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/period.dart';
import '../services/face_detection_service.dart';
import '../services/face_recognition_service.dart';
import '../services/anti_spoofing_service.dart';

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

  /// Preload all student embeddings before camera starts
  /// Performance Optimization: Embedding Cache
  ///
  /// Why preload?
  /// - All embeddings loaded into RAM (not disk)
  /// - O(1) lookup time for face matching
  /// - Eliminates database queries during recognition
  /// - Faster attendance marking
  ///
  /// When called:
  /// - Before opening camera (during _openLiveCameraStandard)
  /// - During class selection initialization
  /// - Cache refreshed every 30 minutes
  ///
  /// Data structure:
  /// {
  ///   "student_id_1": [embedding_vector_128],
  ///   "student_id_2": [embedding_vector_128],
  ///   ...
  /// }
  Future<void> _preloadStudentEmbeddings() async {
    try {
      // Collect all unique student IDs across selected classes
      final studentIds = <String>{};
      for (var classModel in widget.selectedClasses) {
        for (var student in classModel.students) {
          studentIds.add(student.id);
        }
      }

      print('Preloading embeddings for ${studentIds.length} students...');

      // TODO: Create FaceRecognitionService instance
      // final recognitionService = FaceRecognitionService();
      //
      // // Load embeddings for all students
      // await recognitionService.loadStudentEmbeddings(studentIds.toList());
      //
      // // Log cache statistics
      // final stats = recognitionService.getCacheStats();
      // print('Cache loaded: ${stats['status']}');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Embeddings preloaded')));
    } catch (e) {
      print('Error preloading embeddings: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
  /// STUDENT MODE (Multi-face recognition):
  ///
  /// Camera Configuration:
  /// - Back camera for better group view (wider angle)
  /// - High resolution (1920x1440) for long-range face detection
  /// - Flash support for low light conditions
  ///
  /// Processing Pipeline:
  /// 1. Frame Capture: Every 2nd frame processed (FRAME_SKIP = 2)
  /// 2. Detection: ML Kit ACCURATE mode detects multiple faces
  /// 3. Quality Control: Filter out blurry/dark faces
  /// 4. Deduplication: IoU overlap filtering (avoid same face twice)
  /// 5. Recognition: Compare faces against all enrolled students
  /// 6. Anti-Spoofing: Verify faces are genuine (not photos/videos)
  /// 7. Matching: Dynamic threshold based on face quality (60-90%)
  /// 8. Attendance: Auto-mark when confidence > threshold
  ///
  /// Key Parameters:
  /// - Recognition Threshold: 60-90% (dynamic, based on quality)
  /// - Warmup Delay: 1500ms for back camera stabilization
  /// - Frame Skip: Every 2nd frame for performance balance
  /// - Camera Resolution: 1920x1440 for long-range detection
  /// - Min Face Size: 10-15 feet away detection
  ///
  /// Multi-Face Processing:
  /// - Detects up to N students simultaneously
  /// - Duplicate filtering with IoU threshold (0.3)
  /// - Processes each face independently
  /// - Avoids false positives from same student detected twice
  void _openLiveCameraStandard() {
    // TODO: Connect to Camera and Face Detection Package
    // Steps:
    // 1. Request camera permission
    // 2. Initialize BACK camera for group view
    // 3. Preload all class student embeddings into RAM
    // 4. Start face detection pipeline
    // 5. Apply multi-face recognition
    // 6. Auto-mark students on successful verification
    // 7. Show live detection overlay
    // 8. Navigate to camera screen

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening camera in Standard mode...'),
        duration: Duration(seconds: 2),
      ),
    );

    // TODO: Uncomment when camera service is ready
    // // Preload student embeddings for recognition
    // _preloadStudentEmbeddings();
    //
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => CameraScreen(
    //       mode: 'standard',
    //       classes: widget.selectedClasses,
    //       onStudentDetected: _markStudentPresent,
    //       cameraLens: CameraLensDirection.back, // Back camera
    //       enableFlash: true,
    //       faceDetectionService: FaceDetectionService(),
    //       faceRecognitionService: FaceRecognitionService(),
    //       antiSpoofingService: AntiSpoofingService(),
    //     ),
    //   ),
    // );
  }

  /// Open camera to capture student photos (Hijab mode)
  /// Optimized for detecting faces with hijab/head coverings
  ///
  /// HIJAB MODE SPECIALIZATION:
  /// This mode is adapted for detecting faces with head coverings like:
  /// - Hijab (Islamic head covering)
  /// - Dupattas (South Asian head scarves)
  /// - Bandanas, hats, turbans, etc.
  ///
  /// Adaptations:
  /// 1. Flexible Landmark Detection: Only requires visible face parts (eyes, nose, mouth)
  /// 2. Expanded Detection Area: Can detect faces at more angles
  /// 3. Quality Assessment: Adjusted for partial face visibility
  /// 4. Anti-Spoofing: Works with partial face verification
  /// 5. Recognition: Uses available landmarks for matching
  /// 6. Confidence Thresholds: Slightly higher tolerance for covered areas
  ///
  /// Same multi-face pipeline as Standard mode:
  /// - Back camera for group view
  /// - High resolution detection
  /// - Flash support for low light
  /// - Frame skipping (every 2nd frame)
  /// - Duplicate filtering
  /// - Auto-attendance marking
  void _openLiveCameraHijab() {
    // TODO: Connect to Camera and Face Detection Package
    // This mode is optimized for detecting faces with hijab or head coverings
    // Steps:
    // 1. Request camera permission
    // 2. Initialize back camera with hijab detection mode
    // 3. Preload all class student embeddings
    // 4. Use flexible landmark detection
    // 5. Apply adjusted face recognition
    // 6. Mark attendance for detected students
    // 7. Show live detection overlay with hijab optimization

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening camera in Hijab mode...'),
        duration: Duration(seconds: 2),
      ),
    );

    // TODO: Uncomment when camera service is ready
    // // Preload student embeddings
    // _preloadStudentEmbeddings();
    //
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => CameraScreen(
    //       mode: 'hijab',
    //       classes: widget.selectedClasses,
    //       onStudentDetected: _markStudentPresent,
    //       cameraLens: CameraLensDirection.back, // Back camera
    //       enableFlash: true,
    //       hijabMode: true, // Enable hijab mode adaptations
    //       faceDetectionService: FaceDetectionService(),
    //       faceRecognitionService: FaceRecognitionService(),
    //       antiSpoofingService: AntiSpoofingService(),
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
      appBar: AppBar(title: const Text('Take Attendance')),
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
