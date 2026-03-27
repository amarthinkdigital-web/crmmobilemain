import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class EmployeeLeavesScreen extends StatefulWidget {
  const EmployeeLeavesScreen({super.key});

  @override
  State<EmployeeLeavesScreen> createState() => _EmployeeLeavesScreenState();
}

class _EmployeeLeavesScreenState extends State<EmployeeLeavesScreen> {
  List<Map<String, dynamic>> _leaveRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getAllEmployeeLeaveRequests();
    if (!mounted) return;
    if (res['error'] == false) {
      setState(() {
        _leaveRequests = (res['data'] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to load leaves')),
      );
    }
  }

  Future<void> _updateStatus(int id, String status, String leaveType, {String? reason}) async {
    final res = await ApiService.setEmployeeLeaveStatus(id, status, leaveType: leaveType, reason: reason);
    if (!mounted) return;
    if (res['error'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave updated to $status')),
      );
      _fetchLeaves();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to update leave')),
      );
    }
  }

  int _getId(dynamic req) => req['id'] ?? 0;
  String _getName(dynamic req) => req['employee']?['name'] ?? req['user']?['name'] ?? 'Unknown';
  String _getRole(dynamic req) => req['employee']?['department']?['name'] ?? req['user']?['role'] ?? 'Staff';
  String _getStart(dynamic req) => req['start_date']?.toString() ?? '-';
  String _getEnd(dynamic req) => req['end_date']?.toString() ?? '-';
  String _getType(dynamic req) => req['leave_type'] ?? req['type'] ?? 'Leave';
  String _getStatus(dynamic req) => req['status'] ?? 'Pending';
  String _getReason(dynamic req) => req['reason'] ?? 'No reason provided';

  bool _hasPaidLeaveThisMonth(Map<String, dynamic> req) {
    final userId = req['employee']?['id'] ?? req['user']?['id'] ?? req['user_id'] ?? req['employee_id'];
    if (userId == null) return false;

    final startDateStr = req['start_date']?.toString();
    if (startDateStr == null || startDateStr == '-') return false;

    try {
      final startDate = DateTime.parse(startDateStr).toLocal();
      final month = startDate.month;
      final year = startDate.year;

      for (var r in _leaveRequests) {
        // Skip current request if it's already in the list
        if (r['id'] == req['id']) continue;

        final rUserId = r['employee']?['id'] ?? r['user']?['id'] ?? r['user_id'] ?? r['employee_id'];
        if (rUserId != userId) continue;

        final status = (r['status'] ?? '').toString().toLowerCase();
        if (status.contains('approved') && status.contains('paid')) {
          final rStartDateStr = r['start_date']?.toString();
          if (rStartDateStr != null && rStartDateStr != '-') {
            final rStartDate = DateTime.parse(rStartDateStr).toLocal();
            if (rStartDate.month == month && rStartDate.year == year) {
              return true;
            }
          }
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildLeaveRequestsTable(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Employee Leaves',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Manage and review staff time-off requests officially',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.grey400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _fetchLeaves,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveRequestsTable() {
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
              "Staff Leave Requests",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          if (_leaveRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "No leave requests found.",
                style: GoogleFonts.inter(color: AppColors.grey600),
              ),
            )
          else
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
                    _buildDataColumn("ID"),
                    _buildDataColumn("Staff Name"),
                    _buildDataColumn("Role"),
                    _buildDataColumn("Start"),
                    _buildDataColumn("End"),
                    _buildDataColumn("Type"),
                    _buildDataColumn("Status"),
                    _buildDataColumn("Reason"),
                    _buildDataColumn("Action"),
                  ],
                  rows: _leaveRequests.map((req) => _buildRow(req)).toList(),
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

  DataRow _buildRow(Map<String, dynamic> req) {
    return DataRow(
      cells: [
        DataCell(
          Text(_getId(req).toString(), style: GoogleFonts.inter(fontSize: 12)),
        ),
        DataCell(
          Text(
            _getName(req),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            _getRole(req),
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Text(_getStart(req), style: GoogleFonts.inter(fontSize: 12)),
        ),
        DataCell(Text(_getEnd(req), style: GoogleFonts.inter(fontSize: 12))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getType(req),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.goldDark,
              ),
            ),
          ),
        ),
        DataCell(_buildStatusBadge(_getStatus(req))),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              _getReason(req),
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          _getStatus(req).toLowerCase() == 'pending' 
          ? Row(
            children: [
              if (!_hasPaidLeaveThisMonth(req)) ...[
                _buildCompactActionButton(
                  "Paid", 
                  AppColors.success, 
                  () => _updateStatus(_getId(req), 'Approved Paid', _getType(req)),
                ),
                const SizedBox(width: 8),
              ],
              _buildCompactActionButton(
                "Unpaid", 
                AppColors.warning, 
                () => _updateStatus(_getId(req), 'Approved Unpaid', _getType(req)),
              ),
              const SizedBox(width: 8),
              _buildCompactActionButton(
                "Reject", 
                AppColors.error, 
                () => _showRejectDialog(_getId(req), _getType(req)),
              ),
            ],
          )
          : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showRejectDialog(int id, String leaveType) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Reject Leave",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please provide a reason for rejection:",
              style: GoogleFonts.inter(color: AppColors.grey600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter reason...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.navy),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: AppColors.grey600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, 'Rejected', leaveType, reason: reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.navy;
    final lower = status.toLowerCase();
    if (lower.contains("approved")) color = AppColors.success;
    if (lower.contains("pending")) color = AppColors.warning;
    if (lower.contains("reject")) color = AppColors.error;

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

  Widget _buildCompactActionButton(
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
