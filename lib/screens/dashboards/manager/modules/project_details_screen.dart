import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final List<Map<String, dynamic>> _projects = [
    {
      'title': 'E-Commerce Platform Rebranding',
      'client': 'Global Industries',
      'progress': 0.75,
      'status': 'In Progress',
      'deadline': 'Dec 15, 2025',
      'tag': 'Development',
      'team': 8,
    },
    {
      'title': 'CRM Mobile App Design',
      'client': 'Tech Corp',
      'progress': 0.35,
      'status': 'At Risk',
      'deadline': 'Nov 10, 2025',
      'tag': 'UI/UX Design',
      'team': 4,
    },
    {
      'title': 'Server Infrastructure Migration',
      'client': 'InnoSoft',
      'progress': 1.0,
      'status': 'Completed',
      'deadline': 'Oct 20, 2025',
      'tag': 'DevOps',
      'team': 5,
    },
    {
      'title': 'AI chatbot integration',
      'client': 'Global Industries',
      'progress': 0.15,
      'status': 'Planning',
      'deadline': 'Jan 30, 2026',
      'tag': 'AI/ML',
      'team': 12,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeaderStats(),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final project = _projects[index];
                  return _buildProjectCard(project);
                },
                childCount: _projects.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navy, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Project Portfolio",
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.dashboard_customize_rounded, color: AppColors.navy),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn("Active", "12", AppColors.success),
          _buildStatColumn("Completed", "34", AppColors.info),
          _buildStatColumn("Delayed", "3", AppColors.error),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project['tag'],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      Text(
                        project['title'],
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project['client'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(project['status']!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(project['status']!),
                    color: _getStatusColor(project['status']!),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Overall Progress",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      "${(project['progress'] * 100).toInt()}%",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project['progress'],
                    minHeight: 8,
                    backgroundColor: AppColors.offWhite,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(project['status']!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.grey400),
                        const SizedBox(width: 8),
                        Text(
                          project['deadline'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grey400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 14, color: AppColors.grey400),
                        const SizedBox(width: 8),
                        Text(
                          "${project['team']} Team Members",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.grey400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Completed') return AppColors.success;
    if (status == 'At Risk') return AppColors.error;
    if (status == 'Planning') return AppColors.info;
    return AppColors.navy;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'Completed') return Icons.check_circle_rounded;
    if (status == 'At Risk') return Icons.warning_rounded;
    if (status == 'Planning') return Icons.edit_calendar_rounded;
    return Icons.more_time_rounded;
  }
}
