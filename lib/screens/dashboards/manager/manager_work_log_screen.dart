import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class ManagerWorkLogScreen extends StatefulWidget {
  const ManagerWorkLogScreen({super.key});

  @override
  State<ManagerWorkLogScreen> createState() => _ManagerWorkLogScreenState();
}

class _ManagerWorkLogScreenState extends State<ManagerWorkLogScreen> {
  List<Map<String, dynamic>> _worksheets = [];
  bool _isLoading = true;

  final TextEditingController dateController = TextEditingController();
  final TextEditingController pointsController = TextEditingController();
  final TextEditingController workDoneController = TextEditingController();
  final TextEditingController nextStepController = TextEditingController();

  List<dynamic> _availableProjects = [];
  dynamic _selectedProjectObj; // Will store the selected project map {id, name}

  String selectedStatus = 'Pending';
  String selectedPriority = 'Medium';
  String selectedApproval = 'Pending';
  bool _isModalSubmitting = false; 

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
    _fetchWorksheets();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    final res = await ApiService.getProjects(fallbackData: _worksheets);
    if (mounted && res['error'] == false) {
      setState(() {
        _availableProjects = res['data'];
        if (_availableProjects.isNotEmpty) {
          _selectedProjectObj = _availableProjects.first;
        }
      });
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    pointsController.dispose();
    workDoneController.dispose();
    nextStepController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorksheets() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getManagerDailyWorksheets();
    if (mounted) {
      setState(() {
        if (res['error'] == false) {
          _worksheets = List<Map<String, dynamic>>.from(res['data']);
          _fetchProjects(); // Refresh projects from worksheets if API fails
        }
        _isLoading = false;
      });
      if (res['error'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to load manager worksheets'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddWorksheetSheet({bool isEdit = false, int? editId}) {
    // Initialize date if empty
    if (dateController.text.isEmpty) {
      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? "Edit Worksheet" : "Add Worksheet",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                    _buildProjectDropdown(
                      "Select Project",
                      _selectedProjectObj,
                      _availableProjects,
                      (v) => setModalState(() => _selectedProjectObj = v),
                    ),
                    const SizedBox(height: 16),
                _buildInputField(
                  "Work Date",
                  "Select date",
                  dateController,
                  Icons.calendar_today_rounded,
                  isReadOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setModalState(() {
                        dateController.text = DateFormat('yyyy-MM-dd').format(date);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  "Today's Work",
                  "Description of work done today",
                  workDoneController,
                  Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  "Status",
                  selectedStatus,
                  _statuses,
                  (v) => setModalState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  "Next Step",
                  "Planned next steps",
                  nextStepController,
                  Icons.next_plan_outlined,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  "Priority",
                  selectedPriority,
                  _priorities,
                  (v) => setModalState(() => selectedPriority = v!),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isModalSubmitting ? null : () async {
                      if (_selectedProjectObj == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Project selection is required"), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      if (dateController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Date is required")));
                        return;
                      }
                      if (workDoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Work done description is required")));
                        return;
                      }
                      
                      setModalState(() => _isModalSubmitting = true);
                      final body = {
                        'project_id': _selectedProjectObj['id'],
                        'project_name': _selectedProjectObj['name'],
                        'work_date': dateController.text,
                        'todays_work': workDoneController.text,
                        'status': selectedStatus.toLowerCase().replaceAll(' ', ''),
                        'priority': selectedPriority.toLowerCase(),
                        'next_step': nextStepController.text,
                      };
                      
                      final res = isEdit 
                          ? await ApiService.updateManagerDailyWorksheet(editId!, body)
                          : await ApiService.submitManagerDailyWorksheet(body);
                      
                      if (mounted) {
                        setModalState(() => _isModalSubmitting = false);
                        if (res['error'] == false) {
                          _fetchWorksheets();
                          _clearControllers();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(isEdit ? "Worksheet updated" : "Worksheet added"), backgroundColor: AppColors.success),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Error submitting worksheet'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isModalSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Add Worksheet",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearControllers() {
    dateController.clear();
    pointsController.clear();
    workDoneController.clear();
    nextStepController.clear();
    if (_availableProjects.isNotEmpty) {
      _selectedProjectObj = _availableProjects.first;
    } else {
      _selectedProjectObj = null;
    }
    selectedStatus = 'Pending';
    selectedPriority = 'Medium';
    selectedApproval = 'Pending';
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    VoidCallback? onTap,
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
            filled: true,
            fillColor: AppColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
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
                fontWeight: FontWeight.w600,
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
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
                  : _buildWorksheetsTable(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWorksheetSheet,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Add Worksheet",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Daily Work Log",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          "Review and manage assignments and work progression",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWorksheetsTable() {
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
              "My Worksheet List",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
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
                  _buildDataColumn("Sr. No."),
                  _buildDataColumn("Project"),
                  _buildDataColumn("Work Date"),
                  _buildDataColumn("Status"),
                  _buildDataColumn("Priority"),
                  _buildDataColumn("Approval Status"),
                  _buildDataColumn("Points"),
                  _buildDataColumn("Action"),
                ],
                rows: _worksheets.asMap().entries.map((entry) {
                   final idx = entry.key;
                   final w = entry.value;
                   return _buildRow(idx + 1, w);
                }).toList(),
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

  DataRow _buildRow(int srNo, Map<String, dynamic> w) {
    String project = w['project']?['name'] ?? w['project_name'] ?? w['project'] ?? 'N/A';
    String workDate = w['work_date'] ?? w['workDate'] ?? '-';
    String status = w['status']?.toString() ?? 'Pending';
    String priority = w['priority']?.toString() ?? 'Medium';
    String approval = w['approval_status']?.toString() ?? w['approvalStatus']?.toString() ?? 'Pending';
    String points = w['points']?.toString() ?? '-';

    return DataRow(
      cells: [
        DataCell(
          Text(srNo.toString(), style: GoogleFonts.inter(fontSize: 12)),
        ),
        DataCell(
          Text(
            project,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        DataCell(Text(workDate, style: GoogleFonts.inter(fontSize: 12))),
        DataCell(_buildStatusBadge(status)),
        DataCell(_buildPriorityBadge(priority)),
        DataCell(_buildApprovalBadge(approval)),
        DataCell(
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
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
              _buildActionIcon(
                Icons.visibility_outlined,
                AppColors.info,
                "View",
                onTap: () => _viewWorksheet(w),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.edit_outlined, 
                AppColors.goldDark, 
                "Edit",
                onTap: () => _editWorksheet(w),
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                Icons.delete_outline_rounded,
                AppColors.error,
                "Delete",
                onTap: () => _confirmDelete(w),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.navy;
    String s = status.toLowerCase();
    if (s.contains("completed") || s.contains("done")) color = AppColors.success;
    if (s.contains("progress")) color = AppColors.info;
    if (s.contains("hold")) color = Colors.orange;
    if (s.contains("cancel") || s.contains("block")) color = AppColors.error;
    if (s.contains("pending")) color = AppColors.warning;

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

  Widget _buildPriorityBadge(String priority) {
    Color color = AppColors.navy;
    String p = priority.toLowerCase();
    if (p.contains("high") || p.contains("urgent") || p.contains("critical")) color = AppColors.error;
    if (p.contains("medium")) color = AppColors.warning;
    if (p.contains("low")) color = AppColors.success;

    return Row(
      children: [
        Icon(Icons.flag_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          priority,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalBadge(String status) {
    Color color = AppColors.warning;
    String s = status.toLowerCase();
    if (s.contains("approved")) color = AppColors.success;
    if (s.contains("rejected")) color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, String tooltip,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _viewWorksheet(Map<String, dynamic> w) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Worksheet Details",
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy)),
            const Divider(height: 32),
            _buildDetailRow("Project",
                w['project']?['name'] ?? w['project_name'] ?? 'N/A'),
            _buildDetailRow("Work Date", w['work_date'] ?? '-'),
            _buildDetailRow("Status", w['status'] ?? 'Pending'),
            _buildDetailRow("Priority", w['priority'] ?? 'Medium'),
            _buildDetailRow("Work Description", w['todays_work'] ?? '-'),
            _buildDetailRow("Next Step", w['next_step'] ?? '-'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                child:
                    const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editWorksheet(Map<String, dynamic> w) {
    // Populate controllers
    dateController.text = w['work_date'] ?? '';
    workDoneController.text = w['todays_work'] ?? '';
    nextStepController.text = w['next_step'] ?? '';
    selectedStatus = _statuses.firstWhere(
      (s) =>
          s.toLowerCase().replaceAll(' ', '') ==
          w['status']?.toString().toLowerCase(),
      orElse: () => "Pending",
    );
    selectedPriority = _priorities.firstWhere(
      (p) => p.toLowerCase() == w['priority']?.toString().toLowerCase(),
      orElse: () => "Medium",
    );

    // We also need to set the selected project object
    final pId = w['project_id'] ?? w['project']?['id'];
    if (pId != null) {
      _selectedProjectObj = _availableProjects.firstWhere(
        (p) => p['id'] == pId,
        orElse: () =>
            _availableProjects.isNotEmpty ? _availableProjects.first : null,
      );
    }

    _showAddWorksheetSheet(isEdit: true, editId: w['id']);
  }

  void _confirmDelete(Map<String, dynamic> w) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Worksheet"),
        content: const Text(
            "Delete this worksheet? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await ApiService.deleteManagerDailyWorksheet(w['id']);
              if (mounted) {
                if (res['error'] == false) {
                  _fetchWorksheets();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Worksheet deleted"),
                      backgroundColor: AppColors.success));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Delete failed"),
                      backgroundColor: AppColors.error));
                }
              }
            },
            child:
                const Text("Delete", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey400)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy)),
        ],
      ),
    );
  }
}
