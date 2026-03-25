import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PayrollManagementScreen extends StatefulWidget {
  const PayrollManagementScreen({super.key});

  @override
  State<PayrollManagementScreen> createState() =>
      _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen> {
  String selectedMonth = "March";
  String selectedYear = "2026";

  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];
  final List<String> years = ["2023", "2024", "2025", "2026"];

  final List<Map<String, dynamic>> payrollData = [
    {
      "employee": "John Doe",
      "baseRate": "\$2,500",
      "offDays": "4",
      "pl": "1",
      "absent": "0",
      "totalPaid": "26",
      "netSalary": "\$2,450",
      "status": "Paid",
    },
    {
      "employee": "Jane Smith",
      "baseRate": "\$3,000",
      "offDays": "4",
      "pl": "0",
      "absent": "2",
      "totalPaid": "24",
      "netSalary": "\$2,750",
      "status": "Unpaid",
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
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilterSection(),
            const SizedBox(height: 32),
            _buildPayrollHeaderRow(),
            const SizedBox(height: 16),
            _buildPayrollTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payroll Management",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Handle employee salaries, deductions, and monthly disbursements",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallDropdown(
                selectedMonth,
                months,
                (v) => setState(() => selectedMonth = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallDropdown(
                selectedYear,
                years,
                (v) => setState(() => selectedYear = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text("Export"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: AppColors.grey200),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text("Generate"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallDropdown(
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          style: GoogleFonts.inter(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPayrollHeaderRow() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payroll Sheet",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            Text(
              "$selectedMonth $selectedYear",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.goldDark,
              ),
            ),
          ],
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.sync_rounded, size: 16),
          label: const Text("Sync All Data"),
          style: TextButton.styleFrom(foregroundColor: AppColors.navy),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.done_all_rounded, size: 16),
          label: const Text("Mark All Read"),
          style: TextButton.styleFrom(foregroundColor: AppColors.success),
        ),
      ],
    );
  }

  Widget _buildPayrollTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.navy.withValues(alpha: 0.05),
            ),
            columnSpacing: 40,
            columns: [
              _buildDataColumn("Employee"),
              _buildDataColumn("Base/Rate P/H"),
              _buildDataColumn("Off Days"),
              _buildDataColumn("PL"),
              _buildDataColumn("Absent"),
              _buildDataColumn("Total Paid"),
              _buildDataColumn("Net Salary"),
              _buildDataColumn("Status"),
              _buildDataColumn("Actions"),
            ],
            rows: payrollData.map((data) => _buildRow(data)).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }

  DataRow _buildRow(Map<String, dynamic> data) {
    final bool isPaid = data['status'] == "Paid";

    return DataRow(
      cells: [
        DataCell(
          Text(
            data['employee'],
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            data['baseRate'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            data['offDays'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            data['pl'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            data['absent'],
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Text(
            data['totalPaid'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            data['netSalary'],
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPaid ? AppColors.success : AppColors.error).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['status'],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isPaid ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildActionIcon(
                Icons.refresh_rounded,
                AppColors.info,
                "Refresh",
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.money_off_csred_rounded,
                AppColors.error,
                "Unpaid",
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.receipt_long_rounded,
                AppColors.navy,
                "Deduction Details",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, String tooltip) {
    return InkWell(
      onTap: () {},
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
