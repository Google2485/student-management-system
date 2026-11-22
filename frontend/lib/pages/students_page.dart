import 'package:flutter/material.dart';

import '../main.dart';

class StudentsPage extends StatefulWidget {
  final String? token;
  final bool embedded;

  const StudentsPage({super.key, this.token, this.embedded = false});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];

  bool isLoading = true;
  String? error;
  String searchQuery = '';
  String? authToken;

  static const Color primary = Color(0xFF6258E8);

  @override
  void initState() {
    super.initState();
    _initializeStudents();
  }

  Future<void> _initializeStudents() async {
    authToken = widget.token ?? await ApiService.getToken();

    if (authToken == null || authToken!.isEmpty) {
      if (!mounted) return;

      setState(() {
        error = 'Login token not found. Please login again.';
        isLoading = false;
      });
      return;
    }

    await loadStudents();
  }

  Future<void> loadStudents() async {
    if (authToken == null || authToken!.isEmpty) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await ApiService.getStudents(authToken!);

      if (!mounted) return;

      setState(() {
        students = result;
        _applySearch();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void searchStudents(String value) {
    setState(() {
      searchQuery = value.toLowerCase().trim();
      _applySearch();
    });
  }

  void _applySearch() {
    filteredStudents = students.where((student) {
      final name = (student['name'] ?? '').toString().toLowerCase();
      final id = (student['student_id'] ?? '').toString().toLowerCase();
      final email = (student['email'] ?? '').toString().toLowerCase();

      return name.contains(searchQuery) ||
          id.contains(searchQuery) ||
          email.contains(searchQuery);
    }).toList();
  }

  Future<void> showStudentForm({Map<String, dynamic>? student}) async {
    if (authToken == null) return;

    final isEdit = student != null;
    final formKey = GlobalKey<FormState>();

    final studentIdController = TextEditingController(
      text: student?['student_id']?.toString() ?? '',
    );

    final nameController = TextEditingController(
      text: student?['name']?.toString() ?? '',
    );

    final emailController = TextEditingController(
      text: student?['email']?.toString() ?? '',
    );

    final phoneController = TextEditingController(
      text: student?['phone']?.toString() ?? '',
    );

    final addressController = TextEditingController(
      text: student?['address']?.toString() ?? '',
    );

    final courseController = TextEditingController(
      text: student?['course_id']?.toString() ?? '',
    );

    final admissionController = TextEditingController(
      text:
          student?['admission_date']?.toString() ??
          DateTime.now().toIso8601String().substring(0, 10),
    );

    String gender = student?['gender']?.toString() ?? 'Male';
    String status = student?['status']?.toString() ?? 'Active';

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(isEdit ? 'Edit Student' : 'Add New Student'),
                content: SizedBox(
                  width: 450,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _formField(
                            studentIdController,
                            'Student ID',
                            required: true,
                          ),
                          _formField(
                            nameController,
                            'Full Name',
                            required: true,
                          ),
                          _formField(emailController, 'Email'),
                          _formField(phoneController, 'Phone'),
                          _formField(addressController, 'Address'),
                          _formField(
                            courseController,
                            'Course ID',
                            keyboardType: TextInputType.number,
                          ),
                          _formField(
                            admissionController,
                            'Admission Date (YYYY-MM-DD)',
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            initialValue: gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  gender = value;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Active', 'Inactive']
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  status = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final data = <String, dynamic>{
                        'student_id': studentIdController.text.trim(),
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'address': addressController.text.trim(),
                        'course_id': int.tryParse(courseController.text.trim()),
                        'admission_date': admissionController.text.trim(),
                        'gender': gender,
                        'status': status,
                      };

                      try {
                        if (isEdit) {
                          data['id'] = int.parse(student['id'].toString());

                          await ApiService.updateStudent(authToken!, data);
                        } else {
                          await ApiService.createStudent(authToken!, data);
                        }

                        if (!dialogContext.mounted) return;

                        Navigator.pop(dialogContext);

                        await loadStudents();

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Student updated successfully'
                                  : 'Student added successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(isEdit ? 'Update Student' : 'Save Student'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      studentIdController.dispose();
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      addressController.dispose();
      courseController.dispose();
      admissionController.dispose();
    }
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> deleteStudent(Map<String, dynamic> student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Student?'),
          content: Text('Are you sure you want to delete ${student['name']}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true || authToken == null) return;

    try {
      await ApiService.deleteStudent(
        authToken!,
        int.parse(student['id'].toString()),
      );

      await loadStudents();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _studentTable() {
    if (filteredStudents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(35),
        child: Center(child: Text('No students found')),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F0FC)),
        columns: const [
          DataColumn(label: Text('Student ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Course')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: filteredStudents.map((student) {
          final status = student['status']?.toString() ?? 'Active';

          return DataRow(
            cells: [
              DataCell(Text(student['student_id']?.toString() ?? '-')),
              DataCell(Text(student['name']?.toString() ?? '-')),
              DataCell(Text(student['email']?.toString() ?? '-')),
              DataCell(Text(student['phone']?.toString() ?? '-')),
              DataCell(
                Text(
                  student['course_name']?.toString() ??
                      student['course']?.toString() ??
                      '-',
                ),
              ),
              DataCell(
                Chip(
                  label: Text(status),
                  backgroundColor: status == 'Active'
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined, color: primary),
                      onPressed: () {
                        showStudentForm(
                          student: Map<String, dynamic>.from(student),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        deleteStudent(Map<String, dynamic>.from(student));
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _pageContent() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: searchStudents,
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID or email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => showStudentForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'Total Students: ${students.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFEEEEF3)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _initializeStudents,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _studentTable(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(color: const Color(0xFFF7F8FC), child: _pageContent());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Student Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadStudents,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _pageContent(),
    );
  }
}
