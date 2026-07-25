import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class TeamReviewedRecordsScreen extends StatefulWidget {
  const TeamReviewedRecordsScreen({super.key});

  @override
  State<TeamReviewedRecordsScreen> createState() =>
      _TeamReviewedRecordsScreenState();
}

class _TeamReviewedRecordsScreenState
    extends State<TeamReviewedRecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedApprovalStatus = "All";

  final List<String> _approvalStatuses = ["All", "approved", "rejected"];

  @override
  void initState() {
    super.initState();
    _fetchReviewedRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviewedRecords() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getTeamReviewedWorksheets();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['error'] == false) {
          _records = List<Map<String, dynamic>>.from(res['data'] ?? []);
          _errorMessage = null;
        } else {
          _errorMessage = res['message'];
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    return _records.where((rec) {
      if (_searchController.text.isNotEmpty) {
        final name = (rec['user']?['name'] ?? rec['user_name'] ?? '')
            .toString()
            .toLowerCase();
        if (!name.contains(_searchController.text.toLowerCase())) return false;
      }
      if (_selectedDate != null) {
        final wd = rec['work_date']?.toString().substring(0, 10) ?? '';
        if (wd != DateFormat('yyyy-MM-dd').format(_selectedDate!)) return false;
      }
      if (_selectedApprovalStatus != "All") {
        if ((rec['approval_status'] ?? '') != _selectedApprovalStatus) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _fetchReviewedRecords,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilterSection(),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(_errorMessage!,
                        style: GoogleFonts.inter(color: AppColors.error)),
                  ),
                )
              else
                _buildTableSection(filtered),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Team Reviewed Records",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Worksheets already reviewed by you",
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
                    controller: _searchController,
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Search employee name...",
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.offWhite,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildDatePicker(),
                const SizedBox(width: 12),
                _buildDropdown(
                  _selectedApprovalStatus,
                  _approvalStatuses,
                  (v) => setState(() => _selectedApprovalStatus = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedApprovalStatus = "All";
                      _selectedDate = null;
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("Reset"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.grey200),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _fetchReviewedRecords,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text("Search"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) setState(() => _selectedDate = date);
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
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.navy),
            const SizedBox(width: 8),
            Text(
              _selectedDate == null
                  ? "Select Date"
                  : DateFormat('dd MMM, yyyy').format(_selectedDate!),
              style: GoogleFonts.inter(
                color: _selectedDate == null
                    ? AppColors.grey400
                    : AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      width: 160,
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
              fontWeight: FontWeight.w600),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTableSection(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 64, color: AppColors.grey200),
              const SizedBox(height: 16),
              Text("No reviewed records found",
                  style: GoogleFonts.inter(color: AppColors.grey400)),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
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
            headingRowColor:
                WidgetStateProperty.all(AppColors.navy.withValues(alpha: 0.05)),
            columnSpacing: 40,
            columns: [
              _buildDataColumn("Sr. No."),
              _buildDataColumn("Employee"),
              _buildDataColumn("Project"),
              _buildDataColumn("Points"),
              _buildDataColumn("Approval"),
              _buildDataColumn("Date"),
              _buildDataColumn("Actions"),
            ],
            rows: data.asMap().entries.map((entry) {
              return _buildRow(entry.key + 1, entry.value);
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(label,
          style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
    );
  }

  DataRow _buildRow(int srNo, Map<String, dynamic> rec) {
    final String userName =
        rec['user']?['name'] ?? rec['user_name'] ?? 'N/A';
    // Backend uses 'items' for multi-project worksheets
    final items = rec['items'] as List? ?? rec['projects'] as List? ?? [];
    final String project;
    if (items.isNotEmpty) {
      project = items.map((p) => p['project_name'] ?? p['project']?['name'] ?? '').where((n) => n.toString().isNotEmpty).join(', ');
    } else {
      project = rec['project']?['name'] ?? rec['project_name'] ?? 'N/A';
    }
    final String points = rec['points']?.toString() ?? '-';
    final String approvalStatus =
        rec['approval_status']?.toString() ?? 'pending';
    final String workDate = rec['work_date']?.toString() ?? '-';

    return DataRow(
      cells: [
        DataCell(Text(srNo.toString(),
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600))),
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
                      color: AppColors.navy),
                ),
              ),
              const SizedBox(width: 8),
              Text(userName,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
            ],
          ),
        ),
        DataCell(Text(project,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text("$points pts",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldDark)),
          ),
        ),
        DataCell(_buildApprovalBadge(approvalStatus)),
        DataCell(Text(workDate,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.grey600))),
        DataCell(
          _buildCompactButton(
              "View", Icons.visibility_outlined, AppColors.navy, () {
            _showViewDialog(rec);
          }),
        ),
      ],
    );
  }

  Widget _buildApprovalBadge(String status) {
    Color color;
    String label;
    final s = status.toLowerCase();
    if (s == 'approved') {
      color = AppColors.success;
      label = 'Approved';
    } else if (s == 'rejected') {
      color = AppColors.error;
      label = 'Rejected';
    } else {
      color = AppColors.warning;
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            s == 'approved'
                ? Icons.check_circle
                : (s == 'rejected' ? Icons.cancel : Icons.schedule),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
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
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> rec) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Review Details",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(
                  "User", rec['user']?['name'] ?? rec['user_name'] ?? 'N/A'),
              _buildDetailItem("Project",
                  rec['project']?['name'] ?? rec['project_name'] ?? 'N/A'),
              _buildDetailItem("Work Date", rec['work_date'] ?? '-'),
              _buildDetailItem(
                  "Work Done", rec['todays_work'] ?? '-', isMultiLine: true),
              _buildDetailItem(
                  "Status", rec['status']?.toString() ?? 'Pending'),
              _buildDetailItem(
                  "Priority", rec['priority']?.toString() ?? 'Medium'),
              _buildDetailItem(
                  "Next Step", rec['next_step'] ?? '-', isMultiLine: true),
              const Divider(height: 24),
              _buildDetailItem(
                  "Approval Status", rec['approval_status']?.toString() ?? '-'),
              _buildDetailItem("Points", rec['points']?.toString() ?? '0'),
              _buildDetailItem("Reviewed By",
                  rec['approver']?['name'] ?? rec['approved_by_name'] ?? 'You'),
              if (rec['leader_comment'] != null &&
                  rec['leader_comment'].toString().isNotEmpty)
                _buildDetailItem("Review Comment",
                    rec['leader_comment'].toString(),
                    isMultiLine: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
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
}
