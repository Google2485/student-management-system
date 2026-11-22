import 'package:flutter/material.dart';

import '../main.dart';
import '../services/course_api_service.dart';

class CoursesPage extends StatefulWidget {
  final bool embedded;

  const CoursesPage({super.key, this.embedded = false});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  static const Color primary = Color(0xFF6258E8);

  String? token;
  bool isLoading = true;
  String? error;

  List<dynamic> courses = [];
  List<dynamic> departments = [];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> initializePage() async {
    try {
      token = await ApiService.getToken();

      if (token == null || token!.isEmpty) {
        throw Exception('Login token not found. Please login again.');
      }

      await Future.wait([loadCourses(), loadDepartments()]);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> loadCourses() async {
    try {
      final result = await CourseApiService.getCourses(token!);

      if (!mounted) return;

      setState(() {
        courses = result;
        error = null;
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

  Future<void> loadDepartments() async {
    final result = await CourseApiService.getDepartments(token!);

    if (!mounted) return;

    setState(() {
      departments = result;
    });
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      await Future.wait([loadCourses(), loadDepartments()]);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  List<dynamic> get filteredCourses {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) return courses;

    return courses.where((course) {
      final name = course['name']?.toString().toLowerCase() ?? '';
      final code = course['course_code']?.toString().toLowerCase() ?? '';
      final department =
          course['department_name']?.toString().toLowerCase() ?? '';

      return name.contains(query) ||
          code.contains(query) ||
          department.contains(query);
    }).toList();
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Add Course
  Future<void> showAddCourseDialog() async {
    if (departments.isEmpty) {
      showMessage('Please create a department first.', isError: true);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    int? selectedDepartmentId = int.tryParse(
      departments.first['id'].toString(),
    );

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add New Course',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Course Name',
                          hintText: 'Enter course name',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Course name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Course Code',
                          hintText: 'Example: DCE-101',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Course code is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: departments.map((department) {
                          final id = int.tryParse(department['id'].toString());

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(department['name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDepartmentId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a department';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => isSaving = true);

                          try {
                            await CourseApiService.createCourse(token!, {
                              'name': nameController.text.trim(),
                              'course_code': codeController.text.trim(),
                              'department_id': selectedDepartmentId,
                            });

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            await loadCourses();

                            if (!mounted) return;

                            showMessage('Course created successfully!');
                          } catch (e) {
                            setDialogState(() => isSaving = false);

                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Course'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
  }

  // Edit Course
  Future<void> showEditCourseDialog(Map<String, dynamic> course) async {
    if (departments.isEmpty) {
      showMessage('No departments available.', isError: true);
      return;
    }

    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: course['name']?.toString() ?? '',
    );

    final codeController = TextEditingController(
      text: course['course_code']?.toString() ?? '',
    );

    int? selectedDepartmentId = int.tryParse(
      course['department_id'].toString(),
    );

    if (!departments.any(
      (department) =>
          int.tryParse(department['id'].toString()) == selectedDepartmentId,
    )) {
      selectedDepartmentId = int.tryParse(departments.first['id'].toString());
    }

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Course',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Course Name',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Course name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Course Code',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Course code is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: departments.map((department) {
                          final id = int.tryParse(department['id'].toString());

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(department['name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDepartmentId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a department';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => isSaving = true);

                          try {
                            await CourseApiService.updateCourse(token!, {
                              'id': int.parse(course['id'].toString()),
                              'name': nameController.text.trim(),
                              'course_code': codeController.text.trim(),
                              'department_id': selectedDepartmentId,
                            });

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            await loadCourses();

                            if (!mounted) return;

                            showMessage('Course updated successfully!');
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() => isSaving = false);

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Update Course'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
  }

  // Delete Course
  Future<void> deleteCourse(Map<String, dynamic> course) async {
    final id = int.tryParse(course['id'].toString());

    if (id == null) {
      showMessage('Invalid course ID.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Course?'),
          content: Text('Are you sure you want to delete "${course['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await CourseApiService.deleteCourse(token!, id);

      if (!mounted) return;

      await loadCourses();

      if (!mounted) return;

      showMessage('Course deleted successfully!');
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Widget pageContent() {
    final displayedCourses = filteredCourses;

    return Padding(
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
                      'Course Management',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF20213A),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage courses and departments',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: refreshData,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: showAddCourseDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Courses',
                  courses.length.toString(),
                  Icons.menu_book_rounded,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _statCard(
                  'Departments',
                  departments.length.toString(),
                  Icons.business_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search course, code or department...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 10),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: refreshData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : courses.isEmpty
                ? _emptyState(
                    'No courses found',
                    'Add your first course to get started.',
                  )
                : displayedCourses.isEmpty
                ? _emptyState(
                    'No matching courses',
                    'Try searching with another keyword.',
                  )
                : _courseTable(displayedCourses),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseTable(List<dynamic> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F0FC)),
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Course Name')),
              DataColumn(label: Text('Course Code')),
              DataColumn(label: Text('Department')),
              DataColumn(label: Text('Actions')),
            ],
            rows: data.map((item) {
              final course = Map<String, dynamic>.from(item);

              return DataRow(
                cells: [
                  DataCell(Text(course['id']?.toString() ?? '-')),
                  DataCell(Text(course['name']?.toString() ?? '-')),
                  DataCell(Text(course['course_code']?.toString() ?? '-')),
                  DataCell(Text(course['department_name']?.toString() ?? '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit Course',
                          onPressed: () => showEditCourseDialog(course),
                          icon: const Icon(Icons.edit_outlined, color: primary),
                        ),
                        IconButton(
                          tooltip: 'Delete Course',
                          onPressed: () => deleteCourse(course),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
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
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 55,
            color: primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFF7F8FC), child: pageContent());
  }
}
