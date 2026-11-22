import 'package:flutter/material.dart';

class HelpCenterPage extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const HelpCenterPage({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  static const Color primary = Color(0xFF6258E8);

  final searchController = TextEditingController();

  final List<Map<String, dynamic>> guides = [
    {
      'title': 'Student Management',
      'description': 'Add, edit, search and manage student information.',
      'icon': Icons.people_alt_outlined,
      'index': 1,
    },
    {
      'title': 'Courses',
      'description': 'Create courses and manage course information.',
      'icon': Icons.menu_book_outlined,
      'index': 2,
    },
    {
      'title': 'Departments',
      'description': 'Organize and manage academic departments.',
      'icon': Icons.account_tree_outlined,
      'index': 3,
    },
    {
      'title': 'Attendance',
      'description': 'Record and manage student attendance.',
      'icon': Icons.fact_check_outlined,
      'index': 4,
    },
    {
      'title': 'Fees & Payments',
      'description': 'Manage student fees, payments and dues.',
      'icon': Icons.payments_outlined,
      'index': 5,
    },
    {
      'title': 'Academic Results',
      'description': 'Enter marks and manage academic results.',
      'icon': Icons.school_outlined,
      'index': 6,
    },
    {
      'title': 'Settings',
      'description': 'Update profile, password and system preferences.',
      'icon': Icons.settings_outlined,
      'index': 8,
    },
  ];

  final List<Map<String, String>> faqs = [
    {
      'question': 'How can I add a new student?',
      'answer':
          'Open Student Management from the sidebar. Click the Add Student button, fill in the required information and save. The student will be added to the student list.',
    },
    {
      'question': 'How can I edit student information?',
      'answer':
          'Go to Student Management, find the student you want to update and use the Edit option. Update the information and save your changes.',
    },
    {
      'question': 'How do I create a new course?',
      'answer':
          'Open the Courses page from the sidebar. Use the Add Course option, enter the course information and save it.',
    },
    {
      'question': 'How can I record attendance?',
      'answer':
          'Open Attendance from the sidebar. Select the available class or student information, mark attendance and save the records.',
    },
    {
      'question': 'How can I record student fee payments?',
      'answer':
          'Open Fees & Payments. Select the relevant student, enter the payment information and save the transaction.',
    },
    {
      'question': 'How does the grading system work?',
      'answer':
          'The system calculates grades based on marks. A+ = 80–100, A = 70–79, A- = 60–69, B = 50–59, C = 40–49, D = 33–39 and F = 0–32.',
    },
    {
      'question': 'How can I change my admin password?',
      'answer':
          'Go to Settings from the sidebar, open Security Settings, enter your current password and your new password, confirm it and save.',
    },
    {
      'question': 'Why can I not see my updated information?',
      'answer':
          'Check that your changes were saved successfully. If the information is still not updated, refresh the page and check again.',
    },
    {
      'question': 'What should I do if a page shows an error?',
      'answer':
          'First refresh the page and try again. Check your internet connection. If the problem continues, note the error message and contact the system administrator.',
    },
  ];

  List<Map<String, String>> get filteredFaqs {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return faqs;

    return faqs.where((faq) {
      return faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredFaqs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 25),
          _searchBox(),
          const SizedBox(height: 30),
          _sectionTitle('Quick Guides', 'Navigate directly to a module'),
          const SizedBox(height: 15),
          _guideGrid(),
          const SizedBox(height: 35),
          _sectionTitle('Frequently Asked Questions', 'Find answers to common questions'),
          const SizedBox(height: 15),
          _faqSection(filtered),
          const SizedBox(height: 30),
          _supportCard(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6258E8), Color(0xFF8982F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 42,
            color: Colors.white,
          ),
          const SizedBox(height: 15),
          const Text(
            'Help Center',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How can we help you today?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Explore guides and find answers to your questions.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search help articles or questions...',
        prefixIcon: const Icon(Icons.search, color: primary),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _guideGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: guides.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            mainAxisExtent: 145,
          ),
          itemBuilder: (context, index) {
            final guide = guides[index];

            return InkWell(
              onTap: () => widget.onNavigate(guide['index'] as int),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      guide['icon'] as IconData,
                      size: 28,
                      color: primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      guide['title'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        guide['description'] as String,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _faqSection(List<Map<String, String>> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 10),
            Text('No questions found'),
            SizedBox(height: 5),
            Text(
              'Try searching with a different keyword.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final faq = items[index];

          return Column(
            children: [
              ExpansionTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: primary,
                ),
                title: Text(
                  faq['question']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq['answer']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        height: 1.6,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _supportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: primary, size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need more help?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 7),
                Text(
                  'If you cannot find an answer, contact your system administrator '
                  'and describe the problem you are experiencing.',
                  style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
