import 'package:flutter/material.dart';

import '../services/reports_api_service.dart';

class ReportsPage extends StatefulWidget {
  final String token;

  const ReportsPage({super.key, required this.token});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const Color primary = Color(0xFF6258E8);

  Map<String, dynamic> _data = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ReportsApiService.getSummary(widget.token);

      if (!mounted) return;

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int _number(Map<String, dynamic> data, String key) {
    return num.tryParse(data[key]?.toString() ?? '0')?.toInt() ?? 0;
  }

  double _decimal(Map<String, dynamic> data, String key) {
    return double.tryParse(data[key]?.toString() ?? '0') ?? 0;
  }

  String _formatNumber(num value) {
    return value
        .toStringAsFixed(value is double ? 2 : 0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 21),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF25243A),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _reportGrid(List<Widget> cards, double width) {
    final columns = width >= 1100
        ? 4
        : width >= 650
        ? 2
        : 1;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: columns == 1 ? 2.3 : 1.65,
      children: cards,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 55,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 15),
              const Text(
                'Unable to Load Reports',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadReports,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final students = Map<String, dynamic>.from(_data['students'] ?? {});
    final courses = Map<String, dynamic>.from(_data['courses'] ?? {});
    final departments = Map<String, dynamic>.from(_data['departments'] ?? {});
    final fees = Map<String, dynamic>.from(_data['fees'] ?? {});
    final attendance = Map<String, dynamic>.from(_data['attendance'] ?? {});
    final results = Map<String, dynamic>.from(_data['results'] ?? {});

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
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
                          'Reports Overview',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'View your institution statistics and reports.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadReports,
                    tooltip: 'Refresh Reports',
                    icon: const Icon(Icons.refresh_rounded),
                    color: primary,
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _sectionTitle('Student Statistics', Icons.people_alt_rounded),

              _reportGrid([
                _statCard(
                  title: 'Total Students',
                  value: _formatNumber(_number(students, 'total')),
                  icon: Icons.groups_rounded,
                  color: Colors.blue,
                  subtitle: 'All registered students',
                ),
                _statCard(
                  title: 'Active Students',
                  value: _formatNumber(_number(students, 'active')),
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                  subtitle: 'Currently active students',
                ),
                _statCard(
                  title: 'Inactive Students',
                  value: _formatNumber(_number(students, 'inactive')),
                  icon: Icons.person_off_rounded,
                  color: Colors.orange,
                  subtitle: 'Inactive students',
                ),
                _statCard(
                  title: 'Total Courses',
                  value: _formatNumber(_number(courses, 'total')),
                  icon: Icons.menu_book_rounded,
                  color: Colors.purple,
                  subtitle: 'Available courses',
                ),
                _statCard(
                  title: 'Total Departments',
                  value: _formatNumber(_number(departments, 'total')),
                  icon: Icons.apartment_rounded,
                  color: Colors.teal,
                  subtitle: 'Academic departments',
                ),
              ], constraints.maxWidth),

              const SizedBox(height: 30),

              _sectionTitle(
                'Fees & Payments',
                Icons.account_balance_wallet_rounded,
              ),

              _reportGrid([
                _statCard(
                  title: 'Total Collection',
                  value:
                      '৳ ${_formatNumber(_decimal(fees, 'total_collection'))}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.green,
                  subtitle: 'Total amount collected',
                ),
                _statCard(
                  title: 'Total Payments',
                  value: _formatNumber(_number(fees, 'total_payments')),
                  icon: Icons.receipt_long_rounded,
                  color: Colors.blue,
                  subtitle: 'Payment transactions',
                ),
                _statCard(
                  title: 'Average Payment',
                  value:
                      '৳ ${_formatNumber(_decimal(fees, 'average_payment'))}',
                  icon: Icons.trending_up_rounded,
                  color: Colors.orange,
                  subtitle: 'Average per transaction',
                ),
              ], constraints.maxWidth),

              const SizedBox(height: 30),

              _sectionTitle('Attendance Statistics', Icons.fact_check_rounded),

              _reportGrid([
                _statCard(
                  title: 'Total Attendance',
                  value: _formatNumber(_number(attendance, 'total')),
                  icon: Icons.calendar_month_rounded,
                  color: Colors.blue,
                  subtitle: 'Recorded attendance entries',
                ),
                _statCard(
                  title: 'Present',
                  value: _formatNumber(_number(attendance, 'present')),
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                  subtitle: 'Present entries',
                ),
                _statCard(
                  title: 'Absent',
                  value: _formatNumber(_number(attendance, 'absent')),
                  icon: Icons.cancel_rounded,
                  color: Colors.red,
                  subtitle: 'Absent entries',
                ),
                _statCard(
                  title: 'Leave',
                  value: _formatNumber(_number(attendance, 'leave')),
                  icon: Icons.event_busy_rounded,
                  color: Colors.orange,
                  subtitle: 'Leave entries',
                ),
              ], constraints.maxWidth),

              const SizedBox(height: 30),

              _sectionTitle('Academic Results', Icons.school_rounded),

              _reportGrid([
                _statCard(
                  title: 'Total Results',
                  value: _formatNumber(_number(results, 'total')),
                  icon: Icons.assignment_rounded,
                  color: Colors.blue,
                  subtitle: 'Recorded result entries',
                ),
                _statCard(
                  title: 'Average Marks',
                  value: _formatNumber(_decimal(results, 'average_marks')),
                  icon: Icons.analytics_rounded,
                  color: Colors.purple,
                  subtitle: 'Average marks',
                ),
                _statCard(
                  title: 'Highest Marks',
                  value: _formatNumber(_decimal(results, 'highest_marks')),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.green,
                  subtitle: 'Highest recorded marks',
                ),
                _statCard(
                  title: 'Lowest Marks',
                  value: _formatNumber(_decimal(results, 'lowest_marks')),
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.orange,
                  subtitle: 'Lowest recorded marks',
                ),
              ], constraints.maxWidth),

              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }
}
