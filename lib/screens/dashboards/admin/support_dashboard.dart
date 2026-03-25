import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SupportDashboard extends StatelessWidget {
  const SupportDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSupportStats(),
          const SizedBox(height: 24),
          _buildActiveTickets(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Dashboard',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          'Track and resolve customer issues',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportStats() {
    return Row(
      children: [
        _buildSupportCard('Open Tickets', '12', Icons.confirmation_number_rounded, Colors.red),
        const SizedBox(width: 12),
        _buildSupportCard('Resolved (24h)', '34', Icons.check_circle_rounded, Colors.green),
      ],
    );
  }

  Widget _buildSupportCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildActiveTickets() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Center(
        child: Icon(Icons.support_agent_rounded, size: 64, color: AppColors.grey100),
      ),
    );
  }
}
