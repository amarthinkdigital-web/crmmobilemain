import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../attendance_action_card.dart';
import 'modules/business_leads_screen.dart';
import 'modules/client_directory_screen.dart';
import 'modules/project_details_screen.dart';
import 'modules/support_tickets_screen.dart';
import 'manager_salary_screen.dart';

class ManagerIndividualDashboard extends StatefulWidget {
  final String userName;
  const ManagerIndividualDashboard({super.key, required this.userName});

  @override
  State<ManagerIndividualDashboard> createState() =>
      _ManagerIndividualDashboardState();
}

class _ManagerIndividualDashboardState
    extends State<ManagerIndividualDashboard> {
  bool _isLoading = true;
  String _userRole = '';

  // Data states
  int _totalTasks = 0;
  int _completedTasks = 0;
  double _attendanceRate = 0.0;
  double _totalHoursWorked = 0.0;

  final List<double> _taskEfficiencyData = [
    70.0,
    50.0,
    80.0,
    60.0,
    90.0,
    75.0,
    95.0,
  ];
  final List<double> _hoursTrendData = [8.0, 8.5, 7.0, 9.5, 9.0, 0.0, 0.0];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final role = await AuthService.getUserRole() ?? 'Manager';

      // Simultaneously fetch data for performance metrics
      final results = await Future.wait([
        ApiService.getEmployeeTasks(),
        ApiService.getEmployeeDailyWorksheets(),
        ApiService.getMyAttendance(),
      ]);

      final taskRes = results[0];
      final worksheetRes = results[1];
      final attendanceRes = results[2];

      if (mounted) {
        setState(() {
          _userRole = role;

          // Tasks processing
          if (taskRes['error'] == false && taskRes['data'] is List) {
            final List tasks = taskRes['data'];
            _totalTasks = tasks.length;
            _completedTasks = tasks
                .where(
                  (t) =>
                      (t['status'] ?? '').toString().toLowerCase() ==
                      'completed',
                )
                .length;
          }

          // Worksheets processing for hours
          if (worksheetRes['error'] == false && worksheetRes['data'] is List) {
            final List sheets = worksheetRes['data'];
            _totalHoursWorked = sheets.fold(0.0, (sum, item) {
              final duration =
                  double.tryParse(item['duration']?.toString() ?? '0') ?? 0.0;
              return sum + duration;
            });
          }

          // Attendance calculation
          if (attendanceRes['error'] == false &&
              attendanceRes['data'] is List) {
            final List attendance = attendanceRes['data'];
            if (attendance.isNotEmpty) {
              final onTimeCount = attendance
                  .where((a) => (a['is_late'] == 0 || a['is_late'] == false))
                  .length;
              _attendanceRate = (onTimeCount / attendance.length) * 100;
            } else {
              _attendanceRate = 100.0;
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: AppColors.gold,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            const AttendanceActionCard(),
            const SizedBox(height: 32),
            _buildPerformanceStats(),
            const SizedBox(height: 32),
            _buildSectionHeader(
              "Operational Insights",
              "Key Performance Trends",
            ),
            const SizedBox(height: 16),
            _buildEfficiencyChart(),
            const SizedBox(height: 32),
            _buildSectionHeader(
              "Business Management",
              "Strategic operations & growth",
            ),
            const SizedBox(height: 16),
            _buildBusinessModules(),
            const SizedBox(height: 24),
            _buildHoursTrend(),
            const SizedBox(height: 32),
            _buildSectionHeader(
              "Recent Activities",
              "Management log highlights",
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Image.network(
                'https://m.media-amazon.com/images/I/71EL7BDl1EL._UF1000,1000_QL80_.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  widget.userName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: AppColors.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _userRole.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌑';
  }

  Widget _buildPerformanceStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Task Success",
                _completedTasks.toString(),
                "Total Assigned: $_totalTasks",
                Icons.task_alt_rounded,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                "Attendance",
                "${_attendanceRate.toStringAsFixed(1)}%",
                "Team punctuality",
                Icons.event_available_rounded,
                AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Logged Hours",
                "${_totalHoursWorked.toStringAsFixed(1)}h",
                "Management logs",
                Icons.hourglass_bottom_rounded,
                AppColors.gold,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                "Team Efficiency",
                "92%",
                "Strategic output",
                Icons.insights_rounded,
                Colors.deepPurpleAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String sub,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.grey600,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.grey400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyChart() {
    return _buildChartCard(
      title: "Team Performance Efficiency",
      subtitle: "Weekly aggregate (%)",
      content: SizedBox(
        height: 220,
        child: CustomPaint(
          size: Size.infinite,
          painter: BarChartPainter(
            data: _taskEfficiencyData,
            barColor: AppColors.success,
            labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
          ),
        ),
      ),
    );
  }

  Widget _buildHoursTrend() {
    return _buildChartCard(
      title: "Management Log Trend",
      subtitle: "Strategic hours per day",
      content: SizedBox(
        height: 220,
        child: CustomPaint(
          size: Size.infinite,
          painter: LineTrendPainter(
            data: _hoursTrendData,
            lineColor: AppColors.info,
            labels: ["M", "T", "W", "T", "F", "S", "S"],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grey100),
                ),
                child: Row(
                  children: [
                    Text(
                      "This Week",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          content,
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          _buildActivityItem(
            "Reviewed Team KPIs",
            "General Management",
            "1 hour ago",
            Icons.analytics_rounded,
            AppColors.success,
          ),
          const Divider(height: 1, indent: 80, color: AppColors.grey100),
          _buildActivityItem(
            "Strategy Meeting with Stakeholders",
            "Executive",
            "3 hours ago",
            Icons.domain_rounded,
            AppColors.info,
          ),
          const Divider(height: 1, indent: 80, color: AppColors.grey100),
          _buildActivityItem(
            "Budget Proposal Approved",
            "Financial",
            "Yesterday",
            Icons.account_balance_wallet_rounded,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessModules() {
    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Business Leads',
        'subtitle': 'Growth tracking',
        'icon': Icons.leaderboard_rounded,
        'color': AppColors.info,
        'screen': const BusinessLeadsScreen(),
      },
      {
        'title': 'Client Directory',
        'subtitle': 'Contacts matrix',
        'icon': Icons.contact_mail_rounded,
        'color': AppColors.gold,
        'screen': const ClientDirectoryScreen(),
      },
      {
        'title': 'Project Details',
        'subtitle': 'Portfolio data',
        'icon': Icons.rocket_launch_rounded,
        'color': AppColors.success,
        'screen': const ProjectDetailsScreen(),
      },
      {
        'title': 'Support Tickets',
        'subtitle': 'Issue resolution',
        'icon': Icons.confirmation_number_rounded,
        'color': AppColors.warning,
        'screen': const SupportTicketsScreen(),
      },
      {
        'title': 'My Salary',
        'subtitle': 'Earnings & payouts',
        'icon': Icons.payments_rounded,
        'color': AppColors.navy,
        'screen': const ManagerSalaryScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 130,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => module['screen']),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.grey100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: module['color'].withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: module['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module['icon'], color: module['color'], size: 24),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module['title'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      module['subtitle'],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(
    String title,
    String type,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grey400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.grey400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Bar Chart Painter ---
class BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color barColor;

  BarChartPainter({
    required this.data,
    required this.labels,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 20;
    final double graphWidth = size.width - (padding * 2);
    final double graphHeight = size.height - (padding * 2);
    final double barWidth = (graphWidth / data.length) * 0.5;
    final double spacing = (graphWidth / data.length);

    final paint = Paint()..color = barColor;
    final backgroundPaint = Paint()..color = AppColors.offWhite;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i < data.length; i++) {
      final double x = padding + (i * spacing) + (spacing / 2) - (barWidth / 2);

      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          padding,
          x + barWidth,
          padding + graphHeight,
          const Radius.circular(8),
        ),
        backgroundPaint,
      );

      final double barHeight = (data[i] / 100) * graphHeight;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          padding + graphHeight - barHeight,
          x + barWidth,
          padding + graphHeight,
          const Radius.circular(8),
        ),
        paint,
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.grey400,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth / 2) - (textPainter.width / 2), size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// --- Custom Line Trend Painter ---
class LineTrendPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;

  LineTrendPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 30;
    final double graphWidth = size.width - (padding * 2);
    final double graphHeight = size.height - (padding * 2);
    final double spacing = graphWidth / (data.length - 1);
    const double maxVal = 10.0;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = padding + (i * spacing);
      final double y =
          padding + graphHeight - ((data[i] / maxVal) * graphHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, padding + graphHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, padding + graphHeight);
        fillPath.close();
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.grey400,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 15),
      );
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = lineColor;
    final innerDotPaint = Paint()..color = AppColors.white;
    for (int i = 0; i < data.length; i++) {
      final double x = padding + (i * spacing);
      final double y =
          padding + graphHeight - ((data[i] / maxVal) * graphHeight);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 2.5, innerDotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
