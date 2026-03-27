import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class CorrectionsScreen extends StatefulWidget {
  const CorrectionsScreen({super.key});

  @override
  State<CorrectionsScreen> createState() => _CorrectionsScreenState();
}

class _CorrectionsScreenState extends State<CorrectionsScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _clockIn = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _clockOut = const TimeOfDay(hour: 18, minute: 0);
  final _reasonController = TextEditingController();
  
  List<dynamic> _myRequests = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getMyCorrections();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['error'] == false) {
          _myRequests = res['data'] ?? [];
        }
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitCorrection() async {
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
      _fetchData();
    } else {
      _showToast(res['message'] ?? "Submission failed", isError: true);
    }
  }

  String _formatTime(TimeOfDay t) {
    // API expects HH:mm (e.g. 09:30)
    final hours = t.hour.toString().padLeft(2, '0');
    final minutes = t.minute.toString().padLeft(2, '0');
    return "$hours:$minutes";
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildRegulationForm(),
          const SizedBox(height: 40),
          _buildRequestsTable(),
        ],
      ),
    );
  }

  Widget _buildRegulationForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_note_rounded, color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 14),
              Text('New Regulation Request', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel("Select Date"),
          _buildDateSelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Clock In"), _buildTimeSelector(true)])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("Clock Out"), _buildTimeSelector(false)])),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel("Reason"),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe why this correction is needed...',
              filled: true, fillColor: AppColors.offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitCorrection,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Regulation History", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: AppColors.navy))
        else if (_myRequests.isEmpty)
          Center(child: Text("No records yet", style: TextStyle(color: AppColors.grey400, fontSize: 13)))
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.grey100)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("DATE")),
                  DataColumn(label: Text("IN")),
                  DataColumn(label: Text("OUT")),
                  DataColumn(label: Text("STATUS")),
                  DataColumn(label: Text("ADMIN REMARK")),
                  DataColumn(label: Text("APPLIED ON")),
                ],
                rows: _myRequests.map((req) {
                  final status = (req['status'] ?? 'pending').toString().toLowerCase();
                  Color statusColor = AppColors.warning;
                  if (status == 'approved') statusColor = AppColors.success;
                  if (status == 'rejected') statusColor = AppColors.error;

                  return DataRow(cells: [
                     DataCell(Text(req['date'] ?? "-")),
                     DataCell(Text(req['clock_in'] ?? "-")),
                     DataCell(Text(req['clock_out'] ?? "-")),
                     DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10)),
                     )),
                     DataCell(Text(req['admin_remark'] ?? "-")),
                     DataCell(Text(req['created_at'] != null ? DateFormat('MMM dd').format(DateTime.tryParse(req['created_at']) ?? DateTime.now()) : "N/A")),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String l) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(l, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey600)));
  
  Widget _buildHeader() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Attendance Regulation Requests', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)), const SizedBox(height: 4), Text('Submit and track your attendance adjustment requests', style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400))]);

  Widget _buildDateSelector() => InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2025), lastDate: DateTime.now()); if (d != null) setState(() => _selectedDate = d); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.calendar_month, color: AppColors.grey400, size: 18), const SizedBox(width: 12), Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), const Icon(Icons.arrow_drop_down)])));

  Widget _buildTimeSelector(bool isIn) => InkWell(onTap: () async { final t = await showTimePicker(context: context, initialTime: isIn ? _clockIn : _clockOut); if (t != null) setState(() => isIn ? _clockIn = t : _clockOut = t); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(isIn ? Icons.login : Icons.logout, color: AppColors.grey400, size: 16), const SizedBox(width: 10), Text((isIn ? _clockIn : _clockOut).format(context), style: const TextStyle(fontWeight: FontWeight.bold))])));
}
