import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ProjectDashboard extends StatelessWidget {
  const ProjectDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildProjectStats(),
          const SizedBox(height: 24),
          _buildRecentProjects(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Dashboard',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          'Track active and completed projects',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectStats() {
    return Row(
      children: [
        _buildProjectStatCard('In Progress', '8 Projects', Icons.work_history_rounded, Colors.blue),
        const SizedBox(width: 12),
        _buildProjectStatCard('Overdue', '2 Projects', Icons.report_problem_rounded, Colors.red),
      ],
    );
  }

  Widget _buildProjectStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400)),
            Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjects() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Center(
        child: Icon(Icons.rocket_launch_rounded, size: 64, color: AppColors.grey100),
      ),
    );
  }
}
