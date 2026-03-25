import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  State<ManagerAttendanceScreen> createState() =>
      _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends State<ManagerAttendanceScreen> {
  final List<Map<String, String>> _logs = [
    {
      'date': '2026-03-09',
      'in': '09:02 AM',
      'out': '06:15 PM',
      'hours': '8h 43m',
      'break': '00h 30m',
      'status': 'Present',
    },
    {
      'date': '2026-03-07',
      'in': '09:10 AM',
      'out': '06:00 PM',
      'hours': '8h 20m',
      'break': '00h 30m',
      'status': 'Late',
    },
    {
      'date': '2026-03-06',
      'in': '09:45 AM',
      'out': '04:30 PM',
      'hours': '6h 15m',
      'break': '00h 30m',
      'status': 'Half Day',
    },
    {
      'date': '2026-03-05',
      'in': '08:55 AM',
      'out': '06:30 PM',
      'hours': '9h 05m',
      'break': '00h 30m',
      'status': 'Present',
    },
    {
      'date': '2026-03-04',
      'in': '-',
      'out': '-',
      'hours': '-',
      'break': '-',
      'status': 'Absent',
    },
  ];

  String _selectedMonth = 'March';
  String _selectedYear = '2026';
  String _selectedStatus = 'All Status';
  DateTime? _selectedDate;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
  ];
  final List<String> _years = ['2025', '2026', '2027'];
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
                (v) => setState(() => _selectedMonth = v!),
              ),
              _buildDropdown(
                _selectedYear,
                _years,
                (v) => setState(() => _selectedYear = v!),
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
                    _selectedMonth = 'March';
                    _selectedYear = '2026';
                    _selectedStatus = 'All Status';
                    _selectedDate = null;
                  });
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
                onPressed: () {},
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(Map<String, String> log) {
    Color statusColor = AppColors.grey400;
    if (log['status'] == 'Present') statusColor = AppColors.success;
    if (log['status'] == 'Late') statusColor = AppColors.warning;
    if (log['status'] == 'Half Day') statusColor = AppColors.goldDark;
    if (log['status'] == 'Absent') statusColor = AppColors.error;

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
                      DateFormat(
                        'EEEE, MMM dd',
                      ).format(DateTime.parse(log['date']!)),
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
                  log['status']!,
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
              _buildTimeColumn("Clock In", log['in']!),
              _buildTimeColumn("Clock Out", log['out']!),
              _buildTimeColumn("Break", log['break']!),
              _buildTimeColumn("Total", log['hours']!, isHighlight: true),
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
}
