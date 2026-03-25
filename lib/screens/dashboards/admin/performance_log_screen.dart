import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PerformanceLogScreen extends StatelessWidget {
  const PerformanceLogScreen({super.key});

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
          _buildTopPerformers(),
          const SizedBox(height: 24),
          _buildDepartmentEffort(),
          const SizedBox(height: 24),
          _buildRecentAchievements(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Log',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Track and analyze employee productivity',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
        ),
      ],
    );
  }

  Widget _buildTopPerformers() {
    final performers = [
      {'name': 'Alex Johnson', 'score': '98%', 'rank': 1, 'color': Colors.amber},
      {'name': 'Sarah Jenkins', 'score': '95%', 'rank': 2, 'color': AppColors.grey400},
      {'name': 'Mike Ross', 'score': '92%', 'rank': 3, 'color': Colors.brown},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Performers', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
              const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          ...performers.map((p) => _buildPerformerRow(p)),
        ],
      ),
    );
  }

  Widget _buildPerformerRow(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (p['color'] as Color).withOpacity(0.1), // Assuming withValues was meant to be withOpacity
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                p['rank'].toString(),
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: p['color'] as Color, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(p['name'] as String, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const Spacer(),
          Text(p['score'] as String, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildDepartmentEffort() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department Efficiency', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 20),
          _buildProgressItem('Engineering', 0.85, Colors.blue),
          _buildProgressItem('Sales', 0.72, Colors.green),
          _buildProgressItem('Marketing', 0.65, Colors.purple),
          _buildProgressItem('Customer Support', 0.92, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grey600)),
              Text('${(value * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.grey100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Milestones', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
        const SizedBox(height: 12),
        _buildAchievementTile('Project Apollo Completed', 'Sales Team', '2h ago', Icons.check_circle_rounded, Colors.green),
        _buildAchievementTile('New Client Onboarded', 'Account Management', '5h ago', Icons.person_add_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildAchievementTile(String title, String dept, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text(dept, style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400)),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.grey400)),
        ],
      ),
    );
  }
}
