import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({super.key});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedStatus;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _years = ['2024', '2025', '2026', '2027'];
  final List<String> _statuses = ['All', 'Present', 'Absent', 'Late', 'Half Day', 'On Leave'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('MMMM').format(DateTime.now());
    _selectedYear = DateTime.now().year.toString();
    _selectedStatus = 'All';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildShiftInfoCard(),
            const SizedBox(height: 24),
            Text(
              "Filter Attributes",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 24),
            _buildLogList(),
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
          'My Attendance Logs',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'View and filter your daily clock-in records',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildShiftInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimingItem(
            Icons.access_time_rounded,
            "Shift Timing",
            "9:00 AM - 6:00 PM",
            AppColors.navy,
          ),
          Container(height: 40, width: 1, color: AppColors.grey200),
          _buildTimingItem(
            Icons.coffee_rounded,
            "Break Timing",
            "60 Min Max",
            AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildTimingItem(IconData icon, String title, String value, Color iconColor) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDropdown(_months, _selectedMonth, (v) => setState(() => _selectedMonth = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown(_years, _selectedYear, (v) => setState(() => _selectedYear = v))),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdown(_statuses, _selectedStatus, (v) => setState(() => _selectedStatus = v)),
      ],
    );
  }

  Widget _buildDropdown(List<String> items, String? currentValue, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey400),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLogList() {
    return Column(
      children: List.generate(5, (index) {
        final isLate = index % 3 == 0;
        final date = DateTime.now().subtract(Duration(days: index));
        return _buildDetailedAttendanceCard(date, isLate);
      }),
    );
  }

  Widget _buildDetailedAttendanceCard(DateTime date, bool isLate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMM d, yyyy').format(date),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLate ? AppColors.warning.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLate ? 'Late' : 'Present',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isLate ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Details row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3, 
                  child: _buildDetailColumn("Session Timing", isLate ? "09:15 AM - 06:00 PM" : "09:00 AM - 06:00 PM")
                ),
                Expanded(
                  flex: 2, 
                  child: _buildDetailColumn("Break Total", "45 Min", alignCenter: true)
                ),
                Expanded(
                  flex: 2, 
                  child: _buildDetailColumn("Work Hours", isLate ? "7h 45m" : "8h 00m", isHighlight: true, alignRight: true)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, {bool isHighlight = false, bool alignRight = false, bool alignCenter = false}) {
    CrossAxisAlignment alignment = CrossAxisAlignment.start;
    if (alignRight) alignment = CrossAxisAlignment.end;
    if (alignCenter) alignment = CrossAxisAlignment.center;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.grey600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.navy : AppColors.navy.withValues(alpha: 0.8),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
