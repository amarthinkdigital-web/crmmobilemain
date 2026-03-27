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
    final teamRes = await ApiService.getAdminCorrections(status: 'pending'); // Use same admin endpoint as doc says HR/Admin can access this

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (myRes['error'] == false) _myRequests = myRes['data'] ?? [];
        if (teamRes['error'] == false) _teamRequests = teamRes['data'] ?? [];
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
            DataCell(Text(req['created_at'] != null ? DateFormat('MMM dd').format(DateTime.tryParse(req['created_at']) ?? DateTime.now()) : "N/A")),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildTeamApprovalsTab() {
    if (_teamRequests.isEmpty) return const Center(child: Text("No pending requests from team"));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _teamRequests.length,
      itemBuilder: (context, index) {
        final req = _teamRequests[index];
        return Card(
           margin: const EdgeInsets.only(bottom: 12),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
           child: ListTile(
             leading: const CircleAvatar(backgroundColor: AppColors.gold, child: Icon(Icons.person, color: Colors.white)),
             title: Text("Request #${req['id']}"),
             subtitle: Text("Date: ${req['date']} | In: ${req['clock_in']}"),
             trailing: TextButton(onPressed: () => _updateTeamStatus(req['id'], 'approved'), child: const Text("APPROVE", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
           ),
        );
      },
    );
  }

  Future<void> _updateTeamStatus(int id, String status) async {
    setState(() => _isLoading = true);
    final res = await ApiService.updateCorrectionStatus(id, status, "Approved by Manager");
    if (res['error'] == false) {
      _showToast(res['message'] ?? "Approved team request!");
      _fetchData();
    } else {
      _showToast(res['message'] ?? "Action failed", isError: true);
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String l) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey600)));

  Widget _buildDateSelector() => InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2025), lastDate: DateTime.now()); if (d != null) setState(() => _selectedDate = d); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.calendar_month, color: AppColors.grey400, size: 18), const SizedBox(width: 12), Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.arrow_drop_down)])));

  Widget _buildTimeSelector(bool isIn) => InkWell(onTap: () async { final t = await showTimePicker(context: context, initialTime: isIn ? _clockIn : _clockOut); if (t != null) setState(() => isIn ? _clockIn = t : _clockOut = t); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(isIn ? Icons.login : Icons.logout, color: AppColors.grey400, size: 16), const SizedBox(width: 10), Text((isIn ? _clockIn : _clockOut).format(context), style: const TextStyle(fontWeight: FontWeight.bold))])));
}
