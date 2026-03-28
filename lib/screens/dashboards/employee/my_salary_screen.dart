import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MySalaryScreen extends StatefulWidget {
  const MySalaryScreen({super.key});

  @override
  State<MySalaryScreen> createState() => _MySalaryScreenState();
}

class _MySalaryScreenState extends State<MySalaryScreen> {
  String selectedMonth = "March 2026";
  final List<String> monthOptions = [
    "January 2026",
    "February 2026",
    "March 2026",
  ];

  final List<Map<String, dynamic>> salaryHistory = [
    {
      "month": "March",
      "base": "\$2,500",
      "performance": "Good",
      "attendance": "22/26",
      "payableDays": "26",
      "deductions": "-\$50",
      "netPayout": "\$2,450",
      "status": "Paid",
    },
    {
      "month": "February",
      "base": "\$2,500",
      "performance": "Average",
      "attendance": "20/26",
      "payableDays": "24",
      "deductions": "-\$150",
      "netPayout": "\$2,350",
      "status": "Paid",
    },
    {
      "month": "January",
      "base": "\$2,500",
      "performance": "Excellent",
      "attendance": "24/26",
      "payableDays": "26",
      "deductions": "\$0",
      "netPayout": "\$2,500",
      "status": "Paid",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopSection(),
            const SizedBox(height: 32),
            _buildQuickStats(),
            const SizedBox(height: 40),
            _buildPayrollHeader(),
            const SizedBox(height: 16),
            _buildSalaryTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Payroll",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
                letterSpacing: -1,
              ),
            ),
            Text(
              "Financial distribution & history",
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
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
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              icon: const Icon(
                Icons.arrow_drop_down_circle_outlined,
                size: 18,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatTile(
          "Leave Balance",
          "12 Days",
          AppColors.info,
          Icons.calendar_today_rounded,
        ),
        _buildStatTile(
          "March Base",
          "\$2,500",
          AppColors.navy,
          Icons.account_balance_rounded,
        ),
        _buildStatTile(
          "March Deduction",
          "\$50",
          AppColors.error,
          Icons.money_off_csred_rounded,
        ),
        _buildStatTile(
          "March Payout",
          "\$2,450",
          AppColors.success,
          Icons.payments_rounded,
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
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

  Widget _buildPayrollHeader() {
    return Text(
      "Salary Distribution Matrix",
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildSalaryTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 56,
          headingTextStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.grey600,
          ),
          dataTextStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
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
          rows: salaryHistory.map((data) => _buildDataRow(data)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> data) {
    return DataRow(
      cells: [
        DataCell(Text(data['month'])),
        DataCell(Text(data['base'])),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              data['performance'],
              style: const TextStyle(color: AppColors.goldDark, fontSize: 11),
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
            ),
          ),
        ),
        DataCell(_buildStatusBadge(data['status'])),
        DataCell(
          IconButton(
            onPressed: () => _showBreakdownDetails(data),
            icon: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.navy,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showBreakdownDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
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
                  "${data['month']} Detailed Breakdown",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildBreakdownItem("Allowance (HRA)", "\$400"),
            _buildBreakdownItem("Performance Incentive", "\$200"),
            _buildBreakdownItem("Professional Tax", "-\$50"),
            _buildBreakdownItem("Leave Encashment", "\$50"),
            const Divider(height: 32, color: AppColors.grey100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Distribution",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey400,
                  ),
                ),
                Text(
                  data['netPayout'],
                  style: GoogleFonts.inter(
                    fontSize: 20,
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

  Widget _buildBreakdownItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: value.startsWith('-') ? AppColors.error : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
