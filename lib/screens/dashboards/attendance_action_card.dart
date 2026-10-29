import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AttendanceActionCard extends StatefulWidget {
  const AttendanceActionCard({super.key});

  @override
  State<AttendanceActionCard> createState() => _AttendanceActionCardState();
}

class _AttendanceActionCardState extends State<AttendanceActionCard>
    with WidgetsBindingObserver {
  static const String officeWiFiName = "Airtel_Think Digital";

  bool _isLoading = true;
  Map<String, dynamic>? _todayRecord;
  String _status = "Loading...";
  Timer? _refreshTimer;
  Timer? _liveTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchStatus();
    // Auto-refresh every 30 seconds so that if clock-in happens on web,
    // the mobile app picks it up automatically without manual restart.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _fetchStatus();
    });
    // Live elapsed timer — ticks every second
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _tickTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground, immediately re-fetch status
    if (state == AppLifecycleState.resumed) {
      _fetchStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _liveTimer?.cancel();
    super.dispose();
  }

  void _tickTimer() {
    final record = _todayRecord;
    if (record == null ||
        record['clock_in'] == null ||
        record['clock_out'] != null) {
      if (_elapsed != Duration.zero) setState(() => _elapsed = Duration.zero);
      return;
    }
    final clockIn =
        DateTime.tryParse(record['clock_in'].toString())?.toLocal();
    if (clockIn == null) return;
    setState(() => _elapsed = DateTime.now().difference(clockIn));
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
          _tickTimer();
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
    bool onBreak =
        _todayRecord!['on_break'] == true ||
        _todayRecord!['on_break'] == 1 ||
        (_todayRecord!['break_in'] != null &&
            _todayRecord!['break_out'] == null) ||
        (_todayRecord!['break_in_1'] != null &&
            _todayRecord!['break_out_1'] == null) ||
        (_todayRecord!['break_in_2'] != null &&
            _todayRecord!['break_out_2'] == null);

    if (onBreak) {
      _status = "On Break";
    } else {
      _status = "Clocked In";
    }
  }

  Future<void> _handleAction(
    Future<Map<String, dynamic>> Function() action, {
    bool isClockIn = false,
  }) async {
    setState(() => _isLoading = true);

    if (isClockIn) {
      bool allowed = await _checkWiFiConnection();
      if (!allowed) {
        setState(() => _isLoading = false);
        return;
      }
    }

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
          SnackBar(
            content: Text(res['message'] ?? 'Action failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _checkWiFiConnection() async {
    if (kIsWeb) return true; // Bypass on Web

    // Bypass on Desktop (Windows/Mac/Linux) since permission_handler might fail
    try {
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        return true;
      }
    } catch (_) {}

    try {
      // 1. Request location permission (required on Android to get SSID)
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isPermanentlyDenied) {
        _showErrorSnackBar(
          "Location permission is needed to verify WiFi. Please enable it in settings.",
        );
        return false;
      }

      // 2. Get WiFi name and IP
      final info = NetworkInfo();
      String? wifiName = await info.getWifiName();
      String? wifiIP = await info.getWifiIP();

      // Clean the name (Android often wraps in quotes)
      String cleanWifi = wifiName?.replaceAll('"', '') ?? '';

      print(
        "DEBUG: Retreived SSID: $cleanWifi, IP: $wifiIP",
      ); // Helpful for debugging

      // ✅ Check if connected to office WiFi (by SSID name)
      bool isOfficeWifi =
          cleanWifi.toLowerCase() == officeWiFiName.toLowerCase() ||
          cleanWifi == officeWiFiName ||
          cleanWifi == "Office_WiFi" ||
          cleanWifi.contains("Think Digital");

      // ✅ Also allow if IP is in the office subnet (192.168.1.x)
      bool isOfficeSubnet =
          wifiIP != null && wifiIP.startsWith('192.168.1.');

      if (isOfficeWifi || isOfficeSubnet) {
        // Connected to office WiFi — allow clock-in
        return true;
      }

      // ❌ Not on office WiFi — show error and block
      String errorTxt =
          "Clock In failed! Please connect to '$officeWiFiName' WiFi.";
      if (cleanWifi.isEmpty || cleanWifi == "<unknown ssid>") {
        errorTxt =
            "Could not detect WiFi name. Please make sure WiFi and Location (GPS) are both ON.";
      }

      _showErrorSnackBar(errorTxt);
      return false;
    } catch (e) {
      _showErrorSnackBar("Error verification WiFi: ${e.toString()}");
      return false;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
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
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        ),
      );
    }

    final bool isClockedIn =
        _todayRecord != null && _todayRecord!['clock_out'] == null;
    final bool isClockedOut =
        _todayRecord != null && _todayRecord!['clock_out'] != null;

    bool isOnBreak = false;
    if (isClockedIn) {
      isOnBreak =
          _todayRecord!['on_break'] == true ||
          _todayRecord!['on_break'] == 1 ||
          (_todayRecord!['break_in'] != null &&
              _todayRecord!['break_out'] == null) ||
          (_todayRecord!['break_in_1'] != null &&
              _todayRecord!['break_out_1'] == null) ||
          (_todayRecord!['break_in_2'] != null &&
              _todayRecord!['break_out_2'] == null);
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
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
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
                      if (_todayRecord != null &&
                          _todayRecord!['clock_in'] != null)
                        Text(
                          "Clocked in at ${_formatTime(_todayRecord!['clock_in'])}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grey400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navy,
                    ),
                  )
                else
                  IconButton(
                    onPressed: _fetchStatus,
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.navy),
                    tooltip: 'Refresh status',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Live Work Duration Timer ──
          if (_todayRecord != null &&
              _todayRecord!['clock_in'] != null &&
              _todayRecord!['clock_out'] == null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.navy.withValues(alpha: 0.05),
                    AppColors.success.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_outlined,
                        color: AppColors.success, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Work Duration",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _formatElapsed(_elapsed),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _PulsingDot(),
                ],
              ),
            ),
          // ── Total Worked (after clock-out) ──
          if (_todayRecord != null && _todayRecord!['clock_out'] != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Worked",
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey400)),
                      Text(
                        _calcTotalWorked(),
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.info),
                      ),
                    ],
                  ),
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
                    () => _handleAction(ApiService.clockIn, isClockIn: true),
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
                    style: GoogleFonts.inter(
                      color: AppColors.grey400,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (isClockedIn) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          isOnBreak ? "End Break" : "Start Break",
                          isOnBreak
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          isOnBreak ? AppColors.info : AppColors.gold,
                          () => _handleAction(
                            isOnBreak
                                ? ApiService.breakOut
                                : ApiService.breakIn,
                          ),
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
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
      case "Clocked In":
        return AppColors.success;
      case "On Break":
        return AppColors.gold;
      case "Shift Ended":
        return AppColors.info;
      case "Not Clocked In":
        return AppColors.grey400;
      default:
        return AppColors.navy;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case "Clocked In":
        return Icons.timer_rounded;
      case "On Break":
        return Icons.coffee_rounded;
      case "Shift Ended":
        return Icons.check_circle_rounded;
      case "Not Clocked In":
        return Icons.more_time_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _formatTime(String timeStr) {
    try {
      if (timeStr.contains('T')) {
        return DateFormat('hh:mm a').format(
            DateTime.parse(timeStr).toLocal());
      }
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final dt = DateTime(2024, 1, 1, hour, min);
        return DateFormat('hh:mm a').format(dt);
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _calcTotalWorked() {
    final r = _todayRecord;
    if (r == null) return '00:00:00';
    final cin =
        DateTime.tryParse(r['clock_in']?.toString() ?? '')?.toLocal();
    final cout =
        DateTime.tryParse(r['clock_out']?.toString() ?? '')?.toLocal();
    if (cin == null || cout == null) return '00:00:00';
    return _formatElapsed(cout.difference(cin));
  }
}

// ── Pulsing animated green dot ──────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
