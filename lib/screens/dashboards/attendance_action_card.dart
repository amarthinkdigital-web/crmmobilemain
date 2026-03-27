import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AttendanceActionCard extends StatefulWidget {
  const AttendanceActionCard({super.key});

  @override
  State<AttendanceActionCard> createState() => _AttendanceActionCardState();
}

class _AttendanceActionCardState extends State<AttendanceActionCard> {
  bool _isLoading = true;
  Map<String, dynamic>? _todayRecord;
  String _status = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getTodayAttendance();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['error'] == false) {
          _todayRecord = res['data'];
          _updateStatusText();
        } else {
          _status = "Error loading status";
        }
      });
    }
  }

  void _updateStatusText() {
    if (_todayRecord == null) {
      _status = "Not Clocked In";
      return;
    }

    if (_todayRecord!['clock_out'] != null) {
      _status = "Shift Ended";
      return;
    }

    // Check for active break
    bool onBreak = _todayRecord!['on_break'] == true || 
                   _todayRecord!['on_break'] == 1 ||
                   (_todayRecord!['break_in'] != null && _todayRecord!['break_out'] == null) ||
                   (_todayRecord!['break_in_1'] != null && _todayRecord!['break_out_1'] == null);

    if (onBreak) {
      _status = "On Break";
    } else {
      _status = "Clocked In";
    }
  }

  Future<void> _handleAction(Future<Map<String, dynamic>> Function() action) async {
    setState(() => _isLoading = true);
    final res = await action();
    if (mounted) {
      if (res['error'] == false || res['success'] == true) {
        await _fetchStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Action successful')),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Action failed'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _todayRecord == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.grey100),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );
    }

    final bool isClockedIn = _todayRecord != null && _todayRecord!['clock_out'] == null;
    final bool isClockedOut = _todayRecord != null && _todayRecord!['clock_out'] != null;
    
    bool isOnBreak = false;
    if (isClockedIn) {
      isOnBreak = _todayRecord!['on_break'] == true || 
                  _todayRecord!['on_break'] == 1 ||
                  (_todayRecord!['break_in'] != null && _todayRecord!['break_out'] == null) ||
                  (_todayRecord!['break_in_1'] != null && _todayRecord!['break_out_1'] == null);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _status,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      if (_todayRecord != null && _todayRecord!['clock_in'] != null)
                        Text(
                          "Clocked in at ${_formatTime(_todayRecord!['clock_in'])}",
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (!isClockedIn && !isClockedOut)
                  _buildActionButton(
                    "Clock In",
                    Icons.login_rounded,
                    AppColors.success,
                    () => _handleAction(ApiService.clockIn),
                  ),
                if (isClockedIn && !isOnBreak)
                  _buildActionButton(
                    "Clock Out",
                    Icons.logout_rounded,
                    AppColors.error,
                    () => _handleAction(ApiService.clockOut),
                  ),
                if (isClockedOut)
                  Text(
                    "You have completed your shift for today.",
                    style: GoogleFonts.inter(color: AppColors.grey400, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                if (isClockedIn) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          isOnBreak ? "End Break" : "Start Break",
                          isOnBreak ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          isOnBreak ? AppColors.info : AppColors.gold,
                          () => _handleAction(isOnBreak ? ApiService.breakOut : ApiService.breakIn),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case "Clocked In": return AppColors.success;
      case "On Break": return AppColors.gold;
      case "Shift Ended": return AppColors.info;
      case "Not Clocked In": return AppColors.grey400;
      default: return AppColors.navy;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case "Clocked In": return Icons.timer_rounded;
      case "On Break": return Icons.coffee_rounded;
      case "Shift Ended": return Icons.check_circle_rounded;
      case "Not Clocked In": return Icons.more_time_rounded;
      default: return Icons.info_outline;
    }
  }
  String _formatTime(String timeStr) {
    try {
      // Handle cases like "09:00:00" or ISO "2024-03-25T09:00:00.000000Z"
      if (timeStr.contains('T')) {
        return DateFormat('hh:mm A').format(DateTime.parse(timeStr).toLocal());
      }
      // If it's just "09:00:00"
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final dt = DateTime(2024, 1, 1, hour, min);
        return DateFormat('hh:mm A').format(dt);
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }
}
