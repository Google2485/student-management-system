import 'package:flutter/material.dart';

import '../services/settings_api_service.dart';

class SettingsPage extends StatefulWidget {
  final String token;
  final String adminName;
  final String adminEmail;

  const SettingsPage({
    super.key,
    required this.token,
    required this.adminName,
    required this.adminEmail,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color primary = Color(0xFF6258E8);

  int selectedSection = 0;
  bool isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final institutionNameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final institutionEmailController = TextEditingController();
  final logoController = TextEditingController();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool emailNotifications = true;
  bool studentNotifications = true;
  bool feeNotifications = true;
  bool attendanceNotifications = true;

  String theme = 'light';

  final List<Map<String, dynamic>> sections = [
    {'title': 'Profile Settings', 'icon': Icons.person_outline_rounded},
    {'title': 'Institution Settings', 'icon': Icons.school_outlined},
    {'title': 'Security Settings', 'icon': Icons.lock_outline_rounded},
    {'title': 'Notification Settings', 'icon': Icons.notifications_outlined},
    {'title': 'Appearance Settings', 'icon': Icons.palette_outlined},
  ];

  @override
  void initState() {
    super.initState();

    nameController.text = widget.adminName;
    emailController.text = widget.adminEmail;

    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        SettingsApiService.getProfile(widget.token),
        SettingsApiService.getInstitution(widget.token),
        SettingsApiService.getNotifications(widget.token),
        SettingsApiService.getPreferences(widget.token),
      ]);

      if (!mounted) return;

      final profile = results[0];
      final institution = results[1];
      final notifications = results[2];
      final preferences = results[3];

      nameController.text = profile['name']?.toString() ?? widget.adminName;
      emailController.text = profile['email']?.toString() ?? widget.adminEmail;

      institutionNameController.text =
          institution['institution_name']?.toString() ?? '';
      addressController.text = institution['address']?.toString() ?? '';
      phoneController.text = institution['phone']?.toString() ?? '';
      institutionEmailController.text = institution['email']?.toString() ?? '';
      logoController.text = institution['logo']?.toString() ?? '';

      emailNotifications = _toBool(notifications['email_notifications']);
      studentNotifications = _toBool(notifications['student_notifications']);
      feeNotifications = _toBool(notifications['fee_notifications']);
      attendanceNotifications = _toBool(
        notifications['attendance_notifications'],
      );

      theme = preferences['theme']?.toString() ?? 'light';

      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showMessage('Settings load failed: $e', isError: true);
    }
  }

  bool _toBool(dynamic value) {
    return value == true || value.toString() == '1';
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      _showMessage('Name and email are required', isError: true);
      return;
    }

    await _save(() async {
      await SettingsApiService.updateProfile(widget.token, {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
      });
    }, 'Profile updated successfully');
  }

  Future<void> _saveInstitution() async {
    await _save(() async {
      await SettingsApiService.updateInstitution(widget.token, {
        'institution_name': institutionNameController.text.trim(),
        'address': addressController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': institutionEmailController.text.trim(),
        'logo': logoController.text.trim(),
      });
    }, 'Institution settings saved successfully');
  }

  Future<void> _changePassword() async {
    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill in all password fields', isError: true);
      return;
    }

    if (newPasswordController.text.length < 8) {
      _showMessage('Password must be at least 8 characters', isError: true);
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _showMessage('New passwords do not match', isError: true);
      return;
    }

    await _save(() async {
      await SettingsApiService.changePassword(widget.token, {
        'current_password': currentPasswordController.text,
        'new_password': newPasswordController.text,
        'confirm_password': confirmPasswordController.text,
      });
    }, 'Password changed successfully');

    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  Future<void> _saveNotifications() async {
    await _save(() async {
      await SettingsApiService.updateNotifications(widget.token, {
        'email_notifications': emailNotifications,
        'student_notifications': studentNotifications,
        'fee_notifications': feeNotifications,
        'attendance_notifications': attendanceNotifications,
      });
    }, 'Notification settings saved');
  }

  Future<void> _saveTheme() async {
    await _save(() async {
      await SettingsApiService.updatePreferences(widget.token, {
        'theme': theme,
      });
    }, 'Appearance settings saved');
  }

  Future<void> _save(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => isLoading = true);

    try {
      await action();

      if (!mounted) return;

      setState(() => isLoading = false);
      _showMessage(successMessage);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();

    institutionNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    institutionEmailController.dispose();
    logoController.dispose();

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FC),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 750;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage your account and system preferences',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 22),

                      if (mobile) ...[
                        _mobileSectionSelector(),
                        const SizedBox(height: 20),
                      ],

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!mobile) ...[
                            SizedBox(width: 230, child: _sectionSidebar()),
                            const SizedBox(width: 20),
                          ],

                          Expanded(child: _contentCard()),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _mobileSectionSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedSection,
          isExpanded: true,
          items: List.generate(
            sections.length,
            (index) => DropdownMenuItem(
              value: index,
              child: Row(
                children: [
                  Icon(sections[index]['icon'], color: primary),
                  const SizedBox(width: 10),
                  Text(sections[index]['title']),
                ],
              ),
            ),
          ),
          onChanged: (value) {
            if (value != null) setState(() => selectedSection = value);
          },
        ),
      ),
    );
  }

  Widget _sectionSidebar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: List.generate(sections.length, (index) {
          final selected = selectedSection == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: ListTile(
              selected: selected,
              selectedTileColor: primary.withValues(alpha: 0.10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: Icon(
                sections[index]['icon'],
                color: selected ? primary : Colors.grey,
              ),
              title: Text(
                sections[index]['title'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? primary : Colors.black87,
                ),
              ),
              onTap: () => setState(() => selectedSection = index),
            ),
          );
        }),
      ),
    );
  }

  Widget _contentCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sections[selectedSection]['icon'], color: primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sections[selectedSection]['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          if (selectedSection == 0) _profileSection(),
          if (selectedSection == 1) _institutionSection(),
          if (selectedSection == 2) _securitySection(),
          if (selectedSection == 3) _notificationSection(),
          if (selectedSection == 4) _appearanceSection(),
        ],
      ),
    );
  }

  Widget _profileSection() {
    return Column(
      children: [
        _field('Full Name', nameController, Icons.person_outline),
        _field('Email Address', emailController, Icons.email_outlined),
        const SizedBox(height: 20),
        _saveButton('Save Profile', _saveProfile),
      ],
    );
  }

  Widget _institutionSection() {
    return Column(
      children: [
        _field(
          'Institution Name',
          institutionNameController,
          Icons.school_outlined,
        ),
        _field('Address', addressController, Icons.location_on_outlined),
        _field('Phone', phoneController, Icons.phone_outlined),
        _field(
          'Institution Email',
          institutionEmailController,
          Icons.email_outlined,
        ),
        _field('Logo URL', logoController, Icons.image_outlined),
        const SizedBox(height: 20),
        _saveButton('Save Institution Settings', _saveInstitution),
      ],
    );
  }

  Widget _securitySection() {
    return Column(
      children: [
        _field(
          'Current Password',
          currentPasswordController,
          Icons.lock_outline,
          password: true,
        ),
        _field(
          'New Password',
          newPasswordController,
          Icons.lock_reset,
          password: true,
        ),
        _field(
          'Confirm New Password',
          confirmPasswordController,
          Icons.lock_outline,
          password: true,
        ),
        const SizedBox(height: 20),
        _saveButton('Change Password', _changePassword),
      ],
    );
  }

  Widget _notificationSection() {
    return Column(
      children: [
        _switchTile(
          'Email Notifications',
          'Receive system notifications by email',
          emailNotifications,
          (value) => emailNotifications = value,
        ),
        _switchTile(
          'Student Notifications',
          'Notifications related to student records',
          studentNotifications,
          (value) => studentNotifications = value,
        ),
        _switchTile(
          'Fee Notifications',
          'Notifications about student payments',
          feeNotifications,
          (value) => feeNotifications = value,
        ),
        _switchTile(
          'Attendance Notifications',
          'Notifications about attendance records',
          attendanceNotifications,
          (value) => attendanceNotifications = value,
        ),
        const SizedBox(height: 20),
        _saveButton('Save Notifications', _saveNotifications),
      ],
    );
  }

  Widget _appearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your preferred theme',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 15),
        RadioGroup<String>(
          groupValue: theme,
          onChanged: (value) {
            if (value != null) setState(() => theme = value);
          },
          child: const Column(
            children: [
              RadioListTile<String>(
                value: 'light',
                title: Text('Light Theme'),
                subtitle: Text('Clean and bright interface'),
              ),
              RadioListTile<String>(
                value: 'dark',
                title: Text('Dark Theme'),
                subtitle: Text('Comfortable in low-light environments'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _saveButton('Save Appearance', _saveTheme),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: TextField(
        controller: controller,
        obscureText: password,
        maxLines: password ? 1 : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF8F8FC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _switchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: primary,
      onChanged: (newValue) {
        setState(() => onChanged(newValue));
      },
    );
  }

  Widget _saveButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: const Icon(Icons.save_outlined),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
