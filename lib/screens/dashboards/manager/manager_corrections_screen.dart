import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ManagerCorrectionsScreen extends StatefulWidget {
  const ManagerCorrectionsScreen({super.key});

  @override
  State<ManagerCorrectionsScreen> createState() => _ManagerCorrectionsScreenState();
}

class _ManagerCorrectionsScreenState extends State<ManagerCorrectionsScreen> {
  final List<Map<String, dynamic>> _corrections = [
    {
      'date': 'Mar 06, 2026',
      'issue': 'Missed Clock-Out',
      'actual': '06:30 PM',
      'status': 'Pending',
    },
    {
      'date': 'Feb 28, 2026',
      'issue': 'Early Clock-In Error',
      'actual': '08:45 AM',
      'status': 'Approved',
    },
    {
      'date': 'Feb 20, 2026',
      'issue': 'Break Duration Mismatch',
      'actual': '45 mins',
      'status': 'Rejected',
    },
  ];

  final _reasonController = TextEditingController();
  String _selectedIssue = 'Missed Clock-Out';

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Corrections',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.5)),
          Text('Request fixes for attendance discrepancies',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400)),
          const SizedBox(height: 24),
          _buildRequestForm(),
          const SizedBox(height: 28),
          Text('Previous Requests',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 12),
          ..._corrections.map((c) => _buildCorrectionCard(c)),
        ],
      ),
    );
  }

  Widget _buildRequestForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_calendar_rounded, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Text('New Correction Request',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Issue Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey400)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedIssue,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy, fontWeight: FontWeight.w500),
                items: ['Missed Clock-Out', 'Missed Clock-In', 'Break Duration Mismatch', 'Early Clock-In Error']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedIssue = v!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Reason', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey400)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the issue...',
              filled: true,
              fillColor: AppColors.offWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Submit Request',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionCard(Map<String, dynamic> c) {
    Color statusColor;
    switch (c['status']) {
      case 'Approved':
        statusColor = AppColors.success;
        break;
      case 'Rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['issue'],
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text('${c['date']}  •  Actual: ${c['actual']}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(c['status'],
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ],
      ),
    );
  }
}
