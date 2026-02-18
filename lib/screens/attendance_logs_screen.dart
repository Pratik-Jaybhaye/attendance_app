import 'package:flutter/material.dart';

class AttendanceLogsScreen extends StatefulWidget {
  final String email;

  const AttendanceLogsScreen({super.key, required this.email});

  @override
  State<AttendanceLogsScreen> createState() => _AttendanceLogsScreenState();
}

class _AttendanceLogsScreenState extends State<AttendanceLogsScreen> {
  bool _isLoading = true;
  List<dynamic> _attendanceLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceLogs();
  }

  /// TODO: Connect to Backend API
  /// Endpoint: GET /api/attendance/logs
  /// This should fetch the user's attendance history
  Future<void> _fetchAttendanceLogs() async {
    try {
      // TODO: Replace with actual API call
      // Example:
      // final response = await http.get(
      //   Uri.parse('$API_BASE_URL/api/attendance/logs'),
      //   headers: {'Authorization': 'Bearer $authToken'},
      // );
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   setState(() {
      //     _attendanceLogs = data['logs'];
      //     _isLoading = false;
      //   });
      // }

      // Mock delay to simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching attendance logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Call logout API endpoint here
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3F8),
        elevation: 0,
        title: const Text(
          'Attendance Logs',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1A1A2E)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B5B95)),
            )
          : _attendanceLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE0E0E0),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 40,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No attendance records yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your submitted attendance will appear\nhere',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF5A5C6E)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _attendanceLogs.length,
              itemBuilder: (context, index) {
                final log = _attendanceLogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(log['className'] ?? 'Unknown Class'),
                    subtitle: Text(log['date'] ?? 'No date'),
                    trailing: Text(
                      log['status'] ?? 'Pending',
                      style: TextStyle(
                        color: log['status'] == 'Present'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
