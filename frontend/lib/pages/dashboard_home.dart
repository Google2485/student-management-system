import 'package:flutter/material.dart';

import '../services/dashboard_api_service.dart';
import '../services/enrollment_api_service.dart';
import '../services/activities_api_service.dart';

import 'students_page.dart';
import 'departments_page.dart';
import 'courses_page.dart';
import 'attendance_page.dart';
import 'fees_page.dart';
import 'results_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'help_center_page.dart';

class DashboardHome extends StatefulWidget {
  final String token;
  final String adminName;
  final String adminEmail;
  final VoidCallback onLogout;

  const DashboardHome({
    super.key,
    required this.token,
    required this.adminName,
    required this.adminEmail,
    required this.onLogout,
  });

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  static const Color primary = Color(0xFF6258E8);
  static const Color background = Color(0xFFF7F8FC);

  int selectedIndex = 0;

  Map<String, dynamic> _summary = {};
  bool _isLoadingSummary = true;
  String? _summaryError;

  List<Map<String, dynamic>> _enrollmentData = [];
  bool _isLoadingEnrollment = true;
  String? _enrollmentError;

  List<Map<String, dynamic>> _activitiesData = [];
  bool _isLoadingActivities = true;
  String? _activitiesError;

  final List<String> pageTitles = [
    'Overview',
    'Student Management',
    'Courses',
    'Departments',
    'Attendance',
    'Fees & Payments',
    'Academic Results',
    'Reports',
    'Settings',
    'Help Center',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardSummary();
    _loadEnrollment();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoadingActivities = true;
      _activitiesError = null;
    });

    try {
      final data = await ActivitiesApiService.getActivities(widget.token);

      if (!mounted) return;

      setState(() {
        _activitiesData = data;
        _isLoadingActivities = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _activitiesError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingActivities = false;
      });
    }
  }

  Future<void> _loadDashboardSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final data = await DashboardApiService.getSummary(widget.token);

      if (!mounted) return;

      setState(() {
        _summary = data;
        _isLoadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _summaryError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _loadEnrollment() async {
    setState(() {
      _isLoadingEnrollment = true;
      _enrollmentError = null;
    });

    try {
      final data = await EnrollmentApiService.getEnrollment(widget.token);

      if (!mounted) return;

      setState(() {
        _enrollmentData = data;
        _isLoadingEnrollment = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enrollmentError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingEnrollment = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _loadDashboardSummary(),
      _loadEnrollment(),
      _loadActivities(),
    ]);
  }

  int _number(String key) {
    return int.tryParse(_summary[key]?.toString() ?? '0') ?? 0;
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String _formatMoney(int value) {
    return '৳ ${_formatNumber(value)}';
  }

  void _selectPage(int index) {
    setState(() {
      selectedIndex = index;
    });

    if (MediaQuery.of(context).size.width < 800 && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return Row(
            children: [
              if (!isMobile) SizedBox(width: 250, child: _sidebar(context)),

              Expanded(
                child: Column(
                  children: [
                    _topbar(context, isMobile),

                    Expanded(
                      child: selectedIndex == 1
                          ? const StudentsPage(embedded: true)
                          : selectedIndex == 2
                          ? const CoursesPage(embedded: true)
                          : selectedIndex == 3
                          ? const DepartmentsPage(embedded: true)
                          : selectedIndex == 4
                          ? const AttendancePage(embedded: true)
                          : selectedIndex == 5
                          ? const FeesPage(embedded: true)
                          : selectedIndex == 6
                          ? const ResultsPage(embedded: true)
                          : selectedIndex == 7
                          ? ReportsPage(token: widget.token)
                          : selectedIndex == 8
                          ? SettingsPage(
                              token: widget.token,
                              adminName: widget.adminName,
                              adminEmail: widget.adminEmail,
                            )
                          : selectedIndex == 9
                          ? HelpCenterPage(onNavigate: _selectPage)
                          : selectedIndex == 0
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(25),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _welcomeSection(),
                                  const SizedBox(height: 25),
                                  _statistics(),
                                  const SizedBox(height: 25),
                                  _middleSection(),
                                  const SizedBox(height: 25),
                                  _recentActivities(),
                                ],
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.construction_rounded,
                                    size: 55,
                                    color: primary.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    '${pageTitles[selectedIndex]} Page',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'This module is coming soon.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      drawer: MediaQuery.of(context).size.width < 800
          ? Drawer(child: _sidebar(context))
          : null,
    );
  }

  Widget _sidebar(BuildContext context) {
    return Container(
      color: const Color(0xFF211D45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(25),
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: Colors.white, size: 35),
                SizedBox(width: 12),
                Text(
                  'EduManage',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 15),

                  _menuItem(Icons.dashboard_rounded, 'Dashboard', 0),
                  _menuItem(Icons.people_alt_rounded, 'Students', 1),
                  _menuItem(Icons.menu_book_rounded, 'Courses', 2),
                  _menuItem(Icons.apartment_rounded, 'Departments', 3),
                  _menuItem(Icons.fact_check_rounded, 'Attendance', 4),
                  _menuItem(Icons.payments_rounded, 'Fees & Payments', 5),
                  _menuItem(Icons.assessment_rounded, 'Results', 6),
                  _menuItem(Icons.bar_chart_rounded, 'Reports', 7),

                  const SizedBox(height: 15),

                  _menuItem(Icons.settings_rounded, 'Settings', 8),
                  _menuItem(Icons.help_outline_rounded, 'Help Center', 9),

                  const Divider(color: Colors.white12),

                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: widget.onLogout,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, int index) {
    final selected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: Colors.white, size: 21),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          onTap: () => _selectPage(index),
        ),
      ),
    );
  }

  Widget _topbar(BuildContext context, bool isMobile) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEF3))),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),

          Expanded(
            child: Text(
              pageTitles[selectedIndex],
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ),

          IconButton(
            tooltip: 'Refresh Dashboard',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),

          const SizedBox(width: 10),

          CircleAvatar(
            backgroundColor: primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person, color: primary),
          ),

          const SizedBox(width: 10),

          if (!isMobile)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.adminName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  widget.adminEmail,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _welcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 7),
        Text(
          'Welcome back, ${widget.adminName}! Here is what is happening today.',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _statistics() {
    if (_isLoadingSummary) {
      return const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_summaryError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 35),
            const SizedBox(height: 10),
            Text(
              _summaryError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loadDashboardSummary,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 600
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: columns == 1 ? 3.2 : 1.8,
          children: [
            _statCard(
              'Total Students',
              _formatNumber(_number('total_students')),
              '',
              Icons.people_alt_rounded,
              const Color(0xFF6258E8),
            ),
            _statCard(
              'Total Courses',
              _formatNumber(_number('total_courses')),
              '',
              Icons.menu_book_rounded,
              const Color(0xFF16A6A1),
            ),
            _statCard(
              'Departments',
              _formatNumber(_number('total_departments')),
              '',
              Icons.apartment_rounded,
              const Color(0xFFFF9F43),
            ),
            _statCard(
              'Total Revenue',
              _formatMoney(_number('total_revenue')),
              '',
              Icons.account_balance_wallet_rounded,
              const Color(0xFFEB5E8C),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    String growth,
    IconData icon,
    Color color,
  ) {
    final darkColor = Color.lerp(color, Colors.black, 0.18)!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ],
          ),

          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (growth.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    growth,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _middleSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              _enrollmentCard(),
              const SizedBox(height: 18),
              _attendanceCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _enrollmentCard()),
            const SizedBox(width: 18),
            Expanded(child: _attendanceCard()),
          ],
        );
      },
    );
  }

  Widget _enrollmentCard() {
    final maxTotal = _enrollmentData.isEmpty
        ? 1
        : _enrollmentData
              .map((e) => int.tryParse(e['total'].toString()) ?? 0)
              .reduce((a, b) => a > b ? a : b);

    return _panel(
      'Student Enrollment',
      'Monthly student overview',
      SizedBox(
        height: 190,
        child: _isLoadingEnrollment
            ? const Center(child: CircularProgressIndicator())
            : _enrollmentError != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _enrollmentError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: _loadEnrollment,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _enrollmentData.isEmpty
            ? const Center(child: Text('No enrollment data available'))
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _enrollmentData.map((item) {
                  final total = int.tryParse(item['total'].toString()) ?? 0;

                  final height = maxTotal == 0 ? 0.0 : (total / maxTotal) * 145;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        total.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 25,
                        height: height < 8 ? 8 : height,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['month'].toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _attendanceCard() {
    final attendance = _summary['attendance'] is Map
        ? Map<String, dynamic>.from(_summary['attendance'])
        : <String, dynamic>{};

    final present = int.tryParse(attendance['present']?.toString() ?? '0') ?? 0;
    final absent = int.tryParse(attendance['absent']?.toString() ?? '0') ?? 0;
    final leave = int.tryParse(attendance['leave']?.toString() ?? '0') ?? 0;

    final total = present + absent + leave;

    final presentRatio = total == 0 ? 0.0 : present / total;
    final absentRatio = total == 0 ? 0.0 : absent / total;
    final leaveRatio = total == 0 ? 0.0 : leave / total;

    return _panel(
      'Attendance Summary',
      'Today\'s attendance overview',
      SizedBox(
        height: 190,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _progressItem(
              'Present',
              '${(presentRatio * 100).round()}% ($present)',
              presentRatio,
              Colors.green,
            ),
            const SizedBox(height: 22),
            _progressItem(
              'Absent',
              '${(absentRatio * 100).round()}% ($absent)',
              absentRatio,
              Colors.red,
            ),
            const SizedBox(height: 22),
            _progressItem(
              'Leave',
              '${(leaveRatio * 100).round()}% ($leave)',
              leaveRatio,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressItem(
    String title,
    String value,
    double progress,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(title, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 9,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _panel(String title, String subtitle, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEEEEF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  String _formatActivityTime(String? value) {
    if (value == null || value.isEmpty) return '';

    final date = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (date == null) return value;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(activityDay).inDays;

    final time =
        '${date.hour % 12 == 0 ? 12 : date.hour % 12}:'
        '${date.minute.toString().padLeft(2, '0')} '
        '${date.hour >= 12 ? 'PM' : 'AM'}';

    if (difference == 0) return 'Today, $time';
    if (difference == 1) return 'Yesterday, $time';

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _recentActivities() {
    return _panel(
      'Recent Activities',
      'Latest student management activities',
      _isLoadingActivities
          ? const Padding(
              padding: EdgeInsets.all(25),
              child: Center(child: CircularProgressIndicator()),
            )
          : _activitiesError != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    _activitiesError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: _loadActivities,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : _activitiesData.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(25),
              child: Center(
                child: Text(
                  'No recent activities found.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : Column(
              children: List.generate(_activitiesData.length, (index) {
                final activity = _activitiesData[index];

                final type = activity['type']?.toString().toLowerCase() ?? '';

                IconData icon;
                Color color;

                if (type == 'payment') {
                  icon = Icons.payments_outlined;
                  color = Colors.green;
                } else if (type == 'attendance') {
                  icon = Icons.fact_check_outlined;
                  color = Colors.orange;
                } else {
                  icon = Icons.person_add_alt_1;
                  color = Colors.blue;
                }

                return Column(
                  children: [
                    _activity(
                      icon,
                      activity['title']?.toString() ?? 'Activity',
                      activity['description']?.toString() ?? '',
                      _formatActivityTime(
                        activity['activity_date']?.toString(),
                      ),
                      color,
                    ),
                    if (index != _activitiesData.length - 1)
                      const Divider(height: 25),
                  ],
                );
              }),
            ),
    );
  }

  Widget _activity(
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
