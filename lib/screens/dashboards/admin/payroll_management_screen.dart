import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/salary_model.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_theme.dart';

class PayrollManagementScreen extends StatefulWidget {
  const PayrollManagementScreen({super.key});

  @override
  State<PayrollManagementScreen> createState() =>
      _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen> {
  String selectedMonth = DateTime.now().month.toString();
  String selectedYear = DateTime.now().year.toString();
  bool _isManagerMode = false;

  final List<Map<String, String>> months = [
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
  final List<String> years = ["2023", "2024", "2025", "2026"];

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

    final response = _isManagerMode
        ? await ApiService.getAdminManagerSalaries(
            month: int.tryParse(selectedMonth),
            year: int.tryParse(selectedYear),
          )
        : await ApiService.getAdminSalaries(
            month: int.tryParse(selectedMonth),
            year: int.tryParse(selectedYear),
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
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response['message'];
        _isLoading = false;
      });
    }
  }

  Future<void> _generateSalaries() async {
    _showLoadingDialog("Generating salaries...");
    final response = _isManagerMode
        ? await ApiService.generateAdminManagerSalaries(
            int.parse(selectedMonth),
            int.parse(selectedYear),
          )
        : await ApiService.generateAdminSalaries(
            int.parse(selectedMonth),
            int.parse(selectedYear),
          );
    Navigator.pop(context);

    if (response['error'] == false) {
      _showSuccess(response['message'] ?? "Salaries generated successfully");
      _fetchSalaries();
    } else {
      _showError(response['message'] ?? "Failed to generate salaries");
    }
  }

  Future<void> _syncRecord(Salary salary) async {
    _showLoadingDialog("Syncing record...");
    final response = await ApiService.syncSalaryRecord(salary.id!);
    Navigator.pop(context);

    if (response['error'] == false) {
      _showSuccess("Record synced successfully");
      _fetchSalaries();
    } else {
      _showError(response['message'] ?? "Failed to sync record");
    }
  }

  Future<void> _updateStatus(Salary salary, String status) async {
    _showLoadingDialog("Updating status...");
    final response = await ApiService.updateSalaryPaymentStatus(
      salary.id!,
      status,
    );
    Navigator.pop(context);

    if (response['error'] == false) {
      _showSuccess("Status updated to $status");
      _fetchSalaries();
    } else {
      _showError(response['message'] ?? "Failed to update status");
    }
  }

  Future<void> _markAllPaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark All as Paid?"),
        content: Text(
          "Are you sure you want to mark all unpaid salaries for ${months.firstWhere((m) => m['id'] == selectedMonth)['name']} $selectedYear as Paid?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Mark Paid",
              style: TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showLoadingDialog("Processing bulk payment...");
      final response = _isManagerMode
          ? await ApiService.markManagerMonthAsFullyPaid(
              int.parse(selectedMonth),
              int.parse(selectedYear),
            )
          : await ApiService.markMonthAsFullyPaid(
              int.parse(selectedMonth),
              int.parse(selectedYear),
            );
      Navigator.pop(context);

      if (response['error'] == false) {
        _showSuccess("All salaries marked as paid");
        _fetchSalaries();
      } else {
        _showError(response['message'] ?? "Failed to mark all paid");
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilterSection(),
              const SizedBox(height: 24),
              _buildStatCards(),
              const SizedBox(height: 32),
              _buildPayrollHeaderRow(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      ElevatedButton(
                        onPressed: _fetchSalaries,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              else
                _buildPayrollTable(),
              const SizedBox(height: 100),
            ],
          ),
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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  "Employees",
                  !_isManagerMode,
                  () => setState(() {
                    _isManagerMode = false;
                    _fetchSalaries();
                  }),
                ),
              ),
              Expanded(
                child: _buildToggleButton(
                  "Managers",
                  _isManagerMode,
                  () => setState(() {
                    _isManagerMode = true;
                    _fetchSalaries();
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSmallDropdown(
                selectedMonth,
                months.map((m) => m['id']!).toList(),
                (v) {
                  setState(() => selectedMonth = v!);
                  _fetchSalaries();
                },
                labels: months.map((m) => m['name']!).toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallDropdown(selectedYear, years, (v) {
                setState(() => selectedYear = v!);
                _fetchSalaries();
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {}, // Future: Export
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text("Export"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: AppColors.grey200),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generateSalaries,
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

  Widget _buildPayrollHeaderRow() {
    final monthName = months.firstWhere(
      (m) => m['id'] == selectedMonth,
    )['name'];
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
              "$monthName $selectedYear",
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
          onPressed: _markAllPaid,
          icon: const Icon(Icons.done_all_rounded, size: 16),
          label: const Text("Mark All Paid"),
          style: TextButton.styleFrom(foregroundColor: AppColors.success),
        ),
      ],
    );
  }

  Widget _buildPayrollTable() {
    if (_salaries.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "No salary records for this month. Click 'Generate' to create them.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
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
              AppColors.navy.withOpacity(0.05),
            ),
            columnSpacing: 40,
            columns: [
              _buildDataColumn("Employee"),
              _buildDataColumn("Base Salary"),
              _buildDataColumn("Payable Days"),
              _buildDataColumn("PL"),
              _buildDataColumn("Absent"),
              _buildDataColumn("Net Salary"),
              _buildDataColumn("Status"),
              _buildDataColumn("Actions"),
            ],
            rows: _salaries.map((s) => _buildRow(s)).toList(),
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

  DataRow _buildRow(Salary salary) {
    final bool isPaid = salary.status?.toLowerCase() == "paid";

    return DataRow(
      cells: [
        DataCell(
          Text(
            salary.user?.name ?? "Unknown",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            "₹${salary.baseSalary ?? "0"}",
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            "${salary.payableDays}",
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            "${salary.totalPl}",
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            "${salary.totalAbsent}",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Text(
            "₹${salary.netSalary ?? "0"}",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => _updateStatus(salary, isPaid ? "Unpaid" : "Paid"),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isPaid ? AppColors.success : AppColors.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                salary.status ?? "Unpaid",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isPaid ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildActionIcon(
                Icons.sync_rounded,
                AppColors.info,
                "Sync/Recalculate",
                () => _syncRecord(salary),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.receipt_long_rounded,
                AppColors.navy,
                "Deduction Details",
                () => _showBreakdownDetails(salary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _showBreakdownDetails(Salary salary) {
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
            Text(
              "Deduction Reasons",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            if (salary.deductionReasons.isEmpty)
              const Text("No specific deduction reasons found.")
            else
              ...salary.deductionReasons.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(r, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    double totalBase = 0;
    double totalNet = 0;
    int paidCount = 0;

    for (var s in _salaries) {
      totalBase += double.tryParse(s.baseSalary ?? "0") ?? 0;
      totalNet += double.tryParse(s.netSalary ?? "0") ?? 0;
      if (s.status?.toLowerCase() == "paid") paidCount++;
    }

    double deductions = totalBase - totalNet;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildStatTile(
          "Total Base",
          "₹${totalBase.toStringAsFixed(0)}",
          Icons.account_balance_wallet_rounded,
          AppColors.navy,
        ),
        _buildStatTile(
          "Est. Net Payout",
          "₹${totalNet.toStringAsFixed(0)}",
          Icons.payments_rounded,
          AppColors.success,
        ),
        _buildStatTile(
          "Deductions",
          "₹${deductions.toStringAsFixed(0)}",
          Icons.money_off_rounded,
          AppColors.error,
        ),
        _buildStatTile(
          "Payout Status",
          "$paidCount / ${_salaries.length} Paid",
          Icons.check_circle_rounded,
          AppColors.gold,
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
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
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    count,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.grey600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.navy : AppColors.grey600,
            ),
          ),
        ),
      ),
    );
  }
}
