import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

import 'dashboards/employee/calendar_screen.dart';
import 'dashboards/employee/attendance_log_screen.dart';
import 'dashboards/employee/corrections_screen.dart';
import 'dashboards/employee/daily_work_log_screen.dart';
import 'dashboards/employee/task_management_screen.dart';
import 'dashboards/employee/apply_leave_screen.dart';
import 'dashboards/employee/events_screen.dart';
import 'dashboards/employee/company_holidays_screen.dart';
import 'dashboards/employee/employee_dashboard.dart';
import 'dashboards/employee/my_salary_screen.dart';
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
import 'dashboards/manager/manager_salary_screen.dart';
import 'dashboards/admin/departments_screen.dart';
import 'dashboards/admin/managerprofile_screen.dart';
import 'dashboards/admin/employeeprofile_screen.dart';
import 'dashboards/admin/attendance_corrections_screen.dart';
import 'dashboards/admin/all_daily_worksheets_screen.dart';
import 'dashboards/admin/team_leader_approvals_screen.dart';
import 'dashboards/manager/manager_team_worksheets_screen.dart';
import 'dashboards/manager/modules/business_leads_screen.dart';
import 'dashboards/manager/modules/client_directory_screen.dart';
import 'dashboards/manager/modules/project_details_screen.dart';
import 'dashboards/manager/modules/support_tickets_screen.dart';
import 'dashboards/admin/payroll_management_screen.dart';
import 'dashboards/admin/events_meetings_screen.dart';

import 'dashboards/manager/manager_team_leaves_screen.dart';

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
  int _selectedDashboardIndex = 0;
  late List<Map<String, dynamic>> _dashboards;
  late AnimationController _pulseController;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _initDashboards();
    _initAnimations();
    _startLiveClock();
    _syncStatusWithBackend();
  }

  Future<void> _syncStatusWithBackend() async {
    // Current dashboards handle their own status syncing.
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
        {'name': 'My Salary', 'icon': Icons.payments_rounded, 'isSub': true},
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
        {
          'name': 'Employee Approvals',
          'icon': Icons.time_to_leave_rounded,
          'isSub': true,
        },
        {
          'name': 'Business Operations',
          'icon': Icons.business_center_rounded,
          'isHeader': true,
        },
        {
          'name': 'Business Leads',
          'icon': Icons.leaderboard_rounded,
          'isSub': true,
        },
        {
          'name': 'Client Directory',
          'icon': Icons.contact_mail_rounded,
          'isSub': true,
        },
        {
          'name': 'Project Details',
          'icon': Icons.rocket_launch_rounded,
          'isSub': true,
        },
        {
          'name': 'Support Tickets',
          'icon': Icons.confirmation_number_rounded,
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
          'name': 'Team Approvals',
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
        {'name': 'My Salary', 'icon': Icons.payments_rounded},
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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
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
      return AdminDashboard(
        onNavigate: (idx) {
          if (mounted) setState(() => _selectedDashboardIndex = idx);
        },
      );
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
        return const CorrectionsScreen();

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
        final String lowerRole = role.toLowerCase();
        final bool isMgmt = lowerRole.contains('manager') ||
            lowerRole.contains('leader') ||
            lowerRole.contains('hr') ||
            lowerRole.contains('admin');
        return isMgmt ? const ManagerLeaveRequestScreen() : const ApplyLeaveScreen();

      case 'My Salary':
        return role == 'manager'
            ? const ManagerSalaryScreen()
            : const MySalaryScreen();

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
      case 'Employee Approvals':
        return role == 'manager'
            ? const ManagerTeamLeavesScreen()
            : const EmployeeLeavesScreen(); // Default

      case 'Recruitment':
        return const RecruitmentScreen();

      case 'Employee Leaves':
      case 'Staff Leave Data':
        return const EmployeeLeavesScreen();

      case 'Manager Leaves':
      case 'Manager Approvals':
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

      case 'Business Leads':
        return const BusinessLeadsScreen();

      case 'Client Directory':
        return const ClientDirectoryScreen();

      case 'Project Portfolio':
      case 'Project Details':
        return const ProjectDetailsScreen();

      case 'Support Tickets':
        return const SupportTicketsScreen();

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
      case 'Team Approvals':
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
              DateFormat('hh:mm:ss a').format(DateTime.now()),
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
}
