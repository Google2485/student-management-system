import 'package:flutter/material.dart';

import '../main.dart';
import '../services/results_api_service.dart';

class ResultsPage extends StatefulWidget {
  final bool embedded;

  const ResultsPage({super.key, this.embedded = false});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  static const Color primaryColor = Color(0xFF6258E8);
  static const Color backgroundColor = Color(0xFFF7F8FC);

  String? token;

  List<dynamic> results = [];
  List<dynamic> students = [];

  bool isLoading = true;
  bool isSaving = false;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      token ??= await ApiService.getToken();

      if (token == null || token!.isEmpty) {
        throw Exception('Login token not found');
      }

      final data = await Future.wait([
        ResultsApiService.getResults(token!),
        ApiService.getStudents(token!),
      ]);

      if (!mounted) return;

      setState(() {
        results = data[0];
        students = data[1];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  String calculateGrade(double marks) {
    if (marks >= 80) return 'A+';
    if (marks >= 70) return 'A';
    if (marks >= 60) return 'A-';
    if (marks >= 50) return 'B';
    if (marks >= 40) return 'C';
    if (marks >= 33) return 'D';
    return 'F';
  }

  Color gradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'A-':
      case 'B':
        return Colors.blue;
      case 'C':
      case 'D':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  List<dynamic> get filteredResults {
    if (searchQuery.isEmpty) return results;

    final query = searchQuery.toLowerCase();

    return results.where((item) {
      final studentName =
          item['student_name']?.toString().toLowerCase() ?? '';
      final studentCode =
          item['student_code']?.toString().toLowerCase() ?? '';
      final examName = item['exam_name']?.toString().toLowerCase() ?? '';
      final subject = item['subject']?.toString().toLowerCase() ?? '';

      return studentName.contains(query) ||
          studentCode.contains(query) ||
          examName.contains(query) ||
          subject.contains(query);
    }).toList();
  }

  double get averageMarks {
    if (results.isEmpty) return 0;

    double total = 0;

    for (final item in results) {
      total += double.tryParse(item['marks'].toString()) ?? 0;
    }

    return total / results.length;
  }

  int get passedStudents {
    return results.where((item) {
      final marks = double.tryParse(item['marks'].toString()) ?? 0;
      return marks >= 33;
    }).length;
  }

  int get failedStudents => results.length - passedStudents;

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> showResultDialog({Map<String, dynamic>? result}) async {
    final isEditing = result != null;

    dynamic selectedStudent;

    if (!isEditing && students.isEmpty) {
      showMessage('Please add students first', error: true);
      return;
    }

    final examController = TextEditingController(
      text: result?['exam_name']?.toString() ?? '',
    );

    final subjectController = TextEditingController(
      text: result?['subject']?.toString() ?? '',
    );

    final marksController = TextEditingController(
      text: result?['marks']?.toString() ?? '',
    );

    if (!isEditing) {
      selectedStudent = null;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final marks = double.tryParse(marksController.text.trim());
            final grade = marks != null && marks >= 0 && marks <= 100
                ? calculateGrade(marks)
                : '--';

            return AlertDialog(
              title: Text(isEditing ? 'Edit Result' : 'Add Result'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEditing)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F4FF),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Student',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                result['student_name']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                result['student_code']?.toString() ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<dynamic>(
                          initialValue: selectedStudent,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Student',
                          ),
                          items: students.map((student) {
                            return DropdownMenuItem<dynamic>(
                              value: student,
                              child: Text(
                                '${student['name']} (${student['student_id'] ?? student['id']})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            dialogSetState(() {
                              selectedStudent = value;
                            });
                          },
                        ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: examController,
                        decoration: const InputDecoration(
                          labelText: 'Exam Name',
                          hintText: 'e.g. Midterm Examination',
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'e.g. Computer Programming',
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: marksController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Marks',
                          hintText: 'Enter marks (0-100)',
                          suffixText: '/ 100',
                        ),
                        onChanged: (_) {
                          dialogSetState(() {});
                        },
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Automatically Calculated Grade',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              grade,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: grade == '--'
                                    ? Colors.grey
                                    : gradeColor(grade),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final examName = examController.text.trim();
                          final subject = subjectController.text.trim();
                          final marks = double.tryParse(
                            marksController.text.trim(),
                          );

                          if (examName.isEmpty ||
                              subject.isEmpty ||
                              marks == null ||
                              marks < 0 ||
                              marks > 100) {
                            showMessage(
                              'Enter valid exam, subject and marks (0-100)',
                              error: true,
                            );
                            return;
                          }

                          int? studentId;

                          if (!isEditing) {
                            if (selectedStudent == null) {
                              showMessage(
                                'Please select a student',
                                error: true,
                              );
                              return;
                            }

                            studentId = int.tryParse(
                              (selectedStudent['id'] ??
                                      selectedStudent['student_id'])
                                  .toString(),
                            );

                            if (studentId == null) {
                              showMessage(
                                'Invalid student selected',
                                error: true,
                              );
                              return;
                            }
                          }

                          Navigator.pop(dialogContext);

                          await saveResult(
                            isEditing: isEditing,
                            id: isEditing
                                ? int.tryParse(result['id'].toString())
                                : null,
                            studentId: studentId,
                            examName: examName,
                            subject: subject,
                            marks: marks,
                          );
                        },
                  child: Text(isEditing ? 'Update Result' : 'Save Result'),
                ),
              ],
            );
          },
        );
      },
    );

    examController.dispose();
    subjectController.dispose();
    marksController.dispose();
  }

  Future<void> saveResult({
    required bool isEditing,
    int? id,
    int? studentId,
    required String examName,
    required String subject,
    required double marks,
  }) async {
    try {
      setState(() => isSaving = true);

      final grade = calculateGrade(marks);

      if (isEditing) {
        if (id == null) throw Exception('Invalid result ID');

        await ResultsApiService.updateResult(token!, {
          'id': id,
          'exam_name': examName,
          'subject': subject,
          'marks': marks,
          'grade': grade,
        });
      } else {
        await ResultsApiService.createResult(token!, {
          'student_id': studentId,
          'exam_name': examName,
          'subject': subject,
          'marks': marks,
          'grade': grade,
        });
      }

      showMessage(
        isEditing
            ? 'Result updated successfully'
            : 'Result added successfully',
      );

      await loadData();
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> deleteResult(Map<String, dynamic> result) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Result'),
          content: const Text(
            'Are you sure you want to delete this result?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      setState(() => isSaving = true);

      final id = int.tryParse(result['id'].toString());

      if (id == null) throw Exception('Invalid result ID');

      await ResultsApiService.deleteResult(token!, id);

      showMessage('Result deleted successfully');
      await loadData();
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25253A),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF858599),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget resultsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Academic Results',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: TextField(
                    onChanged: (value) {
                      setState(() => searchQuery = value.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search results...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filteredResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(35),
              child: Center(child: Text('No results found')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8F8FC),
                ),
                columns: const [
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Exam')),
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('Marks')),
                  DataColumn(label: Text('Grade')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: filteredResults.map((item) {
                  final result = Map<String, dynamic>.from(item);
                  final marks =
                      double.tryParse(result['marks'].toString()) ?? 0;
                  final grade = calculateGrade(marks);

                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result['student_name']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              result['student_code']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(result['exam_name']?.toString() ?? '-'),
                      ),
                      DataCell(
                        Text(result['subject']?.toString() ?? '-'),
                      ),
                      DataCell(
                        Text(
                          marks.toStringAsFixed(2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: gradeColor(grade).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            grade,
                            style: TextStyle(
                              color: gradeColor(grade),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: isSaving
                                  ? null
                                  : () => showResultDialog(result: result),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: isSaving
                                  ? null
                                  : () => deleteResult(result),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.embedded ? Colors.transparent : backgroundColor,
      padding: const EdgeInsets.all(24),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : SingleChildScrollView(
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
                              'Academic Results',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF25253A),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Manage student exam results and grades',
                              style: TextStyle(
                                color: Color(0xFF858599),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () => showResultDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Result'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      summaryCard(
                        'Total Results',
                        results.length.toString(),
                        Icons.assessment_outlined,
                        primaryColor,
                      ),
                      const SizedBox(width: 12),
                      summaryCard(
                        'Average Marks',
                        '${averageMarks.toStringAsFixed(1)}%',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      summaryCard(
                        'Passed',
                        passedStudents.toString(),
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      summaryCard(
                        'Failed',
                        failedStudents.toString(),
                        Icons.cancel_outlined,
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  resultsTable(),
                ],
              ),
            ),
    );
  }
}
