import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                   Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                      border: Border.all(color: AppColors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.gold, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              userName,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            Text(
              userEmail,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(height: 40),
            _buildProfileOption(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.security_rounded,
              label: 'Security',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try { await ApiService.logout(); } catch (_) {}
                  onLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorBg,
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.navy),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
      ),
    );
  }
}
