import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  State<ManagerAttendanceScreen> createState() =>
      _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends State<ManagerAttendanceScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  late String _selectedMonth;
  late String _selectedYear;
  String _selectedStatus = 'All Status';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('MMMM').format(DateTime.now());
    _selectedYear = DateTime.now().year.toString();
    _fetchLogs();
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _logs.where((log) {
      try {
        final dateRaw = log['date']?.toString() ?? '';
        final date = DateTime.parse(dateRaw).toLocal();

        // Date picker filter
        if (_selectedDate != null) {
          if (date.year != _selectedDate!.year ||
              date.month != _selectedDate!.month ||
              date.day != _selectedDate!.day) {
            return false;
          }
        }

        // Month filter
        if (_selectedMonth != 'All' && _selectedMonth != 'All Status') {
          final logMonth = DateFormat('MMMM').format(date);
          if (logMonth != _selectedMonth) return false;
        }

        // Year filter
        if (_selectedYear != 'All' && _selectedYear != 'All Status') {
          if (date.year.toString() != _selectedYear) return false;
        }

        // Status filter
        if (_selectedStatus != 'All Status') {
          final status = (log['attendance_status']?.toString() ?? '').toLowerCase();
          final isActive = log['clock_out'] == null;
          final isLate = log['is_late'] == 1 || log['is_late'] == true;
          String computedStatus = status;
          if (computedStatus.isEmpty) {
            if (isLate) { computedStatus = 'late'; }
            else if (isActive) { computedStatus = 'working'; }
            else { computedStatus = 'present'; }
          }
          final filterStatus = _selectedStatus.toLowerCase();
          if (filterStatus == 'half day' && !computedStatus.contains('half')) { return false; }
          else if (filterStatus != 'half day' && !computedStatus.contains(filterStatus)) { return false; }
        }

        return true;
      } catch (_) {
        return true;
      }
    }).toList();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    
    int month = 1;
    try {
      final date = DateFormat('MMMM').parse(_selectedMonth);
      month = date.month;
    } catch (_) {
      month = DateTime.now().month;
    }
    
    int year = DateTime.now().year;
    try {
      year = int.parse(_selectedYear);
    } catch (_) {}

    final res = await ApiService.getMyAttendance(month: month, year: year);
    if (mounted) {
      if (res['error'] == false) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(res['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to load logs')),
        );
      }
    }
  }

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _years = ['2024', '2025', '2026', '2027'];
  final List<String> _statuses = [
    'All Status',
    'Present',
    'Absent',
    'Late',
    'Half Day',
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
            _buildTimingStats(),
            const SizedBox(height: 24),
            _buildFilterSection(),
            const SizedBox(height: 24),
            Text(
              "Attendance List",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            _buildLogsList(),
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
          "My Attendance Logs",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Track and review your personal attendance history",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimingStats() {
    return Row(
      children: [
        Expanded(
          child: _timingCard(
            "Shift Timing",
            "09:00 AM - 06:00 PM",
            Icons.access_time_filled_rounded,
            AppColors.navy,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _timingCard(
            "Break Timing",
            "1h 00m Total",
            Icons.coffee_rounded,
            AppColors.goldDark,
          ),
        ),
      ],
    );
  }

  Widget _timingCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
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
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                size: 20,
                color: AppColors.navy,
              ),
              const SizedBox(width: 8),
              Text(
                "Filter Options",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDatePicker(),
              _buildDropdown(
                _selectedMonth,
                _months,
                (v) {
                  setState(() => _selectedMonth = v!);
                  _fetchLogs();
                },
              ),
              _buildDropdown(
                _selectedYear,
                _years,
                (v) {
                  setState(() => _selectedYear = v!);
                  _fetchLogs();
                },
              ),
              _buildDropdown(
                _selectedStatus,
                _statuses,
                (v) => setState(() => _selectedStatus = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateFormat('MMMM').format(DateTime.now());
                    _selectedYear = DateTime.now().year.toString();
                    _selectedStatus = 'All Status';
                    _selectedDate = null;
                  });
                  _fetchLogs();
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: AppColors.grey200),
                ),
                child: const Text("Reset"),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _fetchLogs(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text("Apply Filters"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.grey600,
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: AppColors.navy,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedDate == null
                  ? "Select Date"
                  : DateFormat('MMM dd, yyyy').format(_selectedDate!),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    if (_isLoading) return const Center(child: Padding(
      padding: EdgeInsets.all(40.0),
      child: CircularProgressIndicator(color: AppColors.navy),
    ));

    final filtered = _filteredLogs;

    if (filtered.isEmpty) return Center(child: Padding(
      padding: const EdgeInsets.all(40.0),
      child: Text("No records found", style: GoogleFonts.inter(color: AppColors.grey400)),
    ));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final log = filtered[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final bool isActive = log['clock_out'] == null;
    final status = log['attendance_status']?.toString().replaceAll('_', ' ').toUpperCase() ?? (isActive ? 'WORKING' : 'PRESENT');
    final clockIn = log['clock_in'] != null ? DateFormat('hh:mm A').format(DateTime.parse(log['clock_in']).toLocal()) : '—';
    final clockOut = !isActive ? DateFormat('hh:mm A').format(DateTime.parse(log['clock_out']).toLocal()) : 'IN PROGRESS';
    final int workMinutes = int.tryParse(log['total_work_minutes']?.toString() ?? '0') ?? 0;
    final int breakMinutes = int.tryParse(log['total_break_minutes']?.toString() ?? '0') ?? 0;

    Color statusColor = AppColors.grey400;
    if (status.contains('PRESENT') || status.contains('WORKING')) statusColor = AppColors.success;
    if (status.contains('LATE')) statusColor = AppColors.warning;
    if (status.contains('HALF')) statusColor = AppColors.goldDark;
    if (status.contains('ABSENT')) statusColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 20,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatRawDate(log['date']?.toString() ?? ''),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn("Clock In", clockIn),
              _buildTimeColumn("Clock Out", clockOut),
              _buildTimeColumn("Break", "${breakMinutes}m"),
              _buildTimeColumn("Total", !isActive ? "${(workMinutes/60).floor()}h ${workMinutes%60}m" : "ACTIVE", isHighlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.grey400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.navy : AppColors.grey600,
          ),
        ),
      ],
    );
  }

  String _formatRawDate(String raw) {
    if (raw.isEmpty) return "—";
    try {
      final date = DateTime.parse(raw).toLocal();
      return DateFormat('EEEE, MMM dd').format(date);
    } catch (e) {
      return raw;
    }
  }
}
