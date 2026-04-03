import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class ManagerTeamLeavesScreen extends StatefulWidget {
  const ManagerTeamLeavesScreen({super.key});

  @override
  State<ManagerTeamLeavesScreen> createState() => _ManagerTeamLeavesScreenState();
}

class _ManagerTeamLeavesScreenState extends State<ManagerTeamLeavesScreen> {
  List<dynamic> _teamLeaves = [];
  bool _isLoading = true;
  String _userRole = 'manager';

  @override
  void initState() {
    super.initState();
    _loadRoleAndData();
  }

  Future<void> _loadRoleAndData() async {
    _userRole = (await AuthService.getUserRole() ?? 'manager').toLowerCase();
    _fetchTeamLeaves();
  }

  Future<void> _fetchTeamLeaves() async {
    setState(() => _isLoading = true);
    
    // Choose API based on role: HR/Admin reviews all vs Team Leader / Manager reviews subordinates
    Map<String, dynamic> res;
    if (_userRole == 'hr' || _userRole == 'admin') {
      res = await ApiService.getAllEmployeeLeaveRequests();
    } else {
      res = await ApiService.getManagerTeamLeaves();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['error'] == false) {
          _teamLeaves = res['data'] ?? [];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Failed to load leaves'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  Future<void> _updateStatus(int id, String status, {String? reason}) async {
    setState(() => _isLoading = true);
    
    final res = _userRole == 'hr'
        ? await ApiService.setEmployeeLeaveStatus(id, status, reason: reason, isAdmin: false) // HR Panel
        : await ApiService.setManagerTeamLeaveStatus(id, status, reason: reason);            // TL Panel
        
    if (mounted) {
      if (res['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave $status successfully!')),
        );
        _fetchTeamLeaves();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to update leave status')),
        );
      }
    }
  }

  bool _hasPaidLeaveThisMonth(Map<String, dynamic> req) {
    // Only check for HR reviewing regular employees
    if (_userRole != 'hr') return false;

    final userId = req['employee']?['id'] ?? req['user']?['id'] ?? req['user_id'] ?? req['employee_id'];
    if (userId == null) return false;

    final startDateStr = req['start_date']?.toString();
    if (startDateStr == null || startDateStr == '-') return false;

    try {
      final startDate = DateTime.parse(startDateStr).toLocal();
      for (var r in _teamLeaves) {
        if (r['id'] == req['id']) continue;
        final rUserId = r['employee']?['id'] ?? r['user']?['id'] ?? r['user_id'] ?? r['employee_id'];
        if (rUserId != userId) continue;

        final status = (r['status'] ?? '').toString().toLowerCase();
        final type = (r['leave_type'] ?? '').toString().toLowerCase();
        if (status.contains('approved') && type.contains('paid')) {
          final rDate = DateTime.parse(r['start_date']).toLocal();
          if (rDate.month == startDate.month && rDate.year == startDate.year) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  void _showApproveDialog(int id, String initialType, Map<String, dynamic> req) {
    String selectedType = initialType.toLowerCase().contains('unpaid') ? 'Unpaid' : 'Paid';
    bool hasPaidAlready = _hasPaidLeaveThisMonth(req);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            "Approve Leave",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPaidAlready) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "This user has already taken a paid leave this month.",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                "Select Leave Type:",
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ["Paid", "Unpaid"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.inter(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppColors.grey600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(id, 'Approved $selectedType');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text("APPROVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(int id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reject Leave", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter rejection reason..."),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, 'Rejected', reason: controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : RefreshIndicator(
              onRefresh: _fetchTeamLeaves,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    if (_teamLeaves.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _teamLeaves.length,
                        itemBuilder: (context, index) {
                          return _buildLeaveCard(_teamLeaves[index]);
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    String roleLabel = _userRole == 'hr' ? 'HR Panel' : (_userRole[0].toUpperCase() + _userRole.substring(1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Employee Approvals",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Managing $roleLabel review panel for staff leaves",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.beach_access_rounded, size: 64, color: AppColors.grey200),
          const SizedBox(height: 16),
          Text(
            "No pending leave requests for this panel",
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(dynamic leave) {
    final status = (leave['status'] ?? 'Pending').toString();
    final isPending = status.toLowerCase() == 'pending';
    
    Color statusColor = AppColors.warning;
    if (status.toLowerCase().contains('approve')) statusColor = AppColors.success;
    if (status.toLowerCase().contains('reject')) statusColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
              child: Text(
                _getDisplayName(leave)[0].toUpperCase(),
                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayName(leave),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  Text(
                    "${leave['start_date'] ?? '-'} to ${leave['end_date'] ?? '-'}",
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem("Leave Type", leave['leave_type'] ?? 'Leave'),
                    _buildInfoItem("Days", _calculateDays(leave['start_date'], leave['end_date'])),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Reason:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey400)),
                const SizedBox(height: 4),
                Text(leave['reason'] ?? 'No reason provided', style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy)),
                if (isPending) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRejectDialog(leave['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_userRole == 'hr') {
                              _showApproveDialog(leave['id'], leave['leave_type'] ?? 'paid', leave);
                            } else {
                              _updateStatus(leave['id'], 'Approved');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("APPROVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy, fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _getDisplayName(dynamic leave) {
    if (leave is! Map) return 'Unknown';
    final e = leave['employee'] ?? leave['user'] ?? leave['staff'] ?? leave['requester'] ?? leave['requested_by'];
    if (e is Map) {
      return e['name'] ?? e['full_name'] ?? e['user_name'] ?? e['first_name'] ?? 'Unknown';
    }
    return leave['employee_name'] ?? leave['name'] ?? leave['user_name'] ?? e?.toString() ?? 'U';
  }

  String _calculateDays(String? start, String? end) {
    if (start == null || end == null) return "1";
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      return (e.difference(s).inDays + 1).toString();
    } catch (_) {
      return "1";
    }
  }
}
