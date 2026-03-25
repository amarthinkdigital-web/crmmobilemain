import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import 'shift_state.dart';


import '../../../services/api_service.dart';

class CorrectionsScreen extends StatefulWidget {
  final ShiftState shiftState;
  final String liveTime;
  final String formattedWorked;
  final String formattedBreak;
  final String timerStatusText;
  final double timerProgress;
  final Animation<double> pulseAnim;
  final List<dynamic> activityLog;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final VoidCallback onBreakIn;
  final VoidCallback onBreakOut;

  const CorrectionsScreen({
    super.key,
    required this.shiftState,
    required this.liveTime,
    required this.formattedWorked,
    required this.formattedBreak,
    required this.timerStatusText,
    required this.timerProgress,
    required this.pulseAnim,
    required this.activityLog,
    required this.onClockIn,
    required this.onClockOut,
    required this.onBreakIn,
    required this.onBreakOut,
  });

  @override
  State<CorrectionsScreen> createState() => _CorrectionsScreenState();
}

class _CorrectionsScreenState extends State<CorrectionsScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _clockIn = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _clockOut = const TimeOfDay(hour: 18, minute: 0);
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitCorrection() async {
    if (_reasonController.text.isEmpty) {
      _showToast("Please provide a reason", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    
    final res = await ApiService.submitCorrection(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      clockIn: _formatTime(_clockIn),
      clockOut: _formatTime(_clockOut),
      reason: _reasonController.text,
    );

    setState(() => _isSubmitting = false);

    if (res['error'] == false) {
      _showToast("Correction request submitted!");
      _reasonController.clear();
    } else {
      _showToast(res['message'], isError: true);
    }
  }

  String _formatTime(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('HH:mm:ss').format(dt);
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatusCards(),
          const SizedBox(height: 28),
          _buildTimerRing(),
          const SizedBox(height: 28),
          _buildActionButtons(),
          const SizedBox(height: 32),
          _buildCorrectionForm(),
          const SizedBox(height: 32),
          _buildActivityLog(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Corrections & Attendance',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          'Manage your shift and timer here',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectionForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(color: AppColors.navy.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_calendar_rounded, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Manual Correction', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 20),
          _buildFormRow('Date', DateFormat('MMM dd, yyyy').format(_selectedDate), Icons.calendar_today_rounded, () async {
            final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2025), lastDate: DateTime.now());
            if (d != null) setState(() => _selectedDate = d);
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormRow('In', _clockIn.format(context), Icons.login_rounded, () async {
                  final t = await showTimePicker(context: context, initialTime: _clockIn);
                  if (t != null) setState(() => _clockIn = t);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormRow('Out', _clockOut.format(context), Icons.logout_rounded, () async {
                  final t = await showTimePicker(context: context, initialTime: _clockOut);
                  if (t != null) setState(() => _clockOut = t);
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Reason', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey400)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Forgot to clock in...',
              filled: true,
              fillColor: AppColors.offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitCorrection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Submit Request', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(String label, String value, IconData icon, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey400)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppColors.grey400),
                const SizedBox(width: 10),
                Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
                const Spacer(),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.grey400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCards() {
    String shiftLabel;
    Color shiftBadgeColor;
    String shiftBadgeText;

    switch (widget.shiftState) {
      case ShiftState.working:
        shiftLabel = 'Working';
        shiftBadgeColor = AppColors.success;
        shiftBadgeText = 'Active';
        break;
      case ShiftState.onBreak:
        shiftLabel = 'On Break';
        shiftBadgeColor = AppColors.warning;
        shiftBadgeText = 'Break';
        break;
      case ShiftState.idle:
        shiftLabel = 'Not Clocked In';
        shiftBadgeColor = AppColors.grey400;
        shiftBadgeText = 'Inactive';
        break;
    }

    return Column(
      children: [
        _StatusCard(
          icon: Icons.access_time_rounded,
          iconBgColor: AppColors.navy.withValues(alpha: 0.08),
          iconColor: AppColors.navy,
          label: 'Shift Status',
          value: shiftLabel,
          badge: shiftBadgeText,
          badgeColor: shiftBadgeColor,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusCard(
                icon: Icons.bar_chart_rounded,
                iconBgColor: AppColors.gold.withValues(alpha: 0.12),
                iconColor: AppColors.gold,
                label: 'Hours Today',
                value: widget.formattedWorked,
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusCard(
                icon: Icons.coffee_rounded,
                iconBgColor: AppColors.warning.withValues(alpha: 0.12),
                iconColor: AppColors.warning,
                label: 'Break Time',
                value: widget.formattedBreak,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerRing() {
    final isActive = widget.shiftState != ShiftState.idle;
    final isBreak = widget.shiftState == ShiftState.onBreak;
    Color ringColor = isBreak
        ? AppColors.warning
        : (isActive ? AppColors.success : AppColors.grey200);

    return Center(
      child: ScaleTransition(
        scale: isActive ? widget.pulseAnim : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: ringColor.withValues(alpha: isActive ? 0.2 : 0.05),
                blurRadius: isActive ? 40 : 20,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _RingPainter(
              progress: widget.timerProgress,
              color: ringColor,
              bgColor: AppColors.grey100,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isBreak ? 'Break' : 'Shift',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400),
                  ),
                  Text(
                    isBreak ? widget.formattedBreak : widget.formattedWorked,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    widget.timerStatusText,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: ringColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isIdle = widget.shiftState == ShiftState.idle;
    final isWorking = widget.shiftState == ShiftState.working;
    final isOnBreak = widget.shiftState == ShiftState.onBreak;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Clock In',
                icon: Icons.login_rounded,
                color: AppColors.success,
                enabled: isIdle,
                onPressed: widget.onClockIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Clock Out',
                icon: Icons.logout_rounded,
                color: AppColors.error,
                enabled: isWorking,
                onPressed: widget.onClockOut,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Break In',
                icon: Icons.coffee_rounded,
                color: AppColors.warning,
                enabled: isWorking,
                onPressed: widget.onBreakIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Break Out',
                icon: Icons.play_arrow_rounded,
                color: AppColors.info,
                enabled: isOnBreak,
                onPressed: widget.onBreakOut,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Shift Activity",
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        const SizedBox(height: 14),
        if (widget.activityLog.isEmpty)
          const Text('No activity today', style: TextStyle(color: Colors.grey))
        else
          ...widget.activityLog.map((entry) => ListTile(
                leading: Icon(entry.icon, color: entry.color),
                title: Text(entry.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(entry.time),
              )),
      ],
    );
  }
}

// Supporting UI Classes (Simplified Copies)

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String value;
  final String? badge;
  final Color? badgeColor;
  final bool compact;

  const _StatusCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    this.badge,
    this.badgeColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: compact ? 18 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          if (badge != null)
             Text(badge!, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.1) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: enabled ? color : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: enabled ? color : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _RingPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 6.0;

    canvas.drawCircle(center, radius, paint..color = bgColor);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, 6.2831 * progress, false,
      paint..color = color..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
