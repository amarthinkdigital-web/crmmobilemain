import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class TeamPendingApprovalsScreen extends StatefulWidget {
  const TeamPendingApprovalsScreen({super.key});

  @override
  State<TeamPendingApprovalsScreen> createState() =>
      _TeamPendingApprovalsScreenState();
}

class _TeamPendingApprovalsScreenState
    extends State<TeamPendingApprovalsScreen> {
  List<Map<String, dynamic>> _worksheets = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchPendingWorksheets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingWorksheets() async {
    setState(() => _isLoading = true);
    final params = <String, String>{};
    if (_searchController.text.isNotEmpty) {
      params['name'] = _searchController.text;
    }
    if (_selectedDate != null) {
      params['work_date'] = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
    final res = await ApiService.getTeamPendingWorksheets(
      name: params['name'],
      workDate: params['work_date'],
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['error'] == false) {
          _worksheets = List<Map<String, dynamic>>.from(res['data'] ?? []);
          _errorMessage = null;
        } else {
          _errorMessage = res['message'];
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredWorksheets {
    return _worksheets.where((ws) {
      if (_searchController.text.isNotEmpty) {
        final name =
            (ws['user']?['name'] ?? ws['user_name'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchController.text.toLowerCase())) return false;
      }
      if (_selectedDate != null) {
        final wd = ws['work_date']?.toString().substring(0, 10) ?? '';
        if (wd != DateFormat('yyyy-MM-dd').format(_selectedDate!)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredWorksheets;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _fetchPendingWorksheets,
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
          "Team Pending Approvals",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Review pending worksheets submitted by your team members",
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
        child: Row(
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            ElevatedButton.icon(
              onPressed: _fetchPendingWorksheets,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text("Search"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
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

  Widget _buildTableSection(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: AppColors.grey200),
              const SizedBox(height: 16),
              Text("No pending approvals found",
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
              _buildDataColumn("Date"),
              _buildDataColumn("Project"),
              _buildDataColumn("Work Done"),
              _buildDataColumn("Status"),
              _buildDataColumn("Priority"),
              _buildDataColumn("Action"),
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

  DataRow _buildRow(int srNo, Map<String, dynamic> log) {
    final String name =
        log['user']?['name'] ?? log['employee_name'] ?? 'N/A';
    final String date = log['work_date'] ?? '-';
    // Backend uses 'items' for multi-project worksheets
    final items = log['items'] as List? ?? log['projects'] as List? ?? [];
    String project;
    String work;
    if (items.isNotEmpty) {
      project = items.map((p) => p['project_name'] ?? p['project']?['name'] ?? '').where((n) => n.toString().isNotEmpty).join(', ');
      work = items.map((p) => p['todays_work']?.toString() ?? '').where((n) => n.isNotEmpty).join('; ');
    } else {
      project = log['project']?['name'] ?? log['project_name'] ?? 'N/A';
      work = log['todays_work'] ?? '-';
    }
    final String status = log['approval_status']?.toString() ?? log['status']?.toString() ?? 'Pending';
    final String priority = log['priority']?.toString() ?? 'Medium';

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
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy),
                ),
              ),
              const SizedBox(width: 8),
              Text(name,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
            ],
          ),
        ),
        DataCell(Text(date,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.grey600))),
        DataCell(Text(project,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600))),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(work,
                style: GoogleFonts.inter(fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
          ),
        ),
        DataCell(_buildBadge(status, _getStatusColor(status))),
        DataCell(_buildBadge(priority, _getPriorityColor(priority))),
        DataCell(
          _buildReviewButton(log),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains("completed") || status.contains("done")) {
      return AppColors.success;
    }
    if (status.contains("progress")) return AppColors.info;
    if (status.contains("hold")) return Colors.orange;
    if (status.contains("cancel")) return AppColors.error;
    return AppColors.warning;
  }

  Color _getPriorityColor(String priority) {
    priority = priority.toLowerCase();
    if (priority.contains("high") ||
        priority.contains("urgent") ||
        priority.contains("critical")) return AppColors.error;
    if (priority.contains("medium")) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildReviewButton(Map<String, dynamic> log) {
    return InkWell(
      onTap: () => _showReviewDialog(log),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rate_review_outlined,
                size: 14, color: AppColors.white),
            const SizedBox(width: 4),
            Text("Review",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white)),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> log) {
    String selectedApproval = "approved";
    final pointsController = TextEditingController();
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text("Review Worksheet",
              style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewDetail("Employee",
                    log['user']?['name'] ?? log['employee_name'] ?? 'N/A'),
                _buildReviewDetail("Project",
                    log['project']?['name'] ?? log['project_name'] ?? 'N/A'),
                _buildReviewDetail("Date", log['work_date'] ?? '-'),
                _buildReviewDetail("Work Done",
                    log['todays_work'] ?? '-'),
                const Divider(height: 24),
                const Text("Approval Status",
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _choiceChip("approved", "approve",
                          selectedApproval, (v) {
                        setModalState(() => selectedApproval = v);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choiceChip("rejected", "reject",
                          selectedApproval, (v) {
                        setModalState(() => selectedApproval = v);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: "Points (0-10)",
                    hintText: "e.g. 8.5",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: "Leader Comment (optional)",
                    hintText: "Add your feedback...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setModalState(() => isSubmitting = true);
                      final body = {
                        'approval_status': selectedApproval,
                        'points': double.tryParse(pointsController.text) ?? 0,
                        if (commentController.text.isNotEmpty)
                          'leader_comment': commentController.text,
                      };
                      final res = await ApiService.reviewTeamWorksheet(
                          log['id'], body);
                      if (mounted) {
                        Navigator.pop(ctx);
                        if (res['error'] == false) {
                          _fetchPendingWorksheets();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Review submitted successfully"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  res['message'] ?? "Failed to submit review"),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text("Submit Review"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey400)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(String value, String label, String selected,
      ValueChanged<String> onSelected) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            value == 'approved'
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 16,
            color: isSelected
                ? Colors.white
                : (value == 'approved'
                    ? AppColors.success
                    : AppColors.error),
          ),
          const SizedBox(width: 6),
          Text(label[0].toUpperCase() + label.substring(1)),
        ],
      ),
      selected: isSelected,
      selectedColor: value == 'approved' ? AppColors.success : AppColors.error,
      backgroundColor: AppColors.offWhite,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.navy,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => onSelected(value),
    );
  }
}
