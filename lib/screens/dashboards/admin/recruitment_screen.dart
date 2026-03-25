import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  final List<Map<String, dynamic>> interviews = [
    {
      "id": "INT-001",
      "name": "Rohan Mehta",
      "email": "rohan.m@example.com",
      "applyFor": "Senior Flutter Developer",
      "interviewDate": "2026-03-12",
      "time": "10:30 AM",
      "status": "Scheduled",
    },
    {
      "id": "INT-002",
      "name": "Priya Sharma",
      "email": "priya.s@example.com",
      "applyFor": "UI/UX Designer",
      "interviewDate": "2026-03-13",
      "time": "02:00 PM",
      "status": "Pending",
    },
    {
      "id": "INT-003",
      "name": "Arjun Singh",
      "email": "arjun.s@example.com",
      "applyFor": "Backend Engineer",
      "interviewDate": "2026-03-11",
      "time": "11:00 AM",
      "status": "Completed",
    },
  ];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  String selectedStatus = "Pending";

  void _showAddInterviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add New Interview",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInputField(
                "Candidate Name",
                "Enter name",
                nameController,
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                "Email Address",
                "Enter email",
                emailController,
                Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                "Apply For",
                "Enter job role",
                roleController,
                Icons.work_outline_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      "Interview Date",
                      "Select date",
                      dateController,
                      Icons.calendar_today_rounded,
                      isReadOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          dateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      "Interview Time",
                      "Select time",
                      timeController,
                      Icons.access_time_rounded,
                      isReadOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          timeController.text = time.format(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusDropdown(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      interviews.add({
                        "id": "INT-00${interviews.length + 1}",
                        "name": nameController.text,
                        "email": emailController.text,
                        "applyFor": roleController.text,
                        "interviewDate": dateController.text,
                        "time": timeController.text,
                        "status": selectedStatus,
                      });
                    });
                    _clearControllers();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    "Schedule Interview",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _clearControllers() {
    nameController.clear();
    emailController.clear();
    roleController.clear();
    dateController.clear();
    timeController.clear();
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
            filled: true,
            fillColor: AppColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Status",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              items: [
                "Pending",
                "Scheduled",
                "Completed",
                "Cancelled",
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => selectedStatus = v!),
            ),
          ),
        ),
      ],
    );
  }

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
            _buildInterviewsTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInterviewSheet,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Add Interview",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recruitment - Interviews",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Manage candidate interviews and hiring status",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInterviewsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Interviews List",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.navy.withValues(alpha: 0.05),
                ),
                columnSpacing: 30,
                columns: [
                  _buildDataColumn("ID"),
                  _buildDataColumn("Name"),
                  _buildDataColumn("Email"),
                  _buildDataColumn("Apply For"),
                  _buildDataColumn("Int. Date"),
                  _buildDataColumn("Time"),
                  _buildDataColumn("Status"),
                  _buildDataColumn("Actions"),
                ],
                rows: interviews.map((intv) => _buildRow(intv)).toList(),
              ),
            ),
          ),
        ],
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

  DataRow _buildRow(Map<String, dynamic> intv) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            intv['id'],
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Text(
            intv['name'],
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(Text(intv['email'], style: GoogleFonts.inter(fontSize: 12))),
        DataCell(
          Text(
            intv['applyFor'],
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Text(intv['interviewDate'], style: GoogleFonts.inter(fontSize: 12)),
        ),
        DataCell(Text(intv['time'], style: GoogleFonts.inter(fontSize: 12))),
        DataCell(_buildStatusBadge(intv['status'])),
        DataCell(
          Row(
            children: [
              _buildActionIcon(
                Icons.visibility_outlined,
                AppColors.info,
                "View",
              ),
              const SizedBox(width: 8),
              _buildActionIcon(Icons.edit_outlined, AppColors.goldDark, "Edit"),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.delete_outline_rounded,
                AppColors.error,
                "Delete",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.navy;
    if (status == "Scheduled") color = AppColors.info;
    if (status == "Completed") color = AppColors.success;
    if (status == "Cancelled") color = AppColors.error;
    if (status == "Pending") color = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, String tooltip) {
    return InkWell(
      onTap: () {},
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
