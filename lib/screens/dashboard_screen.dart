import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'dashboards/employee/calendar_screen.dart';
import 'dashboards/employee/attendance_log_screen.dart';
import 'dashboards/employee/corrections_screen.dart';
import 'dashboards/employee/daily_work_log_screen.dart';
import 'dashboards/employee/task_management_screen.dart';
import 'dashboards/employee/apply_leave_screen.dart';
import 'dashboards/employee/events_screen.dart';
import 'dashboards/employee/company_holidays_screen.dart';
import 'dashboards/employee/shift_state.dart';
import 'dashboards/employee/employee_dashboard.dart';
import 'dashboards/admin/admin_dashboard.dart';
import 'dashboards/admin/recruitment_screen.dart';
import 'dashboards/admin/employee_leaves_screen.dart';
import 'dashboards/admin/manager_leaves_screen.dart';
import 'dashboards/admin/service_domains_screen.dart';
import 'dashboards/admin/service_hosting_screen.dart';
import 'dashboards/admin/client_profiles_screen.dart';
import 'dashboards/admin/invoice_list_screen.dart';
import 'dashboards/admin/create_invoice_screen.dart';
import 'dashboards/admin/holiday_calendar_screen.dart';
import 'dashboards/admin/settings_screen.dart';
import 'dashboards/admin/whatsapp_settings_screen.dart';
import 'dashboards/admin/team_attendance_screen.dart';
import 'dashboards/admin/task_tracking_screen.dart';
import 'dashboards/manager/manager_individual_dashboard.dart';
import 'dashboards/manager/manager_calendar_screen.dart';
import 'dashboards/manager/manager_attendance_screen.dart';
import 'dashboards/manager/manager_corrections_screen.dart';
import 'dashboards/manager/manager_work_log_screen.dart';
import 'dashboards/manager/manager_assignments_screen.dart';
import 'dashboards/manager/manager_leave_request_screen.dart';
import 'dashboards/manager/manager_events_screen.dart';
import 'dashboards/manager/manager_holidays_screen.dart';
import 'dashboards/manager/manager_team_attendance_view.dart';
import 'dashboards/admin/departments_screen.dart';
import 'dashboards/admin/managerprofile_screen.dart';
import 'dashboards/admin/employeeprofile_screen.dart';
import 'dashboards/admin/attendance_corrections_screen.dart';
import 'dashboards/admin/all_daily_worksheets_screen.dart';
import 'dashboards/admin/team_leader_approvals_screen.dart';
import 'dashboards/manager/manager_team_worksheets_screen.dart';
import 'dashboards/admin/payroll_management_screen.dart';
import 'dashboards/admin/events_meetings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userRole;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ShiftState _shiftState = ShiftState.idle;
  int _selectedDashboardIndex = 0; // 0 is Main, items follow in list
  late List<Map<String, dynamic>> _dashboards;

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
    _initDashboards();
    _initAnimations();
    _startLiveClock();
    _syncStatusWithBackend();
  }

  Future<void> _syncStatusWithBackend() async {
    if (widget.userEmail.contains('demo')) return;

    final status = await ApiService.getStatus();
    setState(() {
      switch (status['status']) {
        case 'working':
          _shiftState = ShiftState.working;
          if (status['clock_in'] != null) {
            _clockInTime = DateTime.tryParse(status['clock_in']);
          }
          break;
        case 'on_break':
          _shiftState = ShiftState.onBreak;
          if (status['clock_in'] != null) {
            _clockInTime = DateTime.tryParse(status['clock_in']);
          }
          if (status['break_in'] != null) {
            _breakStartTime = DateTime.tryParse(status['break_in']);
          }
          break;
        default:
          _shiftState = ShiftState.idle;
      }

      // Sync accumulated worked time if provided
      if (status['total_worked_seconds'] != null) {
        _totalWorked = Duration(seconds: status['total_worked_seconds']);
      }
      if (status['total_break_seconds'] != null) {
        _totalBreak = Duration(seconds: status['total_break_seconds']);
      }

      _updateTimers(); // Call to update display based on synced data
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initDashboards() {
    final String role = widget.userRole.toLowerCase();

    if (role == 'manager') {
      _dashboards = [
        {'name': 'My Dashboard', 'icon': Icons.dashboard_rounded},
        {'name': 'Calendar', 'icon': Icons.calendar_today_rounded},
        {
          'name': 'Personal Tools',
          'icon': Icons.person_rounded,
          'isHeader': true,
        },
        {
          'name': 'Attendance Log',
          'icon': Icons.history_rounded,
          'isSub': true,
        },
        {
          'name': 'Corrections',
          'icon': Icons.edit_calendar_rounded,
          'isSub': true,
        },
        {
          'name': 'Daily Work Log',
          'icon': Icons.description_rounded,
          'isSub': true,
        },
        {
          'name': 'Tasks Management',
          'icon': Icons.assignment_rounded,
          'isSub': true,
        },
        {
          'name': 'Apply for Leave',
          'icon': Icons.time_to_leave_rounded,
          'isSub': true,
        },
        {
          'name': 'Team Management',
          'icon': Icons.groups_rounded,
          'isHeader': true,
        },
        {
          'name': 'Team Attendance',
          'icon': Icons.person_pin_circle_rounded,
          'isSub': true,
        },
        {
          'name': 'Team Worksheets',
          'icon': Icons.description_outlined,
          'isSub': true,
        },
        {'name': 'Events', 'icon': Icons.event_rounded},
        {'name': 'Company Holidays', 'icon': Icons.beach_access_rounded},
      ];
    } else if (role == 'admin') {
      _dashboards = [
        {'name': 'Admin Console', 'icon': Icons.dashboard_rounded},
        {'name': 'Calendar', 'icon': Icons.calendar_today_rounded},
        {
          'name': 'Team Management',
          'icon': Icons.business_rounded,
          'isHeader': true,
        },
        {'name': 'Departments', 'icon': Icons.domain_rounded, 'isSub': true},
        {
          'name': 'Manager Profile',
          'icon': Icons.domain_rounded,
          'isSub': true,
        },
        {
          'name': 'Employee Profile',
          'icon': Icons.domain_rounded,
          'isSub': true,
        },
        {
          'name': 'Team Attendance',
          'icon': Icons.person_pin_circle_rounded,
          'isSub': true,
        },
        {
          'name': 'Attendance Corrections',
          'icon': Icons.edit_calendar_rounded,
          'isSub': true,
        },
        {
          'name': 'All Daily Worksheets',
          'icon': Icons.description_outlined,
          'isSub': true,
        },
        {
          'name': 'Team Leader Approvals',
          'icon': Icons.rule_folder_rounded,
          'isSub': true,
        },
        {
          'name': 'Payroll Management',
          'icon': Icons.payments_rounded,
          'isSub': true,
        },
        {
          'name': 'Events & Meetings',
          'icon': Icons.event_available_rounded,
          'isSub': true,
        },
        {
          'name': 'Task Management',
          'icon': Icons.checklist_rounded,
          'isSub': true,
        },
        {'name': 'Recruitment', 'icon': Icons.person_search_rounded},
        {'name': 'Approvals', 'icon': Icons.approval_rounded, 'isHeader': true},
        {'name': 'Employee Leaves', 'icon': Icons.hail_rounded, 'isSub': true},
        {'name': 'Manager Leaves', 'icon': Icons.badge_rounded, 'isSub': true},
        {
          'name': 'Services Management',
          'icon': Icons.settings_input_component_rounded,
          'isHeader': true,
        },
        {
          'name': 'Service Domains',
          'icon': Icons.domain_rounded,
          'isSub': true,
        },
        {'name': 'Service Hosting', 'icon': Icons.dns_rounded, 'isSub': true},
        {'name': 'Client Profiles', 'icon': Icons.account_box_rounded},
        {
          'name': 'Financials',
          'icon': Icons.receipt_long_rounded,
          'isHeader': true,
        },
        {'name': 'Invoice List', 'icon': Icons.list_alt_rounded, 'isSub': true},
        {
          'name': 'Create Invoice',
          'icon': Icons.add_chart_rounded,
          'isSub': true,
        },
        {'name': 'Holiday Calendar', 'icon': Icons.beach_access_rounded},
        {'name': 'System Settings', 'icon': Icons.settings_suggest_rounded},
        {'name': 'WhatsApp Settings', 'icon': Icons.message_rounded},
      ];
    } else {
      // Default: Employee
      _dashboards = [
        {'name': 'My Workspace', 'icon': Icons.dashboard_rounded},
        {'name': 'Calendar', 'icon': Icons.calendar_today_rounded},
        {'name': 'Attendance Log', 'icon': Icons.history_rounded},
        {'name': 'Corrections', 'icon': Icons.edit_calendar_rounded},
        {'name': 'My Worksheet List', 'icon': Icons.description_rounded},
        {'name': 'Task Management', 'icon': Icons.assignment_rounded},
        {'name': 'Apply for Leave', 'icon': Icons.time_to_leave_rounded},
        {'name': 'Events', 'icon': Icons.event_rounded},
        {'name': 'Company Holidays', 'icon': Icons.beach_access_rounded},
      ];
    }
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
    // The UI refreshes via the live clock ticker.
    // Logic is handled by _displayWorked and _displayBreak getters.
    setState(() {});
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

  // ─── Attendance Logic ──────────────────────────────────────────────────────

  double _getProgress() {
    // 8 hour goal = 28,800 seconds
    const double goal = 28800.0;
    final double current = _displayWorked.inSeconds.toDouble();
    return (current / goal).clamp(0.0, 1.0);
  }

  void _addActivity(String label, IconData icon, Color color) {
    setState(() {
      _activityLog.insert(
        0,
        _ActivityEntry(
          label: label,
          icon: icon,
          color: color,
          time: DateFormat('hh:mm a').format(DateTime.now()),
        ),
      );
    });
  }

  Future<void> _clockIn() async {
    final res = await ApiService.clockIn();
    if (res['error'] == true) {
      _showError(res['message']);
      return;
    }

    setState(() {
      _shiftState = ShiftState.working;
      _clockInTime = DateTime.now();
      _totalWorked = Duration.zero;
      _totalBreak = Duration.zero;
      _addActivity("Clocked In", Icons.login_rounded, AppColors.success);
    });
  }

  Future<void> _clockOut() async {
    final res = await ApiService.clockOut();
    if (res['error'] == true) {
      _showError(res['message']);
      return;
    }

    setState(() {
      _shiftState = ShiftState.idle;
      _clockInTime = null;
      _breakStartTime = null;
      _addActivity("Clocked Out", Icons.logout_rounded, AppColors.error);
    });
  }

  Future<void> _breakIn() async {
    final res = await ApiService.breakIn();
    if (res['error'] == true) {
      _showError(res['message']);
      return;
    }

    setState(() {
      _shiftState = ShiftState.onBreak;
      _breakStartTime = DateTime.now();
      _addActivity("Started Break", Icons.coffee_rounded, AppColors.warning);
    });
  }

  Future<void> _breakOut() async {
    final res = await ApiService.breakOut();
    if (res['error'] == true) {
      _showError(res['message']);
      return;
    }

    setState(() {
      _shiftState = ShiftState.working;
      if (_breakStartTime != null) {
        _totalBreak += DateTime.now().difference(_breakStartTime!);
      }
      _breakStartTime = null;
      _addActivity("Ended Break", Icons.play_arrow_rounded, AppColors.info);
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      key: _scaffoldKey,
      backgroundColor: AppColors.offWhite,
      drawer: _buildSidebar(),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _selectedDashboardIndex == 0
                ? _buildMainDashboard()
                : _buildOtherDashboard(),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar (Drawer) ───
  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: AppColors.navy,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _dashboards.asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;

                final bool isHeader = data['isHeader'] ?? false;
                final bool isSub = data['isSub'] ?? false;

                // Headers are built as ExpansionTiles
                if (isHeader) {
                  // Find sub-items belonging to this header
                  final subItems = <Widget>[];
                  int subIdx = idx + 1;
                  while (subIdx < _dashboards.length &&
                      (_dashboards[subIdx]['isSub'] ?? false)) {
                    final currentIdx = subIdx;
                    final subData = _dashboards[currentIdx];
                    subItems.add(
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 32),
                        leading: Icon(
                          subData['icon'],
                          size: 18,
                          color: _selectedDashboardIndex == currentIdx
                              ? AppColors.gold
                              : AppColors.white.withValues(alpha: 0.6),
                        ),
                        title: Text(
                          subData['name'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _selectedDashboardIndex == currentIdx
                                ? AppColors.gold
                                : AppColors.white.withValues(alpha: 0.8),
                            fontWeight: _selectedDashboardIndex == currentIdx
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedDashboardIndex = currentIdx);
                          Navigator.pop(context);
                        },
                      ),
                    );
                    subIdx++;
                  }

                  return Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(
                        data['icon'],
                        color: AppColors.gold,
                        size: 20,
                      ),
                      title: Text(
                        data['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      iconColor: AppColors.gold,
                      collapsedIconColor: AppColors.white.withValues(
                        alpha: 0.5,
                      ),
                      children: subItems,
                    ),
                  );
                }

                // If it's a sub-item, skip it here (already handled by ExpansionTile)
                if (isSub) return const SizedBox.shrink();

                // Normal menu items
                return ListTile(
                  leading: Icon(
                    data['icon'],
                    color: _selectedDashboardIndex == idx
                        ? AppColors.gold
                        : AppColors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  title: Text(
                    data['name'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _selectedDashboardIndex == idx
                          ? AppColors.gold
                          : AppColors.white,
                      fontWeight: _selectedDashboardIndex == idx
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedDashboardIndex = idx);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        bottom: 30,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navy.withValues(alpha: 0.8)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: AppColors.navy,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName.isEmpty ? 'User' : widget.userName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.userRole.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.logout_rounded,
          color: AppColors.error,
          size: 20,
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: widget.onLogout,
      ),
    );
  }

  Widget _buildMainDashboard() {
    // If demo user, show employee dashboard
    if (widget.userEmail == 'demo@thinkdigital.com' ||
        widget.userEmail == 'demo1@thinkdigital.com') {
      return EmployeeDashboard(userName: widget.userName);
    }

    final String role = widget.userRole.toLowerCase();

    // Role-based main view
    if (role == 'manager') {
      return ManagerIndividualDashboard(userName: widget.userName);
    } else if (role == 'admin') {
      return const AdminDashboard();
    } else {
      return EmployeeDashboard(userName: widget.userName);
    }
  }

  Widget _buildOtherDashboard() {
    final String role = widget.userRole.toLowerCase();
    final String name = _dashboards[_selectedDashboardIndex]['name'];

    switch (name) {
      case 'Calendar':
        return role == 'manager'
            ? const ManagerCalendarScreen()
            : const CalendarScreen();

      case 'Attendance Log':
        return role == 'manager'
            ? const ManagerAttendanceScreen()
            : const AttendanceLogScreen();

      case 'Corrections':
        if (role == 'manager') return const ManagerCorrectionsScreen();
        return CorrectionsScreen(
          shiftState: _shiftState,
          liveTime: _liveTime,
          formattedWorked: _formatDuration(_displayWorked),
          formattedBreak: _formatDuration(_displayBreak),
          timerStatusText: _shiftState == ShiftState.onBreak
              ? '☕ On Break'
              : (_shiftState == ShiftState.working
                    ? '● Working'
                    : 'Ready to start'),
          timerProgress: _shiftState != ShiftState.idle ? _getProgress() : 0,
          pulseAnim: _pulseAnim,
          activityLog: _activityLog,
          onClockIn: _clockIn,
          onClockOut: _clockOut,
          onBreakIn: _breakIn,
          onBreakOut: _breakOut,
        );

      case 'Daily Work Log':
      case 'My Worksheet List':
        return role == 'manager'
            ? const ManagerWorkLogScreen()
            : const DailyWorkLogScreen();

      case 'My Assignments':
      case 'My Tasks':
      case 'Tasks Management':
      case 'Task Management':
        if (role == 'admin') return const TaskTrackingScreen();
        return role == 'manager'
            ? const ManagerAssignmentsScreen()
            : const TaskManagementScreen();

      case 'Apply for Leave':
        return role == 'manager'
            ? const ManagerLeaveRequestScreen()
            : const ApplyLeaveScreen();

      case 'Events':
        return role == 'manager'
            ? const ManagerEventsScreen()
            : const EventsScreen();

      case 'Company Holidays':
        return role == 'manager'
            ? ManagerHolidaysScreen(userRole: widget.userRole)
            : const CompanyHolidaysScreen();

      case 'Team Worksheets':
        return const ManagerTeamWorksheetsScreen();

      case 'Recruitment':
        return const RecruitmentScreen();

      case 'Employee Leaves':
        return const EmployeeLeavesScreen();

      case 'Manager Leaves':
        return const ManagerLeavesScreen();

      case 'Service Domains':
        return const ServiceDomainsScreen();

      case 'Service Hosting':
        return const ServiceHostingScreen();

      case 'Client Profiles':
        return const ClientProfilesScreen();

      case 'Invoice List':
        return const InvoiceListScreen();

      case 'Create Invoice':
        return const CreateInvoiceScreen();

      case 'Departments':
        return const DepartmentsScreen();

      case 'Holiday Calendar':
        return const HolidayCalendarScreen();

      case 'System Settings':
      case 'Settings':
        return const SettingsScreen();

      case 'WhatsApp Settings':
        return const WhatsappSettingsScreen();

      case 'Team Attendance':
        return role == 'manager'
            ? const TeamAttendanceViewScreen()
            : const TeamAttendanceScreen();

      case 'Attendance Corrections':
        return const AttendanceCorrectionsScreen();
      case 'All Daily Worksheets':
        return const AllDailyWorksheetsScreen();
      case 'Team Leader Approvals':
        return const TeamLeaderApprovalsScreen();
      case 'Payroll Management':
        return const PayrollManagementScreen();
      case 'Events & Meetings':
        return const EventsMeetingsScreen();

      case 'Performance Task':
        return const TaskTrackingScreen();

      case 'My Dashboard':
        return ManagerIndividualDashboard(userName: widget.userName);

      case 'Manager Profile':
        return const ManagerPage();

      case 'Employee Profile':
        return const EmployeeProfileScreen();

      default:
        return _buildMainDashboard();
    }
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
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo & Toggle Button (Sidebar Trigger)
          InkWell(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: AppColors.navy,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _dashboards[_selectedDashboardIndex]['name'],
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.gold,
                      size: 14,
                    ),
                  ],
                ),
                Text(
                  'Hello, ${widget.userName.split(' ').first}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Live clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              _liveTime,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ─── Greeting ───
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greetingText,',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),
                Text(
                  '${widget.userName.split(' ').first} 👋',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.navy,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.navy,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
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
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
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
                Icon(
                  Icons.event_note_rounded,
                  size: 44,
                  color: AppColors.grey200,
                ),
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
                    child: Icon(entry.icon, size: 20, color: entry.color),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                color: (badgeColor ?? AppColors.grey400).withValues(
                  alpha: 0.12,
                ),
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
