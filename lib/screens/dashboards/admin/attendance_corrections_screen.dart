import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AttendanceCorrectionsScreen extends StatefulWidget {
  const AttendanceCorrectionsScreen({super.key});

  @override
  State<AttendanceCorrectionsScreen> createState() =>
      _AttendanceCorrectionsScreenState();
}

class _AttendanceCorrectionsScreenState
    extends State<AttendanceCorrectionsScreen> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> corrections = [
    {
      "employee": "John Doe",
      "date": "2026-03-08",
      "proposedIn": "09:00 AM",
      "proposedOut": "06:00 PM",
      "reason": "Fingerprint scanner failure",
      "appliedOn": "2026-03-09",
      "status": "Pending",
    },
    {
      "employee": "Jane Smith",
      "date": "2026-03-07",
      "proposedIn": "08:30 AM",
      "proposedOut": "05:30 PM",
      "reason": "Forgot to punch out",
      "appliedOn": "2026-03-08",
      "status": "Approved",
    },
    {
      "employee": "Kyle Reese",
      "date": "2026-03-06",
      "proposedIn": "09:15 AM",
      "proposedOut": "06:15 PM",
      "reason": "Personal Emergency - late punch",
      "appliedOn": "2026-03-07",
      "status": "Rejected",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilterSection(),
            const SizedBox(height: 24),
            _buildCorrectionsTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Attendance Corrections",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Manage and review employee attendance adjustment requests",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search by employee name...",
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.grey400,
                  ),
                  filled: true,
                  fillColor: AppColors.offWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Search",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.navy.withValues(alpha: 0.02),
            ),
            columnSpacing: 30,
            horizontalMargin: 20,
            columns: [
              _buildDataColumn("Employee"),
              _buildDataColumn("Date"),
              _buildDataColumn("Proposed In"),
              _buildDataColumn("Proposed Out"),
              _buildDataColumn("Reason"),
              _buildDataColumn("Applied On"),
              _buildDataColumn("Action"),
            ],
            rows: corrections.map((req) => _buildRow(req)).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }

  DataRow _buildRow(Map<String, dynamic> req) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            req['employee'],
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            req['date'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            req['proposedIn'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            req['proposedOut'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              req['reason'],
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.grey600,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            req['appliedOn'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildActionButton(
                Icons.check_circle_outline_rounded,
                AppColors.success,
                () {},
              ),
              const SizedBox(width: 8),
              _buildActionButton(Icons.cancel_outlined, AppColors.error, () {}),
              const SizedBox(width: 8),
              _buildActionButton(
                Icons.visibility_outlined,
                AppColors.navy,
                () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
