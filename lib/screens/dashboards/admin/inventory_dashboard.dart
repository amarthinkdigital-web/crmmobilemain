import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class InventoryDashboard extends StatelessWidget {
  const InventoryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInventoryStats(),
          const SizedBox(height: 24),
          _buildStockLevel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Dashboard',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          'Stock and supply management',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryStats() {
    return Row(
      children: [
        _buildInventoryCard('Total Items', '1,245', Icons.inventory_2_rounded, Colors.teal),
        const SizedBox(width: 12),
        _buildInventoryCard('Low Stock', '18 Items', Icons.warning_amber_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildInventoryCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildStockLevel() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Center(
        child: Icon(Icons.warehouse_rounded, size: 64, color: AppColors.grey100),
      ),
    );
  }
}
