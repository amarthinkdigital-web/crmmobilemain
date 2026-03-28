import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ManagerSalaryScreen extends StatefulWidget {
  const ManagerSalaryScreen({super.key});

  @override
  State<ManagerSalaryScreen> createState() => _ManagerSalaryScreenState();
}

class _ManagerSalaryScreenState extends State<ManagerSalaryScreen> {
  String selectedMonth = "March 2026";
  final List<String> monthOptions = [
    "January 2026",
    "February 2026",
    "March 2026",
  ];

  final List<Map<String, dynamic>> executiveHistory = [
    {
      "month": "March",
      "base": "\$4,500",
      "performance": "Outstanding",
      "attendance": "22/26",
      "payableDays": "26",
      "deductions": "-\$150",
      "netPayout": "\$4,850",
      "status": "Processed",
    },
    {
      "month": "February",
      "base": "\$4,500",
      "performance": "Good",
      "attendance": "24/26",
      "payableDays": "24",
      "deductions": "-\$300",
      "netPayout": "\$4,200",
      "status": "Transferred",
    },
    {
      "month": "January",
      "base": "\$4,500",
      "performance": "Excellent",
      "attendance": "26/26",
      "payableDays": "26",
      "deductions": "\$0",
      "netPayout": "\$5,000",
      "status": "Complete",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExecutiveHeader(),
            const SizedBox(height: 32),
            _buildExecutiveQuickStats(),
            const SizedBox(height: 40),
            _buildMatrixHeader(),
            const SizedBox(height: 16),
            _buildExecutiveSalaryTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Executive Payroll",
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
                letterSpacing: -1.2,
              ),
            ),
            Text(
              "Management distribution & history",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedMonth,
              items: monthOptions
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => selectedMonth = v!),
              style: GoogleFonts.inter(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              icon: const Icon(
                Icons.arrow_circle_down_rounded,
                size: 18,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveQuickStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildManagerStatTile(
          "Leave Credits",
          "18 Days",
          AppColors.info,
          Icons.badge_outlined,
        ),
        _buildManagerStatTile(
          "Management Base",
          "\$4,500",
          AppColors.navy,
          Icons.shield_rounded,
        ),
        _buildManagerStatTile(
          "Executive Deduction",
          "\$150",
          AppColors.error,
          Icons.money_off_csred_rounded,
        ),
        _buildManagerStatTile(
          "Actual Transfer",
          "\$4,850",
          AppColors.success,
          Icons.payments_rounded,
        ),
      ],
    );
  }

  Widget _buildManagerStatTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Remuneration Matrix",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Icon(Icons.more_horiz_rounded, color: AppColors.grey400),
      ],
    );
  }

  Widget _buildExecutiveSalaryTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          headingRowHeight: 64,
          headingTextStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.grey600,
          ),
          dataTextStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
          columns: const [
            DataColumn(label: Text("Month")),
            DataColumn(label: Text("Base Salary")),
            DataColumn(label: Text("Performance")),
            DataColumn(label: Text("Attendance")),
            DataColumn(label: Text("Payable Days")),
            DataColumn(label: Text("Deduction")),
            DataColumn(label: Text("Net Payout")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Breakdown")),
          ],
          rows: executiveHistory
              .map((data) => _buildExecutiveDataRow(data))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildExecutiveDataRow(Map<String, dynamic> data) {
    return DataRow(
      cells: [
        DataCell(Text(data['month'])),
        DataCell(Text(data['base'])),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data['performance'],
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        DataCell(Text(data['attendance'])),
        DataCell(Text(data['payableDays'])),
        DataCell(
          Text(
            data['deductions'],
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        DataCell(
          Text(
            data['netPayout'],
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        DataCell(_buildManagerStatusBadge(data['status'])),
        DataCell(
          IconButton(
            onPressed: () => _showExecutiveBreakdownModal(data),
            icon: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.gold,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagerStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showExecutiveBreakdownModal(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${data['month']} Remuneration Audit",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildExecutiveBreakdownItem("Management Allowance", "\$1,000"),
            _buildExecutiveBreakdownItem(
              "Strategy Performance Incentive",
              "\$500",
            ),
            _buildExecutiveBreakdownItem(
              "Executive Professional Tax",
              "-\$150",
            ),
            const Divider(height: 48, color: AppColors.grey100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Actual Executive Payout",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey400,
                  ),
                ),
                Text(
                  data['netPayout'],
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveBreakdownItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: value.startsWith('-') ? AppColors.error : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
