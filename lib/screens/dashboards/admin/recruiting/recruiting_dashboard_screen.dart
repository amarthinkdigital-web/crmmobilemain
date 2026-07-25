import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/recruiting_api_service.dart';
import '../../../../models/interview_model.dart';
import 'add_edit_interview_screen.dart';
import 'interview_details_screen.dart';

class RecruitingDashboardScreen extends StatefulWidget {
  const RecruitingDashboardScreen({super.key});

  @override
  State<RecruitingDashboardScreen> createState() =>
      _RecruitingDashboardScreenState();
}

class _RecruitingDashboardScreenState extends State<RecruitingDashboardScreen> {
  bool _isLoading = true;
  List<Interview> _interviews = [];
  String _searchQuery = '';

  int _total = 0;
  int _planned = 0;
  int _scheduled = 0;
  int _taskSubmitted = 0;
  int _selected = 0;
  int _rejected = 0;
  int _joined = 0;

  @override
  void initState() {
    super.initState();
    _fetchInterviews();
  }

  Future<void> _fetchInterviews() async {
    setState(() => _isLoading = true);
    final response = await RecruitingApiService.getInterviews(
      search: _searchQuery,
    );

    if (mounted) {
      if (response['error'] == false) {
        final List data = response['data'] ?? [];
        _interviews = data.map((e) => Interview.fromJson(e)).toList();
        _calculateStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load interviews'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    _total = _interviews.length;
    _planned = _interviews
        .where((i) => i.status.toLowerCase().contains('planned'))
        .length;
    _scheduled = _interviews
        .where((i) => i.status.toLowerCase().contains('scheduled'))
        .length;
    _taskSubmitted = _interviews
        .where((i) => i.status.toLowerCase().contains('task'))
        .length;
    _selected = _interviews
        .where((i) => i.status.toLowerCase().contains('selected'))
        .length;
    _rejected = _interviews
        .where((i) => i.status.toLowerCase().contains('rejected'))
        .length;
    _joined = _interviews
        .where((i) => i.status.toLowerCase().contains('joined'))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchInterviews,
                      color: AppColors.navy,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsGrid(),
                            const SizedBox(height: 28),
                            _buildCandidatesList(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.info, Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recruiting",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Manage all interviews and candidate pipeline",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditInterviewScreen()),
            ).then((_) => _fetchInterviews()),
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add Interview"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        // Calculate card width based on container constraints
        final cardWidth = (totalWidth - 40) / 3; // 3 per row with spacing

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                "TOTAL",
                _total.toString(),
                Icons.assignment_rounded,
                AppColors.navy,
                const LinearGradient(
                  colors: [Color(0xFF0A1628), Color(0xFF1B2D4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                "PLANNED",
                _planned.toString(),
                Icons.calendar_month_rounded,
                AppColors.info,
                const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                "SCHEDULED",
                _scheduled.toString(),
                Icons.check_circle_rounded,
                AppColors.success,
                const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                "TASK SUBMITTED",
                _taskSubmitted.toString(),
                Icons.move_to_inbox_rounded,
                const Color(0xFF8B5CF6),
                const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                "SELECTED",
                _selected.toString(),
                Icons.emoji_events_rounded,
                AppColors.gold,
                const LinearGradient(
                  colors: [Color(0xFFD4A843), Color(0xFFB8922E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                "REJECTED",
                _rejected.toString(),
                Icons.cancel_rounded,
                AppColors.error,
                const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                "JOINED",
                _joined.toString(),
                Icons.celebration_rounded,
                const Color(0xFF6366F1),
                const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    LinearGradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.list_alt_rounded,
                    color: AppColors.navy,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "All Candidates",
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_interviews.length} total",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: TextField(
              onChanged: (val) {
                _searchQuery = val;
                _fetchInterviews();
              },
              decoration: InputDecoration(
                hintText: "Search by name, email or position...",
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grey400,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.search, color: AppColors.grey400, size: 20),
                ),
                fillColor: AppColors.offWhite,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (_interviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: AppColors.grey200),
                    const SizedBox(height: 12),
                    Text(
                      "No candidates found.",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey400,
                    letterSpacing: 0.5,
                  ),
                  dataTextStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                  headingRowHeight: 48,
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 72,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('CANDIDATE')),
                    DataColumn(label: Text('APPLY FOR')),
                    DataColumn(label: Text('INTERVIEW DATE')),
                    DataColumn(label: Text('TIME')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: List.generate(_interviews.length, (index) {
                    final interview = _interviews[index];
                    final isEven = index % 2 == 0;
                    return DataRow(
                      color: WidgetStatePropertyAll(
                        isEven ? Colors.transparent : AppColors.offWhite.withValues(alpha: 0.5),
                      ),
                      cells: [
                        DataCell(
                          Text(
                            (index + 1).toString(),
                            style: GoogleFonts.inter(
                              color: AppColors.grey400,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getAvatarColor(interview.name),
                                radius: 18,
                                child: Text(
                                  interview.name.isNotEmpty
                                      ? interview.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    interview.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    interview.email,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.infoBg.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              interview.applyFor,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 14,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                interview.interviewDate,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${interview.interviewTimeFrom} - ${interview.interviewTimeTo}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(_buildStatusBadge(interview.status)),
                        DataCell(_buildActionsMenu(interview)),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.info,
      const Color(0xFF8B5CF6),
      AppColors.success,
      AppColors.gold,
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      AppColors.warning,
      const Color(0xFF6366F1),
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'planned':
        bgColor = AppColors.infoBg;
        textColor = AppColors.info;
        icon = Icons.schedule;
        break;
      case 'scheduled':
        bgColor = AppColors.successBg;
        textColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'selected':
        bgColor = const Color(0xFFFEF3C7);
        textColor = AppColors.gold;
        icon = Icons.emoji_events;
        break;
      case 'rejected':
        bgColor = AppColors.errorBg;
        textColor = AppColors.error;
        icon = Icons.cancel;
        break;
      case 'joined':
        bgColor = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF7C3AED);
        icon = Icons.celebration;
        break;
      default:
        bgColor = AppColors.grey100;
        textColor = AppColors.grey600;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(Interview interview) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleAction(value, interview),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: AppColors.white,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.visibility, size: 18, color: AppColors.info),
              SizedBox(width: 10),
              Text('View Details', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.edit_calendar, size: 18, color: AppColors.warning),
              SizedBox(width: 10),
              Text('Edit & Reschedule', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sync',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.sync, size: 18, color: AppColors.gold),
              SizedBox(width: 10),
              Text('Sync Calendar', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'tasks',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.move_to_inbox, size: 18, color: AppColors.navy),
              SizedBox(width: 10),
              Text('Received Tasks', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'followups',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.forum, size: 18, color: Color(0xFF8B5CF6)),
              SizedBox(width: 10),
              Text('Follow Ups', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Actions",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.grey600),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, Interview interview) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InterviewDetailsScreen(interviewId: interview.id),
          ),
        );
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditInterviewScreen(interview: interview),
          ),
        ).then((_) => _fetchInterviews());
        break;
      case 'sync':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading Calendar file...")),
        );
        break;
      case 'tasks':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InterviewDetailsScreen(
              interviewId: interview.id,
              initialTab: 1,
            ),
          ),
        );
        break;
      case 'followups':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InterviewDetailsScreen(
              interviewId: interview.id,
              initialTab: 2,
            ),
          ),
        );
        break;
      case 'delete':
        _confirmDelete(interview.id);
        break;
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete, color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              "Delete Interview",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this interview?",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey400,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final response = await RecruitingApiService.deleteInterview(id);
              if (response['error'] == false) {
                _fetchInterviews();
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(response['message'])));
                }
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
