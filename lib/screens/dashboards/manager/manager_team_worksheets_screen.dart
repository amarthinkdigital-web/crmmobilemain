import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class ManagerTeamWorksheetsScreen extends StatefulWidget {
  const ManagerTeamWorksheetsScreen({super.key});

  @override
  State<ManagerTeamWorksheetsScreen> createState() => _ManagerTeamWorksheetsScreenState();
}

class _ManagerTeamWorksheetsScreenState extends State<ManagerTeamWorksheetsScreen> {
  List<dynamic> _worksheets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTeamWorksheets();
  }

  Future<void> _fetchTeamWorksheets() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getTeamWorksheets();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['error'] == false) {
          _worksheets = res['data'] ?? [];
          _errorMessage = null;
        } else {
          _errorMessage = res['message'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
              : RefreshIndicator(
                  onRefresh: _fetchTeamWorksheets,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildWorksheetsTable(),
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
          "Team Worksheets",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          "Review and manage worksheets submitted by your team members",
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400),
        ),
      ],
    );
  }

  Widget _buildWorksheetsTable() {
    if (_worksheets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 64, color: AppColors.grey200),
              const SizedBox(height: 16),
              Text("No worksheets found for your team.", style: GoogleFonts.inter(color: AppColors.grey400)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.navy.withValues(alpha: 0.02)),
            columns: [
              DataColumn(label: Text("Employee", style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              DataColumn(label: Text("Date", style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              DataColumn(label: Text("Project", style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              DataColumn(label: Text("Work Done", style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              DataColumn(label: Text("Status", style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
              DataColumn(label: Text("Actions", style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
            ],
            rows: _worksheets.map((log) {
              final String name = log['user']?['name'] ?? log['employee_name'] ?? 'N/A';
              final String date = log['work_date'] ?? 'N/A';
              final String project = log['project']?['name'] ?? log['project_name'] ?? 'N/A';
              final String work = log['todays_work'] ?? 'N/A';
              final String status = log['status'] ?? 'N/A';

              return DataRow(cells: [
                DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(date)),
                DataCell(Text(project)),
                DataCell(SizedBox(width: 200, child: Text(work, overflow: TextOverflow.ellipsis))),
                DataCell(_buildStatusBadge(status)),
                DataCell(IconButton(
                  icon: const Icon(Icons.rate_review_outlined, color: AppColors.info),
                  onPressed: () => _showReviewDialog(log),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.grey600;
    if (status.toLowerCase().contains('progress')) color = AppColors.info;
    if (status.toLowerCase().contains('complete')) color = AppColors.success;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _showReviewDialog(dynamic log) {
    final pointsController = TextEditingController();
    final remarkController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text("Review Worksheet", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(labelText: "Points (0-10)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarkController,
                decoration: const InputDecoration(labelText: "Remark"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
              onPressed: isSubmitting ? null : () async {
                setModalState(() => isSubmitting = true);
                final res = await ApiService.reviewTeamWorksheet(log['id'], {
                  'points': pointsController.text,
                  'remark': remarkController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  if (res['error'] == false) {
                    _fetchTeamWorksheets();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Review submitted successfully"), backgroundColor: AppColors.success),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message']), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Submit Review"),
            ),
          ],
        ),
      ),
    );
  }
}
