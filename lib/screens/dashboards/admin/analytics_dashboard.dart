import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildChartPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          'Insights and performance metrics',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Revenue', '\$12,450', Icons.payments_rounded, Colors.green),
        const SizedBox(width: 12),
        _buildStatCard('Growth', '+18%', Icons.trending_up_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildChartPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Center(
        child: Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.grey100),
      ),
    );
  }
}
