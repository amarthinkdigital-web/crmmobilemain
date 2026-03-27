import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class AttendanceCorrectionsScreen extends StatefulWidget {
  const AttendanceCorrectionsScreen({super.key});

  @override
  State<AttendanceCorrectionsScreen> createState() => _AttendanceCorrectionsScreenState();
}

class _AttendanceCorrectionsScreenState extends State<AttendanceCorrectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();
  List<dynamic> _pendingRequests = [];
  List<dynamic> _historyRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getAdminCorrections(status: 'pending');
    final historyRes = await ApiService.getAdminCorrections(status: 'approved'); 
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['error'] == false) {
          _pendingRequests = res['data'] ?? [];
        }
        if (historyRes['error'] == false) {
          _historyRequests = historyRes['data'] ?? [];
        }
      });
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    final remark = await _showRemarkDialog(status);
    if (remark == null) return;

    setState(() => _isLoading = true);
    final res = await ApiService.updateCorrectionStatus(id, status, remark);
    if (res['error'] == false) {
      _showToast(res['message'] ?? "Request $status successfully!");
      _fetchData();
    } else {
      _showToast(res['message'] ?? "Failed to update status", isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showRemarkDialog(String status) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Admin Remark ($status)", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter reason or remark..."),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text), 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text("Regulation Requests", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.navy,
          indicatorColor: AppColors.gold,
          unselectedLabelColor: AppColors.grey400,
          tabs: const [
            Tab(text: "To Approve"),
            Tab(text: "All History"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(_pendingRequests, true),
              _buildRequestList(_historyRequests, false),
            ],
          ),
    );
  }

  Widget _buildRequestList(List<dynamic> list, bool isPending) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_rounded, size: 64, color: AppColors.grey200),
            const SizedBox(height: 16),
            Text("No requests found", style: GoogleFonts.inter(fontSize: 16, color: AppColors.grey400, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final req = list[index];
        return _buildRequestCard(req, isPending);
      },
    );
  }

  Widget _buildRequestCard(dynamic req, bool isPending) {
    final status = req['status'] ?? 'pending';
    Color statusColor = AppColors.warning;
    if (status == 'approved') statusColor = AppColors.success;
    if (status == 'rejected') statusColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
              child: Text(
                (req['id']?.toString() ?? 'R').substring(0, 1),
                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Request #${req['id']}", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy)),
                  Text(DateFormat('E, MMM dd, yyyy').format(DateTime.parse(req['date']).toLocal()), style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10)),
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
                    _buildInfoColumn("CLOCK IN", req['clock_in'] ?? "--:--"),
                    _buildInfoColumn("CLOCK OUT", req['clock_out'] ?? "--:--"),
                    _buildInfoColumn("APPLIED ON", req['created_at'] != null ? DateFormat('MMM dd, hh:mm A').format(DateTime.parse(req['created_at']!).toLocal()) : "N/A"),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Reason:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey600)),
                const SizedBox(height: 4),
                Text(req['reason'] ?? "No reason provided", style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy)),
                if (req['admin_remark'] != null && req['admin_remark'] != '-') ...[
                  const SizedBox(height: 12),
                  Text("Admin Remark:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey600)),
                  Text(req['admin_remark'], style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy, fontStyle: FontStyle.italic)),
                ],
                if (isPending) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(req['id'], 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(req['id'], 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.grey400)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
      ],
    );
  }
}
