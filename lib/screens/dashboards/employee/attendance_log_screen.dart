import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
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

  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

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
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getMyAttendance();
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
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.navy));
    if (_logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text("No attendance records found.", style: GoogleFonts.inter(color: AppColors.grey400)),
        ),
      );
    }

    return Column(
      children: _logs.map((log) {
        final dateRaw = log['date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
        final date = DateTime.parse(dateRaw).toLocal();
        
        final isLate = log['is_late'] == 1 || log['is_late'] == true;
        return _buildDetailedAttendanceCard(date, isLate, log);
      }).toList(),
    );
  }

  Widget _buildDetailedAttendanceCard(DateTime date, bool isLate, Map<String, dynamic> log) {
    final String clockIn = log['clock_in'] != null ? DateFormat('hh:mm A').format(DateTime.parse(log['clock_in']!).toLocal()) : "--:--";
    final bool isActive = log['clock_out'] == null;
    final String clockOut = !isActive ? DateFormat('hh:mm A').format(DateTime.parse(log['clock_out']!).toLocal()) : "IN PROGRESS";
    
    final int workMinutes = int.tryParse(log['total_work_minutes']?.toString() ?? '0') ?? 0;
    final int breakMinutes = int.tryParse(log['total_break_minutes']?.toString() ?? '0') ?? 0;
    final String status = log['attendance_status']?.toString().replaceAll('_', ' ').toUpperCase() ?? (isLate ? 'LATE' : (isActive ? 'WORKING' : 'PRESENT'));

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
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3, 
                  child: _buildDetailColumn("Session Timing", "$clockIn - $clockOut")
                ),
                Expanded(
                  flex: 2, 
                  child: _buildDetailColumn("Break", "${breakMinutes}m", alignCenter: true)
                ),
                Expanded(
                  flex: 2, 
                  child: _buildDetailColumn(
                    "Work Hours", 
                    isActive ? "IN PROGRESS" : "${(workMinutes/60).floor()}h ${workMinutes%60}m", 
                    isHighlight: true, 
                    alignRight: true
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('late')) return AppColors.warning;
    if (status.contains('absent')) return AppColors.error;
    if (status.contains('present')) return AppColors.success;
    if (status.contains('leave') || status.contains('off')) return Colors.purple;
    return AppColors.info;
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
