import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildCustomerStats(),
          const SizedBox(height: 24),
          _buildRecentCustomers(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Dashboard',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          'Manage relationships and satisfaction',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerStats() {
    return Row(
      children: [
        _buildCustomerCard('New Customers', '45', Icons.person_add_rounded, Colors.purple),
        const SizedBox(width: 12),
        _buildCustomerCard('Satisfaction', '4.8/5', Icons.recommend_rounded, Colors.amber),
      ],
    );
  }

  Widget _buildCustomerCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildRecentCustomers() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Center(
        child: Icon(Icons.people_alt_rounded, size: 64, color: AppColors.grey100),
      ),
    );
  }
}
