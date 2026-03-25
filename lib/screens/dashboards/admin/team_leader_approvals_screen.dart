import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class TeamLeaderApprovalsScreen extends StatefulWidget {
  const TeamLeaderApprovalsScreen({super.key});

  @override
  State<TeamLeaderApprovalsScreen> createState() =>
      _TeamLeaderApprovalsScreenState();
}

class _TeamLeaderApprovalsScreenState extends State<TeamLeaderApprovalsScreen> {
  String selectedProject = "All Projects";
  String selectedStatus = "All Status";
  DateTime? selectedDate;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> _approvalRequests = [];
  bool _isLoading = true;

  List<String> projects = ["All Projects"];
  final List<String> statuses = [
    "All Status",
    "Pending",
    "Approved",
    "Rejected",
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _fetchRequests();
  }

  Future<void> _loadProjects({List<dynamic>? fallbackData}) async {
    final res = await ApiService.getProjects(fallbackData: fallbackData);
    if (res['error'] == false && res['data'] is List) {
      if (mounted) {
        setState(() {
          final List<dynamic> data = res['data'];
          final Set<String> names = {"All Projects"};
          for (var item in data) {
            final name = item['name']?.toString() ?? item['project_name']?.toString();
            if (name != null) names.add(name);
          }
          projects = names.toList()..sort((a, b) => a == "All Projects" ? -1 : a.compareTo(b));
          
          if (!projects.contains(selectedProject)) {
            selectedProject = "All Projects";
          }
        });
      }
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getAdminTeamApprovals();
    if (mounted) {
      setState(() {
        if (res['error'] == false) {
          _approvalRequests = List<Map<String, dynamic>>.from(res['data']);
          // After fetching, try to refresh projects from this data
          _loadProjects(fallbackData: _approvalRequests);
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _approvalRequests.where((req) {
      final query = searchController.text.toLowerCase();
      final emp = (req['user']?['name'] ?? req['user_name'] ?? req['employee'] ?? req['employee_name'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty && !emp.contains(query)) return false;

      if (selectedProject != "All Projects") {
        final proj = (req['project']?['name'] ?? req['project_name'] ?? req['project'] ?? '').toString();
        if (proj != selectedProject) return false;
      }

      if (selectedStatus != "All Status") {
        final status = (req['status'] ?? 'Pending').toString().toLowerCase();
        if (!status.contains(selectedStatus.toLowerCase())) return false;
      }

      if (selectedDate != null) {
        final dateStr = (req['work_date'] ?? req['workDate'] ?? req['date'] ?? '').toString();
        final reqDate = DateTime.tryParse(dateStr);
        if (reqDate != null) {
          if (reqDate.year != selectedDate!.year || 
              reqDate.month != selectedDate!.month || 
              reqDate.day != selectedDate!.day) return false;
        }
      }

      return true;
    }).toList();

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
              : filtered.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Text("No approval requests found", style: GoogleFonts.inter(color: AppColors.grey400))))
                  : _buildApprovalsTable(filtered),
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
          "Team Leader Approvals",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Review and approve project tasks submitted by team leaders",
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
            TextField(
              controller: searchController,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search employee by name...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => searchController.clear()),
                    )
                  : null,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDatePicker()),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    selectedProject,
                    projects,
                    (v) => setState(() => selectedProject = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    selectedStatus,
                    statuses,
                    (v) => setState(() => selectedStatus = v!),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedProject = "All Projects";
                      selectedStatus = "All Status";
                      selectedDate = null;
                      searchController.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.grey200),
                  ),
                  child: const Text("Clear"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Update filtering by triggering a rebuild
                    setState(() {});
                    // Also optionally re-fetch to see if new data arrived
                    _fetchRequests();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Search"),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) setState(() => selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: AppColors.navy,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedDate == null
                    ? "Work Date"
                    : DateFormat('dd MMM, yyyy').format(selectedDate!),
                style: GoogleFonts.inter(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsTable(List<Map<String, dynamic>> requests) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.navy.withValues(alpha: 0.05),
            ),
            columnSpacing: 30,
            columns: [
              _buildDataColumn("Employee"),
              _buildDataColumn("Work Date"),
              _buildDataColumn("Project"),
              _buildDataColumn("Leader"),
              _buildDataColumn("Points"),
              _buildDataColumn("Status"),
              _buildDataColumn("Action"),
            ],
            rows: requests.map((req) => _buildRow(req)).toList(),
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
    String employee = req['user']?['name'] ?? req['user_name'] ?? req['employee'] ?? req['employee_name'] ?? 'N/A';
    String workDate = req['work_date'] ?? req['workDate'] ?? req['date'] ?? '-';
    String project = req['project']?['name'] ?? req['project_name'] ?? (req['project'] is String ? req['project'] : 'N/A');
    String leader = req['leader']?['name'] ?? req['leader_name'] ?? req['leader'] ?? req['team_leader'] ?? req['manager_name'] ?? 'N/A';
    String status = req['status']?.toString() ?? 'Pending';
    String points = req['points']?.toString() ?? '0';
    
    final statusColor = _getStatusColor(status);

    return DataRow(
      cells: [
        DataCell(
          Text(
            employee,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            workDate,
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
        DataCell(
          Text(
            leader,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              if (status == 'Pending') ...[
                _buildCompactButton(
                  Icons.check_circle_outline_rounded,
                  AppColors.success,
                  () => _reviewRequest(req, 'Approved'),
                ),
                const SizedBox(width: 8),
                _buildCompactButton(
                  Icons.cancel_outlined,
                  AppColors.error,
                  () => _reviewRequest(req, 'Rejected'),
                ),
                const SizedBox(width: 8),
              ],
                _buildCompactButton(
                  Icons.visibility_outlined,
                  AppColors.navy,
                  () => _showViewDialog(req),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _reviewRequest(Map<String, dynamic> req, String status) async {
    int id = req['id'] ?? 0;
    final res = await ApiService.reviewTeamWorksheet(id, {'status': status});
    if (mounted) {
      if (res['error'] == false) {
        _fetchRequests();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request $status"), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: AppColors.error));
      }
    }
  }

  void _showViewDialog(Map<String, dynamic> req) {
    String employee = req['user']?['name'] ?? req['user_name'] ?? req['employee'] ?? req['employee_name'] ?? 'N/A';
    String workDate = req['work_date'] ?? req['workDate'] ?? req['date'] ?? '-';
    String project = req['project']?['name'] ?? req['project_name'] ?? (req['project'] is String ? req['project'] : 'N/A');
    String leader = req['leader']?['name'] ?? req['leader_name'] ?? req['leader'] ?? req['team_leader'] ?? req['manager_name'] ?? 'N/A';
    String status = req['status']?.toString() ?? 'Pending';
    String points = req['points']?.toString() ?? '0';
    String workDone = req['todays_work'] ?? req['work_done'] ?? req['description'] ?? '-';
    String nextStep = req['next_step'] ?? '-';
    String priority = req['priority']?.toString() ?? '-';
    String remark = req['remark'] ?? req['review_comment'] ?? req['comment'] ?? '-';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Approval Request Details", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem("Employee", employee),
              _buildDetailItem("Work Date", workDate),
              _buildDetailItem("Project", project),
              _buildDetailItem("Leader / Reporting Manager", leader),
              _buildDetailItem("Status", status),
              _buildDetailItem("Points Awarded", points),
              _buildDetailItem("Work Done", workDone, isMultiLine: true),
              _buildDetailItem("Next Step", nextStep, isMultiLine: true),
              _buildDetailItem("Priority", priority),
              _buildDetailItem("Review Remarks", remark, isMultiLine: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey400)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
          if (isMultiLine) const Divider(height: 20, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildCompactButton(IconData icon, Color color, VoidCallback onTap) {
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

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('approved')) return AppColors.success;
    if (status.contains('rejected')) return AppColors.error;
    return AppColors.warning; // Pending
  }
}
