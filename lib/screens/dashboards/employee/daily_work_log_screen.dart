import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class DailyWorkLogScreen extends StatefulWidget {
  const DailyWorkLogScreen({super.key});

  @override
  State<DailyWorkLogScreen> createState() => _DailyWorkLogScreenState();
}

class _DailyWorkLogScreenState extends State<DailyWorkLogScreen> {
  List<Map<String, dynamic>> _worksheets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorksheets();
  }

  Future<void> _fetchWorksheets() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getEmployeeDailyWorksheets();
    if (mounted) {
      setState(() {
        if (res['error'] == false) {
          _worksheets = List<Map<String, dynamic>>.from(res['data']);
        }
        _isLoading = false;
      });
      if (res['error'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _isLoading 
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ))
              : _worksheets.isEmpty 
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text("No worksheets found", style: GoogleFonts.inter(color: AppColors.grey400)),
                      ),
                    )
                  : _buildTableSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Worksheet List",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Track and manage your daily work logs",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.grey400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddWorksheetDialog,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            "Add Worksheet",
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTableSection() {
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
            headingRowColor: WidgetStateProperty.all(
              AppColors.navy.withValues(alpha: 0.05),
            ),
            columnSpacing: 40,
            columns: [
              _buildDataColumn("Sr. No."),
              _buildDataColumn("Project"),
              _buildDataColumn("Workdate"),
              _buildDataColumn("Status"),
              _buildDataColumn("Priority"),
              _buildDataColumn("Approval Status"),
              _buildDataColumn("Points"),
              _buildDataColumn("Action"),
            ],
            rows: _worksheets.asMap().entries.map((entry) {
              final idx = entry.key;
              final log = entry.value;
              return _buildRow(idx + 1, log);
            }).toList(),
          ),
        ),
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

  DataRow _buildRow(int srNo, Map<String, dynamic> log) {
    String project = log['project']?['name'] ?? log['project_name'] ?? log['project'] ?? 'N/A';
    String workDate = log['work_date'] ?? log['workdate'] ?? '-';
    String status = log['status']?.toString() ?? 'Pending';
    String priority = log['priority']?.toString() ?? 'Medium';
    String approval = log['approval_status']?.toString() ?? log['approvalStatus']?.toString() ?? 'Pending';
    String points = log['points']?.toString() ?? '-';

    return DataRow(
      cells: [
        DataCell(
          Text(
            srNo.toString(),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Text(
            project,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            workDate,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        DataCell(_buildBadge(status, _getStatusColor(status))),
        DataCell(_buildBadge(priority, _getPriorityColor(priority))),
        DataCell(_buildBadge(approval, _getApprovalColor(approval))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              points,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.goldDark,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildCompactActionIcon(Icons.visibility_rounded, AppColors.info, () => _showViewDialog(log)),
              const SizedBox(width: 8),
              _buildCompactActionIcon(Icons.edit_rounded, AppColors.goldDark, () => _showEditDialog(log)),
              const SizedBox(width: 8),
              _buildCompactActionIcon(Icons.delete_rounded, AppColors.error, () => _confirmDelete(log)),
            ],
          ),
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
    if (status.contains("completed") || status.contains("done")) return AppColors.success;
    if (status.contains("progress")) return AppColors.info;
    if (status.contains("hold")) return Colors.orange;
    if (status.contains("cancel")) return AppColors.error;
    return AppColors.warning; // Pending
  }

  Color _getPriorityColor(String priority) {
    priority = priority.toLowerCase();
    if (priority.contains("high") || priority.contains("urgent") || priority.contains("critical")) return AppColors.error;
    if (priority.contains("medium")) return AppColors.warning;
    return AppColors.success; // Low
  }

  Color _getApprovalColor(String status) {
    status = status.toLowerCase();
    if (status.contains("approved")) return AppColors.success;
    if (status.contains("rejected")) return AppColors.error;
    return AppColors.warning; // Pending
  }

  Widget _buildCompactActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _showAddWorksheetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _AddWorksheetDialog(
          onSuccess: _fetchWorksheets,
          existingWorksheets: _worksheets,
        );
      },
    );
  }

  void _showViewDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => _ViewWorksheetDialog(log: log),
    );
  }

  void _showEditDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) {
        return _AddWorksheetDialog(
          onSuccess: _fetchWorksheets,
          existingWorksheets: _worksheets,
          editWorksheet: log,
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Worksheet"),
        content: const Text("Are you sure you want to delete this worksheet?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await ApiService.deleteEmployeeDailyWorksheet(log['id']);
              if (mounted) {
                if (res['error'] == false) {
                  _fetchWorksheets();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Worksheet deleted"), backgroundColor: AppColors.success));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "Error deleting"), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AddWorksheetDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final List<Map<String, dynamic>> existingWorksheets;
  final Map<String, dynamic>? editWorksheet; // Null if adding new
  const _AddWorksheetDialog({
    required this.onSuccess, 
    required this.existingWorksheets,
    this.editWorksheet,
  });

  @override
  State<_AddWorksheetDialog> createState() => _AddWorksheetDialogState();
}

class _AddWorksheetDialogState extends State<_AddWorksheetDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedStatus = "Pending";
  String _selectedPriority = "Medium";
  DateTime? _selectedDate = DateTime.now();
  final _workDoneController = TextEditingController();
  final _nextStepController = TextEditingController();
  bool _isSubmitting = false;

  List<dynamic> _availableProjects = [];
  dynamic _selectedProject; // Will store the selected project map {id, name}

  final List<String> _statuses = [
    "Pending",
    "In Progress",
    "Completed",
    "On Hold",
    "Cancelled"
  ];
  final List<String> _priorities = ["Low", "Medium", "High", "Critical"];

  @override
  void initState() {
    super.initState();
    if (widget.editWorksheet != null) {
      final w = widget.editWorksheet!;
      _workDoneController.text = w['todays_work'] ?? '';
      _nextStepController.text = w['next_step'] ?? '';
      _selectedStatus = _statuses.firstWhere(
        (s) => s.toLowerCase().replaceAll(' ', '') == w['status']?.toString().toLowerCase(),
        orElse: () => "Pending",
      );
      _selectedPriority = _priorities.firstWhere(
        (p) => p.toLowerCase() == w['priority']?.toString().toLowerCase(),
        orElse: () => "Medium",
      );
      if (w['work_date'] != null) {
        _selectedDate = DateTime.tryParse(w['work_date']) ?? DateTime.now();
      }
    }
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    final res = await ApiService.getProjects(fallbackData: widget.existingWorksheets);
    if (mounted && res['error'] == false) {
      setState(() {
        _availableProjects = res['data'];
        if (_availableProjects.isNotEmpty) {
          _selectedProject = _availableProjects.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _workDoneController.dispose();
    _nextStepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: DefaultTextStyle(
            style: GoogleFonts.inter(color: AppColors.navy),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.editWorksheet != null ? "Edit Worksheet" : "Add Worksheet",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.grey400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProjectDropdown(
                    "Select Project",
                    _selectedProject,
                    _availableProjects,
                    (v) => setState(() => _selectedProject = v),
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildTextField("Today's Work", _workDoneController, maxLines: 4),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    "Status",
                    _selectedStatus,
                    _statuses,
                    (v) => setState(() => _selectedStatus = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField("Next Step", _nextStepController, hint: "What's the next step?"),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    "Priority",
                    _selectedPriority,
                    _priorities,
                    (v) => setState(() => _selectedPriority = v!),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting 
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Text(
                          "Save Worksheet",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      onPressed: _isSubmitting ? null : _submitForm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a project"), backgroundColor: AppColors.error),
        );
        return;
      }
      setState(() => _isSubmitting = true);
      
      final body = {
        'project_id': _selectedProject?['id'] ?? 1, 
        'project_name': _selectedProject?['name'] ?? 'N/A',
        'work_date': DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now()),
        'todays_work': _workDoneController.text,
        'status': _selectedStatus.toLowerCase().replaceAll(' ', ''), // inprogress, completed, etc.
        'priority': _selectedPriority.toLowerCase(),
        'next_step': _nextStepController.text,
      };

      final res = widget.editWorksheet != null
          ? await ApiService.updateEmployeeDailyWorksheet(widget.editWorksheet!['id'], body)
          : await ApiService.submitEmployeeDailyWorksheet(body);
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['error'] == false) {
          widget.onSuccess();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.editWorksheet != null ? "Worksheet updated successfully" : "Worksheet added successfully"), 
              backgroundColor: AppColors.success
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? "Error saving worksheet"), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _buildProjectDropdown(
    String label,
    dynamic value,
    List<dynamic> items,
    Function(dynamic) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey100),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.grey400),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.navy,
                fontWeight: FontWeight.w500,
              ),
              items: items
                  .map((i) => DropdownMenuItem(
                      value: i, 
                      child: Text(i['name']?.toString() ?? 'Unnamed Project')))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey100),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.grey400),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.navy,
                fontWeight: FontWeight.w500,
              ),
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy),
          decoration: InputDecoration(
            fillColor: AppColors.offWhite,
            filled: true,
            hintText: hint ?? "Enter $label...",
            hintStyle:
                GoogleFonts.inter(fontSize: 14, color: AppColors.grey400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.grey100),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.grey100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? "Required field" : null,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Workdate",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.navy,
                      onPrimary: Colors.white,
                      onSurface: AppColors.navy,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? "Select Date"
                      : DateFormat('dd MMM, yyyy').format(_selectedDate!),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.calendar_month_rounded,
                    color: AppColors.grey400, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
class _ViewWorksheetDialog extends StatelessWidget {
  final Map<String, dynamic> log;
  const _ViewWorksheetDialog({required this.log});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Worksheet Details",
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow("Project",
                log['project']?['name'] ?? log['project_name'] ?? 'N/A'),
            _buildDetailRow("Work Date", log['work_date'] ?? '-'),
            _buildDetailRow("Status", log['status']?.toString() ?? 'Pending'),
            _buildDetailRow("Priority", log['priority']?.toString() ?? 'Medium'),
            _buildDetailRow("Work Done", log['todays_work'] ?? '-',
                isMultiLine: true),
            _buildDetailRow("Next Step", log['next_step'] ?? '-',
                isMultiLine: true),
            _buildDetailRow("Points", log['points']?.toString() ?? '0'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
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
