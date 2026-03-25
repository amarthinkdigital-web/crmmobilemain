import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class TeamAttendanceViewScreen extends StatefulWidget {
  const TeamAttendanceViewScreen({super.key});

  @override
  State<TeamAttendanceViewScreen> createState() => _TeamAttendanceViewScreenState();
}

class _TeamAttendanceViewScreenState extends State<TeamAttendanceViewScreen> {
  final List<Map<String, dynamic>> _team = [
    {'name': 'Alex Johnson', 'role': 'Developer', 'status': 'Working', 'in': '09:02 AM', 'hours': '3h 14m'},
    {'name': 'Sophie Chen', 'role': 'Designer', 'status': 'Working', 'in': '09:10 AM', 'hours': '3h 06m'},
    {'name': 'Marcus Wright', 'role': 'Support Lead', 'status': 'On Break', 'in': '08:55 AM', 'hours': '3h 15m'},
    {'name': 'Lisa Smith', 'role': 'Marketing', 'status': 'Not In', 'in': '—', 'hours': '0h 00m'},
    {'name': 'Ryan Patel', 'role': 'QA Engineer', 'status': 'Working', 'in': '09:30 AM', 'hours': '2h 40m'},
    {'name': 'Nadia Khan', 'role': 'Copywriter', 'status': 'Working', 'in': '09:00 AM', 'hours': '3h 12m'},
  ];

  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _team
        : _team.where((m) => m['status'] == _filter).toList();

    final working = _team.where((m) => m['status'] == 'Working').length;
    final onBreak = _team.where((m) => m['status'] == 'On Break').length;
    final absent = _team.where((m) => m['status'] == 'Not In').length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Team Attendance',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.5)),
          Text('Real-time team attendance status',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400)),
          const SizedBox(height: 24),
          Row(
            children: [
              _statPill('Working', working, AppColors.success),
              const SizedBox(width: 10),
              _statPill('On Break', onBreak, AppColors.warning),
              const SizedBox(width: 10),
              _statPill('Absent', absent, AppColors.error),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilterRow(),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, i) => _buildMemberRow(filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', 'Working', 'On Break', 'Not In'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map((f) => GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: _filter == f ? AppColors.navy : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _filter == f ? AppColors.navy : AppColors.grey100),
                    ),
                    child: Text(f,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _filter == f ? AppColors.white : AppColors.grey600)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member) {
    Color statusColor;
    switch (member['status']) {
      case 'Working':
        statusColor = AppColors.success;
        break;
      case 'On Break':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.navy.withOpacity(0.06),
            child: Text(member['name'][0],
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['name'],
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text(member['role'], style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 5, height: 5,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(member['status'],
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(member['status'] != 'Not In' ? 'In: ${member['in']}' : 'Not Clocked In',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.grey400)),
            ],
          ),
          const SizedBox(width: 10),
          Text(member['hours'],
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
        ],
      ),
    );
  }
}
