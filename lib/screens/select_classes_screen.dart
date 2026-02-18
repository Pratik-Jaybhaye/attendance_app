import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/student.dart';
import 'class_list_screen.dart';
import 'select_period_screen.dart';

/// Select Classes Screen
/// This screen allows users to select one or two classes for attendance taking.
/// Based on classroom selection, users can proceed to select the period.
///
/// Screenshots reference: Third screenshot showing "Select Classes" with radio buttons
class SelectClassesScreen extends StatefulWidget {
  const SelectClassesScreen({super.key});

  @override
  State<SelectClassesScreen> createState() => _SelectClassesScreenState();
}

class _SelectClassesScreenState extends State<SelectClassesScreen> {
  // TODO: Connect to Backend API
  // Endpoint: GET /api/classes
  // Fetch all available classes from backend
  final List<ClassModel> _availableClasses = [
    ClassModel(
      id: '1',
      name: 'Acculekhaa',
      grade: '',
      students: [
        Student(
          id: '1',
          name: 'Ramesh',
          rollNumber: '9999999999',
          enrollmentStatus: 'no_photo',
        ),
        Student(
          id: '2',
          name: 'Swathi',
          rollNumber: '10021002',
          enrollmentStatus: 'enrolled',
          enrolledPhotosCount: 5,
        ),
        Student(
          id: '3',
          name: 'Jhansi',
          rollNumber: '10021004',
          enrollmentStatus: 'enrolled',
          enrolledPhotosCount: 4,
        ),
        Student(
          id: '4',
          name: 'M Swamy',
          rollNumber: '10021005',
          enrollmentStatus: 'enrolled',
          enrolledPhotosCount: 5,
        ),
        Student(
          id: '5',
          name: 'K V Shekher',
          rollNumber: '10021006',
          enrollmentStatus: 'enrolled',
          enrolledPhotosCount: 4,
        ),
      ],
    ),
    ClassModel(
      id: '2',
      name: 'II-A',
      grade: '',
      students: [
        Student(
          id: '10',
          name: 'Student 1',
          rollNumber: '20010001',
          enrollmentStatus: 'enrolled',
          enrolledPhotosCount: 3,
        ),
        Student(
          id: '11',
          name: 'Student 2',
          rollNumber: '20010002',
          enrollmentStatus: 'enrolled',
          enrolledPhotosCount: 4,
        ),
      ],
    ),
    ClassModel(
      id: '3',
      name: 'II-B',
      grade: '',
      students: [
        Student(
          id: '20',
          name: 'Student B1',
          rollNumber: '20020001',
          enrollmentStatus: 'enrolled',
          enrolledPhotosCount: 2,
        ),
      ],
    ),
  ];

  /// Selected classes - can select 1-2 classes
  final Set<String> _selectedClassIds = {};

  /// Proceed to period selection
  void _proceedToPeriodSelection() {
    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class')),
      );
      return;
    }

    final selectedClasses = _availableClasses
        .where((cls) => _selectedClassIds.contains(cls.id))
        .toList();

    // TODO: Connect to Backend API
    // Endpoint: POST /api/attendance/start
    // Send selected classes to backend

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SelectPeriodScreen(selectedClasses: selectedClasses),
      ),
    );
  }

  /// View class details and students
  void _viewClassDetails(ClassModel classModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ClassListScreen(className: classModel.name, classData: classModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Classes'),
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
            // Instruction text
            Text(
              'Select Classes (${_selectedClassIds.length}/2)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Tap to select classes for attendance',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24.0),

            // Classes list
            _buildClassesList(),
            const SizedBox(height: 24.0),

            // Proceed button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedClassIds.isNotEmpty
                    ? _proceedToPeriodSelection
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Next: Select Period'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build list of available classes
  Widget _buildClassesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableClasses.length,
      itemBuilder: (context, index) {
        final classModel = _availableClasses[index];
        final isSelected = _selectedClassIds.contains(classModel.id);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedClassIds.remove(classModel.id);
              } else {
                // Allow maximum 2 classes selection
                if (_selectedClassIds.length < 2) {
                  _selectedClassIds.add(classModel.id);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maximum 2 classes can be selected'),
                    ),
                  );
                }
              }
            });
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            elevation: isSelected ? 4.0 : 0.0,
            color: isSelected ? Colors.purple.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(
                color: isSelected ? Colors.purple : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Radio button
                  Radio<String>(
                    value: classModel.id,
                    groupValue: _selectedClassIds.length == 1
                        ? _selectedClassIds.first
                        : null,
                    onChanged: (value) {
                      setState(() {
                        if (isSelected) {
                          _selectedClassIds.remove(classModel.id);
                        } else {
                          if (_selectedClassIds.length < 2) {
                            _selectedClassIds.add(classModel.id);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 12.0),

                  // Class information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classModel.name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (classModel.grade.isNotEmpty)
                          Text(
                            'Grade: ${classModel.grade}',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${classModel.students.length} students',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Checkbox for selection
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (isSelected) {
                            _selectedClassIds.remove(classModel.id);
                          } else {
                            if (_selectedClassIds.length < 2) {
                              _selectedClassIds.add(classModel.id);
                            }
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
