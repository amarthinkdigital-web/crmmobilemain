import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class AllDailyWorksheetsScreen extends StatefulWidget {
  const AllDailyWorksheetsScreen({super.key});

  @override
  State<AllDailyWorksheetsScreen> createState() =>
      _AllDailyWorksheetsScreenState();
}

class _AllDailyWorksheetsScreenState extends State<AllDailyWorksheetsScreen> {
  String selectedProject = "All Projects";
  String selectedPriority = "All Priorities";
  DateTime? selectedDate = DateTime.now();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> _allWorksheets = [];
  bool _isLoading = true;

  final List<String> projects = [
    "All Projects",
    "CRM Development",
    "Marketing Campaign",
    "Mobile App",
    "Infrastructure",
  ];
  final List<String> priorities = [
    "All Priorities",
    "High",
    "Medium",
    "Low",
    "Urgent",
  ];

  @override
  void initState() {
    super.initState();
    _fetchWorksheets();
  }

  Future<void> _fetchWorksheets() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getAdminDailyWorksheets();
    if (mounted) {
      setState(() {
        if (res['error'] == false) {
          _allWorksheets = List<Map<String, dynamic>>.from(res['data']);
        }
        _isLoading = false;
      });
      if (res['error'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to load worksheets'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupWorksheetsByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var ws in _allWorksheets) {
      String date = ws['work_date'] ?? ws['workdate'] ?? 'Unknown';
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(ws);
    }
    
    // Sort keys (dates) descending
    var sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    Map<String, List<Map<String, dynamic>>> sortedGrouped = {};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    return sortedGrouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedLogs = _groupWorksheetsByDate();

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
            _isLoading 
              ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              : groupedLogs.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Text("No worksheets found", style: GoogleFonts.inter(color: AppColors.grey400))))
                  : Column(
                      children: groupedLogs.entries.map(
                        (entry) => _buildDailyTableSection(entry.key, entry.value),
                      ).toList(),
                    ),
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
          "All Daily Worksheets",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Monitor daily productivity and task updates across all teams",
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.grey100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: searchController,
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Search employee name...",
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.offWhite,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildDatePicker()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    selectedProject,
                    projects,
                    (v) => setState(() => selectedProject = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    selectedPriority,
                    priorities,
                    (v) => setState(() => selectedPriority = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedProject = "All Projects";
                      selectedPriority = "All Priorities";
                      selectedDate = DateTime.now();
                      searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("Reset"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.grey200),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _fetchWorksheets,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text("Search"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          style: GoogleFonts.inter(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) setState(() => selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.navy,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedDate == null
                    ? "Select Date"
                    : DateFormat('dd MMM, yyyy (EEEE)').format(selectedDate!),
                style: GoogleFonts.inter(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTableSection(
    String dateStr,
    List<Map<String, dynamic>> logs,
  ) {
    DateTime date;
    try {
      date = DateTime.parse(dateStr).toLocal();
    } catch (e) {
      date = DateTime.now();
    }
    final String formattedDate = DateFormat('dd MMMM, yyyy').format(date);
    final String dayName = DateFormat('EEEE').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              const Icon(
                Icons.history_toggle_off_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "$formattedDate - $dayName",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
        Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.navy.withValues(alpha: 0.05),
                ),
                columnSpacing: 40,
                columns: [
                  _buildDataColumn("Sr. No."),
                  _buildDataColumn("User"),
                  _buildDataColumn("Role"),
                  _buildDataColumn("Project"),
                  _buildDataColumn("Status"),
                  _buildDataColumn("Leader"),
                  _buildDataColumn("Points"),
                  _buildDataColumn("Actions"),
                ],
                rows: logs.asMap().entries.map((entry) {
                   final idx = entry.key;
                   final log = entry.value;
                   return _buildRow(idx + 1, log);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
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

  DataRow _buildRow(int srNo, Map<String, dynamic> log) {
    String userName = log['user']?['name'] ?? log['user_name'] ?? log['user'] ?? 'N/A';
    String userRole = log['user']?['role'] ?? log['role'] ?? 'N/A';
    String project = log['project']?['name'] ?? log['project_name'] ?? log['project'] ?? 'N/A';
    String status = log['status']?.toString() ?? 'Pending';
    String leader = log['leader']?['name'] ?? log['leader_name'] ?? log['leader'] ?? 'N/A';
    String points = log['points']?.toString() ?? '-';

    return DataRow(
      cells: [
        DataCell(
          Text(srNo.toString(), style: GoogleFonts.inter(fontSize: 13)),
        ),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                child: Text(
                  userName.isNotEmpty ? userName[0] : '?',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                userName,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            userRole,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(
            project,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(_buildStatusBadge(status)),
        DataCell(
          Text(
            leader,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "$points pts",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.goldDark,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildCompactButton(
                "View",
                Icons.visibility_outlined,
                AppColors.navy,
                () => _showViewDialog(log),
              ),
              const SizedBox(width: 8),
              _buildCompactButton(
                "Review",
                Icons.rate_review_outlined,
                AppColors.success,
                () {
                   _showReviewDialog(log);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReviewDialog(Map<String, dynamic> log) {
    final pointsController = TextEditingController(text: log['points']?.toString() ?? '');
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Review Worksheet", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(labelText: "Points Awarded"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: "Review Comment"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              int id = log['id'] ?? 0;
              final res = await ApiService.reviewAdminWorksheet(id, {
                'points': int.tryParse(pointsController.text) ?? 0,
                'comment': commentController.text,
              });
              if (mounted) {
                Navigator.pop(context);
                if (res['error'] == false) {
                  _fetchWorksheets();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted"), backgroundColor: AppColors.success));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Worksheet Details",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(
                  "User", log['user']?['name'] ?? log['user_name'] ?? 'N/A'),
              _buildDetailItem(
                  "Role", log['user']?['role'] ?? log['role'] ?? 'N/A'),
              _buildDetailItem("Project",
                  log['project']?['name'] ?? log['project_name'] ?? 'N/A'),
              _buildDetailItem("Work Date", log['work_date'] ?? '-'),
              _buildDetailItem("Work Done", log['todays_work'] ?? '-',
                  isMultiLine: true),
              _buildDetailItem("Status", log['status']?.toString() ?? 'Pending'),
              _buildDetailItem(
                  "Priority", log['priority']?.toString() ?? 'Medium'),
              _buildDetailItem("Next Step", log['next_step'] ?? '-',
                  isMultiLine: true),
              if (log['review_comment'] != null)
                _buildDetailItem("Review Comment", log['review_comment'],
                    isMultiLine: true),
              _buildDetailItem("Points", log['points']?.toString() ?? '0'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value,
      {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey400)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.info;
    String s = status.toLowerCase();
    if (s.contains("completed")) color = AppColors.success;
    if (s.contains("pending")) color = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
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

  Widget _buildCompactButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
