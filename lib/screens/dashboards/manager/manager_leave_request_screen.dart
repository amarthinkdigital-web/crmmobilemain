import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class ManagerLeaveRequestScreen extends StatefulWidget {
  const ManagerLeaveRequestScreen({super.key});

  @override
  State<ManagerLeaveRequestScreen> createState() =>
      _ManagerLeaveRequestScreenState();
}

class _ManagerLeaveRequestScreenState extends State<ManagerLeaveRequestScreen> {
  final List<Map<String, dynamic>> _leaveApplications = [
    {
      'srNo': 1,
      'startDate': '2026-03-20',
      'endDate': '2026-03-22',
      'type': 'Vacation',
      'status': 'Pending',
      'reason': 'Family trip out of town',
    },
    {
      'srNo': 2,
      'startDate': '2026-02-14',
      'endDate': '2026-02-14',
      'type': 'Casual Leave',
      'status': 'Approved',
      'reason': 'Personal errands',
    },
    {
      'srNo': 3,
      'startDate': '2026-01-22',
      'endDate': '2026-01-24',
      'type': 'Sick Leave',
      'status': 'Approved',
      'reason': 'Viral fever recovery',
    },
  ];

  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  String selectedType = 'Sick Leave';

  void _showAddLeaveSheet() {
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
                    "Apply for Leave",
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
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      "Start Date",
                      "Select date",
                      startDateController,
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
                          startDateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      "End Date",
                      "Select date",
                      endDateController,
                      Icons.event_available_rounded,
                      isReadOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          endDateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTypeDropdown(),
              const SizedBox(height: 16),
              _buildInputField(
                "Reason",
                "Explain your leave",
                reasonController,
                Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _leaveApplications.insert(0, {
                        "srNo": _leaveApplications.length + 1,
                        "startDate": startDateController.text,
                        "endDate": endDateController.text,
                        "type": selectedType,
                        "status": "Pending",
                        "reason": reasonController.text,
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
                    "Submit Application",
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
    startDateController.clear();
    endDateController.clear();
    reasonController.clear();
    selectedType = 'Sick Leave';
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
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
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppColors.grey400, size: 20)
                : null,
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

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Leave Type",
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
              value: selectedType,
              isExpanded: true,
              items: [
                "Sick Leave",
                "Casual Leave",
                "Vacation",
                "Emergency Leave",
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => selectedType = v!),
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
            _buildLeavesTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLeaveSheet,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Apply Leave", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Apply for Leave",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Manage and track your leave applications",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLeavesTable() {
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
              "Leave Application List",
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
                columnSpacing: 25,
                columns: [
                  _buildDataColumn("Sr. No."),
                  _buildDataColumn("Start Date"),
                  _buildDataColumn("End Date"),
                  _buildDataColumn("Type"),
                  _buildDataColumn("Status"),
                  _buildDataColumn("Reason"),
                  _buildDataColumn("Action"),
                ],
                rows: _leaveApplications.map((l) => _buildRow(l)).toList(),
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

  DataRow _buildRow(Map<String, dynamic> l) {
    return DataRow(
      cells: [
        DataCell(
          Text(l['srNo'].toString(), style: GoogleFonts.inter(fontSize: 12)),
        ),
        DataCell(
          Text(
            l['startDate'],
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            l['endDate'],
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(_buildTypeBadge(l['type'])),
        DataCell(_buildStatusBadge(l['status'])),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              l['reason'],
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildActionIcon(
                Icons.visibility_outlined,
                AppColors.info,
                "View",
              ),
              if (l['status'] == 'Pending') ...[
                const SizedBox(width: 8),
                _buildActionIcon(
                  Icons.edit_outlined,
                  AppColors.goldDark,
                  "Edit",
                ),
                const SizedBox(width: 8),
                _buildActionIcon(
                  Icons.delete_outline_rounded,
                  AppColors.error,
                  "Delete",
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color = AppColors.navy;
    if (type == "Sick Leave") color = AppColors.error;
    if (type == "Vacation") color = AppColors.success;
    if (type == "Emergency Leave") color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.warning;
    if (status == "Approved") color = AppColors.success;
    if (status == "Rejected") color = AppColors.error;

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
