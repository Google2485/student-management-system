import 'package:flutter/material.dart';

import '../main.dart';
import '../services/course_api_service.dart';

class DepartmentsPage extends StatefulWidget {
  final bool embedded;

  const DepartmentsPage({super.key, this.embedded = false});

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  static const Color primary = Color(0xFF6258E8);

  String? token;
  bool isLoading = true;
  String? error;

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

      await loadDepartments();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> loadDepartments() async {
    try {
      final result = await CourseApiService.getDepartments(token!);

      if (!mounted) return;

      setState(() {
        departments = result;
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

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    await loadDepartments();
  }

  List<dynamic> get filteredDepartments {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) return departments;

    return departments.where((department) {
      final name = department['name']?.toString().toLowerCase() ?? '';
      final id = department['id']?.toString().toLowerCase() ?? '';

      return name.contains(query) || id.contains(query);
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

  // Add Department
  Future<void> showAddDepartmentDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add New Department',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Department Name',
                      hintText: 'Enter department name',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Department name is required';
                      }
                      return null;
                    },
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
                            await CourseApiService.createDepartment(
                              token!,
                              nameController.text.trim(),
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            await loadDepartments();

                            if (!mounted) return;

                            showMessage('Department created successfully!');
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
                      : const Text('Save Department'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  // Edit Department
  Future<void> showEditDepartmentDialog(Map<String, dynamic> department) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: department['name']?.toString() ?? '',
    );

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Department',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Department Name',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Department name is required';
                      }
                      return null;
                    },
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
                            await CourseApiService.updateDepartment(
                              token!,
                              int.parse(department['id'].toString()),
                              nameController.text.trim(),
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            await loadDepartments();

                            if (!mounted) return;

                            showMessage('Department updated successfully!');
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
                      : const Text('Update Department'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  // Delete Department
  Future<void> deleteDepartment(Map<String, dynamic> department) async {
    final id = int.tryParse(department['id'].toString());

    if (id == null) {
      showMessage('Invalid department ID.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Department?'),
          content: Text(
            'Are you sure you want to delete "${department['name']}"?',
          ),
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
      await CourseApiService.deleteDepartment(token!, id);

      if (!mounted) return;

      await loadDepartments();

      if (!mounted) return;

      showMessage('Department deleted successfully!');
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Widget pageContent() {
    final displayedDepartments = filteredDepartments;

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
                      'Department Management',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF20213A),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage your academic departments',
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
                onPressed: showAddDepartmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
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
          _statCard(
            'Total Departments',
            departments.length.toString(),
            Icons.business_rounded,
          ),
          const SizedBox(height: 22),
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search department...',
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
                : departments.isEmpty
                ? _emptyState(
                    'No departments found',
                    'Add your first department to get started.',
                  )
                : displayedDepartments.isEmpty
                ? _emptyState(
                    'No matching departments',
                    'Try another search keyword.',
                  )
                : _departmentTable(displayedDepartments),
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
          Column(
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
        ],
      ),
    );
  }

  Widget _departmentTable(List<dynamic> data) {
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
              DataColumn(label: Text('Department Name')),
              DataColumn(label: Text('Created At')),
              DataColumn(label: Text('Actions')),
            ],
            rows: data.map((item) {
              final department = Map<String, dynamic>.from(item);

              return DataRow(
                cells: [
                  DataCell(Text(department['id']?.toString() ?? '-')),
                  DataCell(Text(department['name']?.toString() ?? '-')),
                  DataCell(Text(department['created_at']?.toString() ?? '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit Department',
                          onPressed: () => showEditDepartmentDialog(department),
                          icon: const Icon(Icons.edit_outlined, color: primary),
                        ),
                        IconButton(
                          tooltip: 'Delete Department',
                          onPressed: () => deleteDepartment(department),
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
            Icons.business_outlined,
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
