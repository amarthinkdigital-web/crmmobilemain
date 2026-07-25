import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class ManagerCorrectionsScreen extends StatefulWidget {
  const ManagerCorrectionsScreen({super.key});

  @override
  State<ManagerCorrectionsScreen> createState() => _ManagerCorrectionsScreenState();
}

class _ManagerCorrectionsScreenState extends State<ManagerCorrectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _clockIn = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _clockOut = const TimeOfDay(hour: 18, minute: 0);

  List<dynamic> _myRequests = [];
  List<dynamic> _teamRequests = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final myRes = await ApiService.getMyCorrections();
    // Fetch all statuses so manager sees full team history
    final results = await Future.wait([
      ApiService.getAdminCorrections(status: 'pending'),
      ApiService.getAdminCorrections(status: 'approved'),
      ApiService.getAdminCorrections(status: 'rejected'),
    ]);

    if (mounted) {
      final combined = <dynamic>[];
      for (final res in results) {
        if (res['error'] == false && res['data'] is List) {
          combined.addAll(res['data']);
        }
      }
      // Sort: pending first, approved, rejected
      combined.sort((a, b) {
        const order = {'pending': 0, 'approved': 1, 'rejected': 2};
        final aO = order[a['status']?.toString() ?? 'pending'] ?? 99;
        final bO = order[b['status']?.toString() ?? 'pending'] ?? 99;
        return aO.compareTo(bO);
      });

      setState(() {
        _isLoading = false;
        if (myRes['error'] == false) _myRequests = myRes['data'] ?? [];
        _teamRequests = combined;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_reasonController.text.isEmpty) {
      _showToast("Please provide a reason", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await ApiService.submitCorrection(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      clockIn: _formatTime(_clockIn),
      clockOut: _formatTime(_clockOut),
      reason: _reasonController.text,
    );

    setState(() => _isSubmitting = false);
    if (res['error'] == false) {
      _showToast("Regulation request submitted!");
      _reasonController.clear();
      _tabController.animateTo(1);
      _fetchData();
    } else {
      _showToast(res['message'] ?? "Submission failed", isError: true);
    }
  }

  String _formatTime(TimeOfDay t) {
    // API expects H:i (e.g. 09:30)
    final hours = t.hour.toString().padLeft(2, '0');
    final minutes = t.minute.toString().padLeft(2, '0');
    return "$hours:$minutes";
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
        title: Text("Manager Regulations", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.navy,
          indicatorColor: AppColors.gold,
          unselectedLabelColor: AppColors.grey400,
          tabs: const [
            Tab(text: "Apply"),
            Tab(text: "My Hist."),
            Tab(text: "Approvals"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildApplyTab(),
              _buildHistoryTable(_myRequests),
              _buildTeamApprovalsTab(),
            ],
          ),
    );
  }

  Widget _buildApplyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.grey100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.edit_calendar, color: AppColors.gold), const SizedBox(width: 12), Text("New Request", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16))]),
            const SizedBox(height: 24),
            _buildLabel("Select Date"),
            _buildDateSelector(),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Clock In"), _buildTimeSelector(true)])), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Clock Out"), _buildTimeSelector(false)]))]),
            const SizedBox(height: 16),
            _buildLabel("Reason"),
            TextField(controller: _reasonController, maxLines: 3, decoration: InputDecoration(hintText: "Reason for correction...", filled: true, fillColor: AppColors.offWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSubmitting ? null : _submitRequest, style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT REQUEST"))),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable(List<dynamic> list) {
    if (list.isEmpty) return Center(child: Text("No records found", style: TextStyle(color: AppColors.grey400)));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      child: DataTable(
        columns: const [DataColumn(label: Text("DATE")), DataColumn(label: Text("IN")), DataColumn(label: Text("OUT")), DataColumn(label: Text("STATUS")), DataColumn(label: Text("APPLIED ON"))],
        rows: list.map((req) {
          final status = (req['status'] ?? 'pending').toString().toLowerCase();
          return DataRow(cells: [
            DataCell(Text(req['date'] ?? "-")),
            DataCell(Text(req['clock_in'] ?? "-")),
            DataCell(Text(req['clock_out'] ?? "-")),
            DataCell(Text(status.toUpperCase(), style: TextStyle(color: status == 'approved' ? AppColors.success : (status == 'rejected' ? AppColors.error : AppColors.warning), fontWeight: FontWeight.bold))),
            DataCell(Text(req['created_at'] != null ? DateFormat('MMM dd').format((DateTime.tryParse(req['created_at']) ?? DateTime.now()).toLocal()) : "N/A")),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildTeamApprovalsTab() {
    if (_teamRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_rounded, size: 64, color: AppColors.grey200),
            const SizedBox(height: 16),
            Text('No team correction requests', style: TextStyle(color: AppColors.grey400)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _teamRequests.length,
      itemBuilder: (context, index) {
        final req = _teamRequests[index];
        final user = req['user'] ?? {};
        final fname = user['first_name']?.toString() ?? '';
        final lname = user['last_name']?.toString() ?? '';
        final name = fname.isNotEmpty
            ? '$fname $lname'.trim()
            : (user['name']?.toString() ??
               req['employee_name']?.toString() ??
               req['user_name']?.toString() ??
               'Employee #${req['id']}');

        final status = (req['status'] ?? 'pending').toString().toLowerCase();
        Color statusColor = AppColors.warning;
        if (status == 'approved') statusColor = AppColors.success;
        if (status == 'rejected') statusColor = AppColors.error;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.grey100),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: AppColors.gold.withValues(alpha: 0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'E',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
              ),
            ),
            title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
            subtitle: Text(
              'Date: ${req['date'] ?? '-'} · In: ${req['clock_in'] ?? '-'} · Out: ${req['clock_out'] ?? '-'}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    if (req['reason'] != null)
                      Text('Reason: ${req['reason']}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.navy)),
                    if (req['admin_remark'] != null && req['admin_remark'] != '-') ...[
                      const SizedBox(height: 8),
                      Text('Admin Remark: ${req['admin_remark']}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600, fontStyle: FontStyle.italic)),
                    ],
                    if (status == 'pending') ...[
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateTeamStatus(req['id'], 'rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateTeamStatus(req['id'], 'approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateTeamStatus(int id, String status) async {
    final remarkController = TextEditingController();
    final remark = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${status == 'approved' ? 'Approve' : 'Reject'} Request',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: remarkController,
          decoration: const InputDecoration(hintText: 'Enter remark (optional)...'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, remarkController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (remark == null) return;
    setState(() => _isLoading = true);
    final res = await ApiService.updateCorrectionStatus(id, status, remark);
    if (res['error'] == false) {
      _showToast(res['message'] ?? 'Request $status successfully!');
      _fetchData();
    } else {
      _showToast(res['message'] ?? 'Action failed', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String l) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey600)));

  Widget _buildDateSelector() => InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2025), lastDate: DateTime.now()); if (d != null) setState(() => _selectedDate = d); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.calendar_month, color: AppColors.grey400, size: 18), const SizedBox(width: 12), Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.arrow_drop_down)])));

  Widget _buildTimeSelector(bool isIn) => InkWell(onTap: () async { final t = await showTimePicker(context: context, initialTime: isIn ? _clockIn : _clockOut); if (t != null) setState(() => isIn ? _clockIn = t : _clockOut = t); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(isIn ? Icons.login : Icons.logout, color: AppColors.grey400, size: 16), const SizedBox(width: 10), Text((isIn ? _clockIn : _clockOut).format(context), style: const TextStyle(fontWeight: FontWeight.bold))])));
}
