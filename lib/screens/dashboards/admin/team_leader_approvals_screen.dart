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
  String selectedStatus = "All Status";
  DateTime? selectedDate;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> _leaveRequests = [];
  bool _isLoading = true;

  final List<String> statuses = [
    "All Status",
    "Pending",
    "Approved",
    "Rejected",
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getAdminManagerLeaveRequests(),
      ApiService.getAdminEmployeeLeaveRequests(),
    ]);

    if (mounted) {
      setState(() {
        _leaveRequests.clear();
        if (results[0]['error'] == false) {
          final List<dynamic> mgrData = results[0]['data'];
          _leaveRequests.addAll(mgrData.map((e) => {...Map<String, dynamic>.from(e), 'source_type': 'manager'}).toList());
        }
        if (results[1]['error'] == false) {
          final List<dynamic> empData = results[1]['data'];
          _leaveRequests.addAll(empData.map((e) => {...Map<String, dynamic>.from(e), 'source_type': 'employee'}).toList());
        }
        
        // Sort descending to show newest requests first
        _leaveRequests.sort((a, b) {
            final int idA = int.tryParse((a['id'] ?? '0').toString()) ?? 0;
            final int idB = int.tryParse((b['id'] ?? '0').toString()) ?? 0;
            return idB.compareTo(idA);
        });
        
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _leaveRequests.where((req) {
      // Management only Leave check
      final userObj = req['user'] ?? req['employee'] ?? req['staff'] ?? {};
      final String roleStr = (userObj is Map
              ? (userObj['role'] ??
                  userObj['designation'] ??
                  userObj['role_name'] ??
                  userObj['position'] ??
                  '')
              : '').toString().toLowerCase();

      // Only HR/Managers
      final bool isMgmt = roleStr.contains('hr') || roleStr.contains('manager');
      if (!isMgmt) return false;

      final query = searchController.text.toLowerCase();
      final emp = (req['user_name'] ?? req['employee_name'] ?? req['user']?['name'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty && !emp.contains(query)) return false;

      if (selectedStatus != "All Status") {
        final status = (req['status'] ?? 'Pending').toString().toLowerCase();
        if (!status.contains(selectedStatus.toLowerCase())) return false;
      }

      if (selectedDate != null) {
        final start = DateTime.tryParse(req['start_date'] ?? '');
        final end = DateTime.tryParse(req['end_date'] ?? '');
        if (start != null && end != null) {
           final bool within = (selectedDate!.isAfter(start) || selectedDate!.isAtSameMomentAs(start)) &&
                               (selectedDate!.isBefore(end) || selectedDate!.isAtSameMomentAs(end));
           if (!within) return false;
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
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState("No management leave requests found")
                    : _buildLeavesTable(filtered),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(msg,
            style: GoogleFonts.inter(color: AppColors.grey400, fontSize: 13)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Team Approvals",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Review management time-off requests",
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
                hintText: "Search management user...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.offWhite,
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
                    selectedStatus,
                    statuses,
                    (v) => setState(() => selectedStatus = v!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeavesTable(List<Map<String, dynamic>> requests) {
    return Container(
      decoration: _tableDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.navy.withValues(alpha: 0.05)),
            columns: [
              _buildDataColumn("Requester"),
              _buildDataColumn("Start Date"),
              _buildDataColumn("End Date"),
              _buildDataColumn("Type"),
              _buildDataColumn("Status"),
              _buildDataColumn("Action"),
            ],
            rows: requests.map((req) => _buildLeaveRow(req)).toList(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _tableDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.grey200),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
    );
  }

  DataRow _buildLeaveRow(Map<String, dynamic> req) {
    final status = (req['status'] ?? 'Pending').toString();
    return DataRow(cells: [
      DataCell(Text(req['user_name'] ?? req['employee_name'] ?? req['user']?['name'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
      DataCell(Text(req['start_date'] ?? 'N/A')),
      DataCell(Text(req['end_date'] ?? 'N/A')),
      DataCell(Text((req['leave_type'] ?? 'N/A').toString().toUpperCase())),
      DataCell(_buildStatusBadge(status)),
      DataCell(_buildActions(req)),
    ]);
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildActions(Map<String, dynamic> req) {
    final status = (req['status'] ?? 'Pending').toString().toLowerCase();
    return Row(
      children: [
        if (status.contains('pending')) ...[
           _buildCompactButton(Icons.check_circle_outline, AppColors.success, () => _handleReview(req, 'Approved')),
           const SizedBox(width: 8),
           _buildCompactButton(Icons.cancel_outlined, AppColors.error, () => _handleReview(req, 'Rejected')),
        ],
        const SizedBox(width: 8),
        _buildCompactButton(Icons.visibility_outlined, AppColors.navy, () => _showLeaveDetail(req)),
      ],
    );
  }

  Future<void> _handleReview(Map<String, dynamic> req, String status) async {
    final id = req['id'] ?? 0;
    final isEmployee = req['source_type'] == 'employee';
    final leaveType = (req['leave_type'] ?? 'paid').toString();
    
    final res = isEmployee
        ? await ApiService.setEmployeeLeaveStatus(id, status, leaveType: leaveType, isAdmin: true)
        : await ApiService.setAdminManagerLeaveStatus(id, status);
    
    if (mounted) {
      if (res['error'] == false) {
        _fetchRequests();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request $status successfully"), backgroundColor: AppColors.success));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: AppColors.error));
      }
    }
  }

  void _showLeaveDetail(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Request Detail"),
        content: Text(req['reason'] ?? 'No reason provided'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
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
            const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.navy),
            const SizedBox(width: 8),
            Text(selectedDate == null ? "Select Date" : DateFormat('dd MMM, yyyy').format(selectedDate!),
                 style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey100)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged, isExpanded: true, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
        ),
      ),
    );
  }

  Widget _buildCompactButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)));
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('approved')) return AppColors.success;
    if (status.contains('rejected')) return AppColors.error;
    return AppColors.warning;
  }
}
