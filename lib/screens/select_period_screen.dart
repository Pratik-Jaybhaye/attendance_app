import 'package:flutter/material.dart';
import '../models/class.dart';
import '../models/period.dart';
import 'take_attendance_screen.dart';

/// Select Period Screen
/// This screen allows the user to select a specific period/time slot for attendance.
/// Users can also add optional remarks (max 12 characters) for the attendance session.
///
/// Screenshots reference: Second and Fourth screenshots showing period selection
class SelectPeriodScreen extends StatefulWidget {
  final List<ClassModel> selectedClasses;

  const SelectPeriodScreen({super.key, required this.selectedClasses});

  @override
  State<SelectPeriodScreen> createState() => _SelectPeriodScreenState();
}

class _SelectPeriodScreenState extends State<SelectPeriodScreen> {
  // TODO: Connect to Backend API
  // Endpoint: GET /api/periods
  // Fetch available periods from backend
  final List<Period> _availablePeriods = [
    Period(id: '1', name: 'Period-1'),
    Period(id: '2', name: 'Period-2'),
    Period(id: '3', name: 'Period-3'),
    Period(id: '4', name: 'Period-4'),
    Period(id: '5', name: 'Period-5'),
    Period(id: '6', name: 'Period-6'),
    Period(id: '7', name: 'Period-7'),
    Period(id: '8', name: 'Period-8'),
    Period(id: '9', name: 'Period-9'),
    Period(id: '10', name: 'Period-10'),
    Period(id: '11', name: 'Hostel-11'),
    Period(id: '12', name: 'Mess-12'),
  ];

  /// Selected period ID
  String? _selectedPeriodId;

  /// Remarks text controller - max 12 characters
  final TextEditingController _remarksController = TextEditingController();

  /// Character limit for remarks
  static const int _maxRemarksLength = 12;

  @override
  void initState() {
    super.initState();
    // Default select first period
    _selectedPeriodId = _availablePeriods.isNotEmpty
        ? _availablePeriods[0].id
        : null;
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  /// Proceed to attendance taking screen
  void _proceedToAttendance() {
    if (_selectedPeriodId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a period')));
      return;
    }

    final selectedPeriod = _availablePeriods.firstWhere(
      (p) => p.id == _selectedPeriodId,
    );
    selectedPeriod.remarks = _remarksController.text;

    // TODO: Connect to Backend API
    // Endpoint: POST /api/attendance/session/start
    // Send selected classes, period, and remarks

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TakeAttendanceScreen(
          selectedClasses: widget.selectedClasses,
          selectedPeriod: selectedPeriod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Period'),
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
              'Select a period for attendance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20.0),

            // Periods list with radio buttons
            _buildPeriodsList(),
            const SizedBox(height: 24.0),

            // Remarks section
            _buildRemarksSection(),
            const SizedBox(height: 24.0),

            // Proceed button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPeriodId != null
                    ? _proceedToAttendance
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build list of available periods with radio selection
  Widget _buildPeriodsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availablePeriods.length,
      itemBuilder: (context, index) {
        final period = _availablePeriods[index];
        final isSelected = _selectedPeriodId == period.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPeriodId = period.id;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.purple.shade50 : Colors.grey.shade50,
              border: Border.all(
                color: isSelected ? Colors.purple : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                // Radio button
                Radio<String>(
                  value: period.id,
                  groupValue: _selectedPeriodId,
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriodId = value;
                    });
                  },
                  activeColor: Colors.purple,
                ),
                const SizedBox(width: 12.0),

                // Period name
                Text(
                  period.name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build remarks input section
  Widget _buildRemarksSection() {
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
          // Remarks label
          Text(
            'Remarks',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12.0),

          // Remarks text field
          TextField(
            controller: _remarksController,
            maxLength: _maxRemarksLength,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: 'Optional (max $_maxRemarksLength chars)',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 12.0,
              ),
              counterText: '',
            ),
            onChanged: (_) {
              // Trigger rebuild to update character count
              setState(() {});
            },
          ),
          const SizedBox(height: 8.0),

          // Character counter
          Text(
            '${_remarksController.text.length}/$_maxRemarksLength',
            style: TextStyle(
              fontSize: 12.0,
              color: _remarksController.text.length > _maxRemarksLength
                  ? Colors.red
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
