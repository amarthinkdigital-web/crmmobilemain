import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

enum ShiftState { idle, working, onBreak }

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  ShiftState _shiftState = ShiftState.idle;
  DateTime? _clockInTime;
  DateTime? _breakStartTime;

  Duration _totalWorked = Duration.zero;
  Duration _totalBreak = Duration.zero;

  Timer? _ticker;
  String _liveTime = '';
  final List<_ActivityEntry> _activityLog = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _startLiveClock();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startLiveClock() {
    _updateLiveTime();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateLiveTime();
      _updateTimers();
    });
  }

  void _updateLiveTime() {
    setState(() {
      _liveTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    });
  }

  void _updateTimers() {
    if (_shiftState == ShiftState.working && _clockInTime != null) {
      setState(() {
        _totalWorked = DateTime.now().difference(_clockInTime!) - _totalBreak;
      });
    }
    if (_shiftState == ShiftState.onBreak && _breakStartTime != null) {
      setState(() {
        // break time keeps counting
      });
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Duration get _currentBreakSession {
    if (_shiftState == ShiftState.onBreak && _breakStartTime != null) {
      return DateTime.now().difference(_breakStartTime!);
    }
    return Duration.zero;
  }

  Duration get _displayWorked {
    if (_clockInTime == null) return Duration.zero;
    if (_shiftState == ShiftState.idle) return _totalWorked;
    final elapsed = DateTime.now().difference(_clockInTime!);
    return elapsed - _totalBreak - _currentBreakSession;
  }

  Duration get _displayBreak {
    return _totalBreak + _currentBreakSession;
  }

  // ─── Actions ───

  Future<void> _clockIn() async {
    try {
      await ApiService.clockIn();
    } catch (_) {}
    setState(() {
      _shiftState = ShiftState.working;
      _clockInTime = DateTime.now();
      _totalWorked = Duration.zero;
      _totalBreak = Duration.zero;
      _addActivity('Clock In', Icons.login_rounded, AppColors.success);
    });
  }

  Future<void> _clockOut() async {
    try {
      await ApiService.clockOut();
    } catch (_) {}
    setState(() {
      _totalWorked = _displayWorked;
      _shiftState = ShiftState.idle;
      _clockInTime = null;
      _breakStartTime = null;
      _addActivity('Clock Out', Icons.logout_rounded, AppColors.error);
    });
  }

  Future<void> _breakIn() async {
    try {
      await ApiService.breakIn();
    } catch (_) {}
    setState(() {
      _shiftState = ShiftState.onBreak;
      _breakStartTime = DateTime.now();
      _addActivity('Break Started', Icons.coffee_rounded, AppColors.warning);
    });
  }

  Future<void> _breakOut() async {
    try {
      await ApiService.breakOut();
    } catch (_) {}
    setState(() {
      _totalBreak += DateTime.now().difference(_breakStartTime!);
      _shiftState = ShiftState.working;
      _breakStartTime = null;
      _addActivity('Break Ended', Icons.play_arrow_rounded, AppColors.info);
    });
  }

  void _addActivity(String label, IconData icon, Color color) {
    _activityLog.insert(
      0,
      _ActivityEntry(
        label: label,
        time: DateFormat('hh:mm:ss a').format(DateTime.now()),
        icon: icon,
        color: color,
      ),
    );
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 20),
                  _buildStatusCards(),
                  const SizedBox(height: 28),
                  _buildTimerRing(),
                  const SizedBox(height: 28),
                  _buildActionButtons(),
                  const SizedBox(height: 28),
                  _buildActivityLog(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Bar ───
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 12,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: AppColors.navy, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'ThinkDigital',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'CRM',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
          const Spacer(),
          // Live clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _liveTime,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.gold,
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : 'U',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            color: AppColors.white.withValues(alpha: 0.6),
            onPressed: () async {
              try { await ApiService.logout(); } catch (_) {}
              widget.onLogout();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  // ─── Greeting ───
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greetingText, ${widget.userName.split(' ').first} 👋',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  // ─── Status Cards ───
  Widget _buildStatusCards() {
    String shiftLabel;
    Color shiftBadgeColor;
    String shiftBadgeText;

    switch (_shiftState) {
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
                value: _formatDuration(_displayWorked),
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
                value: _formatDuration(_displayBreak),
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Timer Ring ───
  Widget _buildTimerRing() {
    final isActive = _shiftState != ShiftState.idle;
    final isBreak = _shiftState == ShiftState.onBreak;

    Color ringColor;
    String statusText;

    if (isBreak) {
      ringColor = AppColors.warning;
      statusText = '☕ On Break';
    } else if (isActive) {
      ringColor = AppColors.success;
      statusText = '● Working';
    } else {
      ringColor = AppColors.grey200;
      statusText = 'Ready to start';
    }

    final displayTime = isBreak
        ? _formatDuration(_displayBreak)
        : _formatDuration(_displayWorked);

    return Center(
      child: ScaleTransition(
        scale: isActive ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: ringColor.withValues(alpha: isActive ? 0.2 : 0.05),
                blurRadius: isActive ? 40 : 20,
                spreadRadius: isActive ? 4 : 0,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _RingPainter(
              progress: isActive ? _getProgress() : 0,
              color: ringColor,
              bgColor: AppColors.grey100,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isBreak ? 'Break Timer' : 'Shift Timer',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayTime,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ringColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getProgress() {
    // Progress cycles every 60 seconds for visual appeal
    final seconds = _shiftState == ShiftState.onBreak
        ? _displayBreak.inSeconds
        : _displayWorked.inSeconds;
    return (seconds % 60) / 60.0;
  }

  // ─── Action Buttons ───
  Widget _buildActionButtons() {
    final isIdle = _shiftState == ShiftState.idle;
    final isWorking = _shiftState == ShiftState.working;
    final isOnBreak = _shiftState == ShiftState.onBreak;

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
                onPressed: _clockIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Clock Out',
                icon: Icons.logout_rounded,
                color: AppColors.error,
                enabled: isWorking,
                onPressed: _clockOut,
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
                onPressed: _breakIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Break Out',
                icon: Icons.play_arrow_rounded,
                color: AppColors.info,
                enabled: isOnBreak,
                onPressed: _breakOut,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Activity Log ───
  Widget _buildActivityLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Activity",
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            Text(
              '${_activityLog.length} entries',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.grey400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_activityLog.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Column(
              children: [
                Icon(Icons.event_note_rounded,
                    size: 44, color: AppColors.grey200),
                const SizedBox(height: 12),
                Text(
                  'No activity recorded today',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grey100),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activityLog.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.grey100),
              itemBuilder: (_, i) {
                final entry = _activityLog[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(entry.icon, size: 20, color: entry.color),
                  ),
                  title: Text(
                    entry.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  trailing: Text(
                    entry.time,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── Supporting Widgets ───

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
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: compact ? 20 : 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.grey400).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor ?? AppColors.grey400,
                ),
              ),
            ),
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
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: enabled ? color.withValues(alpha: 0.08) : AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: enabled ? color : AppColors.grey400,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: enabled ? color : AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityEntry {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  _ActivityEntry({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });
}

// ─── Ring Painter ───

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 6.0;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = bgColor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
