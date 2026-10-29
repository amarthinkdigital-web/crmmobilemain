import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'manager/manager_work_log_screen.dart';
import 'hr/team_pending_approvals_screen.dart';

import 'employee/daily_work_log_screen.dart';

class DailyWorksheetsActionCard extends StatefulWidget {
  const DailyWorksheetsActionCard({super.key});

  @override
  State<DailyWorksheetsActionCard> createState() => _DailyWorksheetsActionCardState();
}

class _DailyWorksheetsActionCardState extends State<DailyWorksheetsActionCard> {
  bool _isLoading = true;
  int _pendingCount = 0;
  String _userRole = 'manager';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final role = await AuthService.getUserRole();
      if (mounted) {
        _userRole = role?.toLowerCase() ?? 'manager';
      }

      // Fetch pending count
      final res = await ApiService.getTeamPendingWorksheets();
      if (mounted) {
        if (res['error'] == false) {
          final List data = res['data'] ?? [];
          _pendingCount = data.length;
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      // Refresh count when coming back
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Worksheets",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      "Manage your work logs and team reviews",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                )
              else
                IconButton(
                  onPressed: _fetchData,
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.grey400),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: "My Work Log",
                  icon: Icons.edit_note_rounded,
                  color: Colors.blue,
                  onTap: () {
                    // Logic to show manager or employee work log
                    if (_userRole == 'manager' || _userRole == 'hr' || _userRole == 'admin') {
                      _navigateTo(const ManagerWorkLogScreen());
                    } else {
                      _navigateTo(const DailyWorkLogScreen());
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: "Pending Approvals",
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  badgeCount: _pendingCount,
                  onTap: () {
                    _navigateTo(const TeamPendingApprovalsScreen());
                  },
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 32, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
