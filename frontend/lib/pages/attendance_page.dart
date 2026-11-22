import 'package:flutter/material.dart';

import '../main.dart';
import '../services/attendance_api_service.dart';

class AttendancePage extends StatefulWidget {
  final bool embedded;

  const AttendancePage({super.key, this.embedded = false});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const Color primaryColor = Color(0xFF6258E8);
  static const Color backgroundColor = Color(0xFFF7F8FC);

  DateTime selectedDate = DateTime.now();

  List<dynamic> students = [];

  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;
  String? token;

  String get formattedDate {
    return '${selectedDate.year}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      token ??= await ApiService.getToken();

      if (token == null || token!.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final result = await AttendanceApiService.getAttendance(
        token!,
        formattedDate,
      );

      if (!mounted) return;

      setState(() {
        students = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  int get presentCount {
    return students.where((s) => s['status'] == 'Present').length;
  }

  int get absentCount {
    return students.where((s) => s['status'] == 'Absent').length;
  }

  int get leaveCount {
    return students.where((s) => s['status'] == 'Leave').length;
  }

  int get unmarkedCount {
    return students.where((s) => s['status'] == null).length;
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedDate = picked;
    });

    await loadAttendance();
  }

  Future<void> changeStatus(Map<String, dynamic> student, String status) async {
    if (token == null) return;

    final attendanceId = student['attendance_id'];

    try {
      setState(() {
        isSaving = true;
      });

      if (attendanceId == null) {
        await AttendanceApiService.markAttendance(
          token: token!,
          studentId: int.parse(student['student_id'].toString()),
          date: formattedDate,
          status: status,
        );
      } else {
        await AttendanceApiService.updateAttendance(
          token: token!,
          attendanceId: int.parse(attendanceId.toString()),
          status: status,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student['name']} marked $status'),
          backgroundColor: Colors.green,
        ),
      );

      await loadAttendance();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Leave':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget summaryCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Color(0xFF77788A), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusButton(Map<String, dynamic> student, String status) {
    final selected = student['status'] == status;
    final color = statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: InkWell(
        onTap: isSaving ? null : () => changeStatus(student, status),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.embedded ? Colors.transparent : backgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Management',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25253A),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage daily student attendance',
                      style: TextStyle(color: Color(0xFF858599), fontSize: 13),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: selectDate,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(formattedDate),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: loadAttendance,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              summaryCard(
                'Present',
                presentCount,
                Colors.green,
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              summaryCard(
                'Absent',
                absentCount,
                Colors.red,
                Icons.cancel_outlined,
              ),
              const SizedBox(width: 12),
              summaryCard(
                'Leave',
                leaveCount,
                Colors.orange,
                Icons.event_busy_outlined,
              ),
              const SizedBox(width: 12),
              summaryCard(
                'Not Marked',
                unmarkedCount,
                Colors.grey,
                Icons.pending_actions,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEEF4)),
              ),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(errorMessage!),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: loadAttendance,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : students.isEmpty
                  ? const Center(child: Text('No students found'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Student Attendance',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF8F8FC),
                                ),
                                columns: const [
                                  DataColumn(label: Text('Student ID')),
                                  DataColumn(label: Text('Student Name')),
                                  DataColumn(label: Text('Course')),
                                  DataColumn(label: Text('Attendance Status')),
                                ],
                                rows: students.map((item) {
                                  final student = Map<String, dynamic>.from(
                                    item,
                                  );

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          student['student_code']?.toString() ??
                                              '-',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          student['name']?.toString() ?? '-',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          student['course_name']?.toString() ??
                                              '-',
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            statusButton(student, 'Present'),
                                            statusButton(student, 'Absent'),
                                            statusButton(student, 'Leave'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
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
}
