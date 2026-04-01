import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/salary_model.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

class MySalaryScreen extends StatefulWidget {
  const MySalaryScreen({super.key});

  @override
  State<MySalaryScreen> createState() => _MySalaryScreenState();
}

class _MySalaryScreenState extends State<MySalaryScreen> {
  String _selectedMonth = DateTime.now().month.toString();
  String _selectedYear = DateTime.now().year.toString();

  final List<Map<String, String>> _months = [
    {"id": "1", "name": "January"},
    {"id": "2", "name": "February"},
    {"id": "3", "name": "March"},
    {"id": "4", "name": "April"},
    {"id": "5", "name": "May"},
    {"id": "6", "name": "June"},
    {"id": "7", "name": "July"},
    {"id": "8", "name": "August"},
    {"id": "9", "name": "September"},
    {"id": "10", "name": "October"},
    {"id": "11", "name": "November"},
    {"id": "12", "name": "December"},
  ];
  final List<String> _years = ["2023", "2024", "2025", "2026"];

  bool _isLoading = true;
  List<Salary> _salaries = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSalaries();
  }

  Future<void> _fetchSalaries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.getMySalaries(
      month: int.tryParse(_selectedMonth),
      year: int.tryParse(_selectedYear),
    );

    if (response['error'] == false) {
      final dynamic rawData = response['data'];
      List data = [];
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map) {
         if (rawData.containsKey('salaries') && rawData['salaries'] is List) {
            data = rawData['salaries'];
         } else if (rawData.containsKey('data') && rawData['data'] is List) {
            data = rawData['data'];
         } else {
            data = rawData.values.firstWhere((v) => v is List, orElse: () => []) as List;
         }
      }
      setState(() {
        _salaries = data.map((json) => Salary.fromJson(json)).toList();
        
        // Locally filter if backend returns all months
        int m = int.tryParse(_selectedMonth) ?? 0;
        int y = int.tryParse(_selectedYear) ?? 0;
        if (m > 0 && y > 0) {
          final filtered = _salaries.where((s) => s.month == m && s.year == y).toList();
          // if we found matches, or the returned list clearly includes other months too, then show the filtered slice
          if (filtered.isNotEmpty || (_salaries.isNotEmpty && _salaries.first.month != m && _salaries.length > 1)) {
            _salaries = filtered;
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response['message'];
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _fetchSalaries,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchSalaries,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopSection(),
                    const SizedBox(height: 24),
                    _buildFilterSection(),
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
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
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
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallDropdown(
            _selectedMonth,
            _months.map((m) => m['id']!).toList(),
            (v) {
              setState(() => _selectedMonth = v!);
              _fetchSalaries();
            },
            labels: _months.map((m) => m['name']!).toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallDropdown(_selectedYear, _years, (v) {
            setState(() => _selectedYear = v!);
            _fetchSalaries();
          }),
        ),
      ],
    );
  }

  Widget _buildSmallDropdown(
    String value,
    List<String> items,
    void Function(String?) onChanged, {
    List<String>? labels,
  }) {
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
          isExpanded: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          style: GoogleFonts.inter(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: List.generate(items.length, (index) {
            return DropdownMenuItem(
              value: items[index],
              child: Text(labels != null ? labels[index] : items[index]),
            );
          }),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final latest = _salaries.isNotEmpty ? _salaries.first : null;
    final monthName = latest != null
        ? DateFormat('MMMM').format(DateTime(2026, latest.month ?? 1))
        : "Current";

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
          "Calculated",
          AppColors.info,
          Icons.calendar_today_rounded,
        ),
        _buildStatTile(
          "$monthName Base",
          latest?.baseSalary != null ? "₹${latest!.baseSalary}" : "0",
          AppColors.navy,
          Icons.account_balance_rounded,
        ),
        _buildStatTile(
          "Deduction",
          latest != null
              ? "₹${(double.tryParse(latest.baseSalary ?? "0") ?? 0) - (double.tryParse(latest.netSalary ?? "0") ?? 0)}"
              : "0",
          AppColors.error,
          Icons.money_off_csred_rounded,
        ),
        _buildStatTile(
          "Payout",
          latest?.netSalary != null ? "₹${latest!.netSalary}" : "0",
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
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
                overflow: TextOverflow.ellipsis,
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
    if (_salaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            "No salary records found",
            style: TextStyle(color: AppColors.grey400),
          ),
        ),
      );
    }
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
            DataColumn(label: Text("Month/Year")),
            DataColumn(label: Text("Base Salary")),
            DataColumn(label: Text("Net Salary")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Actions")),
          ],
          rows: _salaries.map((s) => _buildDataRow(s)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Salary salary) {
    final monthName = DateFormat(
      'MMM',
    ).format(DateTime(2026, salary.month ?? 1));
    return DataRow(
      cells: [
        DataCell(Text("$monthName ${salary.year}")),
        DataCell(Text("₹${salary.baseSalary ?? "0"}")),
        DataCell(
          Text(
            "₹${salary.netSalary ?? "0"}",
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        DataCell(_buildStatusBadge(salary.status ?? "Unpaid")),
        DataCell(
          IconButton(
            onPressed: () => _fetchAndShowDetails(salary.id!),
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
    final isPaid = status.toLowerCase() == "paid";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPaid ? AppColors.success : AppColors.error).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isPaid ? AppColors.success : AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _fetchAndShowDetails(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final response = await ApiService.getSalaryDetails(id);
    Navigator.pop(context);

    if (response['error'] == false) {
      final Salary details = Salary.fromJson(response['data']);
      _showBreakdownDetails(details);
    } else {
      _showError(response['message'] ?? "Failed to load details");
    }
  }

  void _showBreakdownDetails(Salary salary) {
    final monthName = DateFormat(
      'MMMM',
    ).format(DateTime(2026, salary.month ?? 1));
    final double base = double.tryParse(salary.baseSalary ?? "0") ?? 0;
    final double net = double.tryParse(salary.netSalary ?? "0") ?? 0;
    final double totalDeduction = base - net;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
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
                  "$monthName Detailed Breakdown",
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
            _buildBreakdownItem("Base Salary", "₹$base"),
            _buildBreakdownItem("Payable Days", "${salary.payableDays}"),
            _buildBreakdownItem(
              "Total Absent",
              "${salary.totalAbsent}",
              isNegative: true,
            ),
            _buildBreakdownItem("Paid Leaves (PL)", "${salary.totalPl}"),

            const Divider(height: 32, color: AppColors.grey100),
            Text(
              "Deduction Reasons",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            if (salary.deductionReasons.isEmpty)
              Text(
                "No deductions applied",
                style: TextStyle(color: AppColors.grey400, fontSize: 13),
              )
            else
              ...salary.deductionReasons.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 32, color: AppColors.grey100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Deduction",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                    ),
                    Text(
                      "-₹$totalDeduction",
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Net Payout",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                    ),
                    Text(
                      "₹$net",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    String value, {
    bool isNegative = false,
  }) {
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
              color: isNegative ? AppColors.error : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
