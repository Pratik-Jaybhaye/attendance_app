import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/period.dart';
import '../models/student.dart';
import 'take_attendance_screen.dart';

/// View Attendance Screen
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
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _presentStudents = {
      for (var entry in widget.presentStudents.entries)
        entry.key: {...entry.value},
    };
  }

  void _toggleStudentAttendance(String classId, String studentId) {
    setState(() {
      if (_presentStudents[classId]!.contains(studentId)) {
        _presentStudents[classId]!.remove(studentId);
      } else {
        _presentStudents[classId]!.add(studentId);
      }
    });
  }

  int _getTotalStudents() {
    return widget.selectedClasses.fold(
      0,
      (sum, classModel) => sum + classModel.students.length,
    );
  }

  int _getPresentCount() {
    return _presentStudents.values.fold(
      0,
      (sum, studentSet) => sum + studentSet.length,
    );
  }

  int _getRemainingCount() {
    return _getTotalStudents() - _getPresentCount();
  }

  void _goBack() {
    Navigator.pop(context, _presentStudents);
  }

  void _goToTakeAttendance() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TakeAttendanceScreen(
          selectedClasses: widget.selectedClasses,
          selectedPeriod: widget.selectedPeriod,
        ),
      ),
    );
  }

  List<Student> _getFilteredStudents() {
    final students = <Student>[];

    for (var classModel in widget.selectedClasses) {
      for (var student in classModel.students) {
        final isPresent =
            _presentStudents[classModel.id]?.contains(student.id) ?? false;

        switch (_selectedTab) {
          case 'present':
            if (isPresent) students.add(student);
            break;
          case 'absent':
            if (!isPresent) students.add(student);
            break;
          case 'all':
          default:
            students.add(student);
            break;
        }
      }
    }

    return students;
  }

  String _getClassIdForStudent(Student student) {
    for (var classModel in widget.selectedClasses) {
      if (classModel.students.any((s) => s.id == student.id)) {
        return classModel.id;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _getTotalStudents();
    final presentCount = _getPresentCount();
    final remainingCount = _getRemainingCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttendanceSummary(
                    totalStudents,
                    presentCount,
                    remainingCount,
                  ),
                  const SizedBox(height: 20.0),
                  _buildTabs(totalStudents, presentCount, remainingCount),
                  const SizedBox(height: 20.0),
                  _buildStudentList(),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(int total, int present, int remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Attendance Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(
                Icons.people,
                total.toString(),
                'Total',
                Colors.purple,
              ),
              _buildStatColumn(
                Icons.check_circle,
                present.toString(),
                'Present',
                Colors.green,
              ),
              _buildStatColumn(
                Icons.cancel,
                remaining.toString(),
                'Remaining',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.0),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(label, style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTabs(int total, int present, int absent) {
    return Row(
      children: [
        _buildTabButton('all', 'All ($total)', _selectedTab == 'all'),
        const SizedBox(width: 12.0),
        _buildTabButton(
          'present',
          'Present ($present)',
          _selectedTab == 'present',
        ),
        const SizedBox(width: 12.0),
        _buildTabButton('absent', 'Absent ($absent)', _selectedTab == 'absent'),
      ],
    );
  }

  Widget _buildTabButton(String tabId, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelected ? Colors.purple : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final filteredStudents = _getFilteredStudents();

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.person_off, size: 48.0, color: Colors.grey.shade400),
            const SizedBox(height: 12.0),
            Text(
              'No students in this category',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showing: ${filteredStudents.length} of ${_getTotalStudents()}',
          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredStudents.length,
          itemBuilder: (context, index) {
            final student = filteredStudents[index];
            final classId = _getClassIdForStudent(student);
            final isPresent =
                _presentStudents[classId]?.contains(student.id) ?? false;

            return _buildStudentCard(student, classId, isPresent);
          },
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student, String classId, bool isPresent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isPresent ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Roll: ${student.rollNumber}',
                style: TextStyle(fontSize: 12.0, color: Colors.grey.shade700),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _toggleStudentAttendance(classId, student.id),
            child: Container(
              width: 50.0,
              height: 30.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: isPresent ? Colors.green : Colors.grey.shade400,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: isPresent ? 20.0 : 2.0,
                    child: Container(
                      width: 26.0,
                      height: 26.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13.0),
                        color: Colors.white,
                      ),
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

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _goToTakeAttendance,
              icon: const Icon(Icons.camera_alt),
              label: const Text('More Photos'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                backgroundColor: Colors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
