import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Account Settings',
            [
              _buildSettingsTile(Icons.person_outline_rounded, 'Profile Information', 'Name, Email, Job Title'),
              _buildSettingsTile(Icons.security_rounded, 'Security & Password', '2FA, Password update'),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSection(
            'Notifications',
            [
              _buildSettingsTile(Icons.notifications_none_rounded, 'Push Notifications', 'Alerts, Task reminders', showToggle: true),
              _buildSettingsTile(Icons.mail_outline_rounded, 'Email Updates', 'Reports, Daily summaries', showToggle: true),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSection(
            'System',
            [
              _buildSettingsTile(Icons.language_rounded, 'Language', 'English (US)'),
              _buildSettingsTile(Icons.dark_mode_outlined, 'Dark Appearance', 'System default', showToggle: true),
              _buildSettingsTile(Icons.cloud_sync_rounded, 'Data Synchronization', 'Last sync: 2m ago'),
            ],
          ),
          const SizedBox(height: 40),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Configure your workspace and preferences',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey100),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {bool showToggle = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.navy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.navy),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400),
      ),
      trailing: showToggle
          ? Switch(
              value: true,
              onChanged: (v) {},
              activeColor: AppColors.gold,
            )
          : const Icon(Icons.chevron_right_rounded, color: AppColors.grey200),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Maintenance',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error),
                ),
                Text(
                  'Restore system to factory defaults',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.error.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Reset',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
