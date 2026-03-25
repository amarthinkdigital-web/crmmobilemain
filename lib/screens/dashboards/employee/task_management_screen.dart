import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  bool _isAssignedToMe = true;
  bool _isLoading = true;

  // Real data from API
  List<Map<String, dynamic>> _assignedToMeTasks = [];
  List<Map<String, dynamic>> _assignedByMeTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getEmployeeTasks(),
      ApiService.getEmployeeTasksAssignedByMe(),
    ]);

    final responseTo = results[0];
    final responseBy = results[1];

    setState(() {
      if (responseTo['error'] == false) {
        final List rawTo = responseTo['data'] ?? [];
        _assignedToMeTasks = rawTo.asMap().entries.map((e) {
          final i = e.value;
          return {
            "id": i['id'],
            "srNo": e.key + 1,
            "taskDetails": i['title'] ?? 'No Title',
            "assignedBy": i['assigner']?['name'] ?? 'Admin',
            "priority": _capitalize(i['priority'] ?? 'Medium'),
            "status": _capitalize(i['status'] ?? 'Pending'),
            "dueDate": i['due_date'] ?? 'N/A',
            "timeTracking": i['total_time_spent'] ?? i['total_seconds']?.toString() ?? '00:00:00',
            "raw": i,
          };
        }).toList();
      }

      if (responseBy['error'] == false) {
        final List rawBy = responseBy['data'] ?? [];
        _assignedByMeTasks = rawBy.asMap().entries.map((e) {
          final i = e.value;
          return {
            "id": i['id'],
            "srNo": e.key + 1,
            "taskDetails": i['title'] ?? 'No Title',
            "assignedTo": i['assignee']?['name'] ?? 'N/A',
            "priority": _capitalize(i['priority'] ?? 'Medium'),
            "status": _capitalize(i['status'] ?? 'Pending'),
            "dueDate": i['due_date'] ?? 'N/A',
            "timeTracking": i['total_time_spent'] ?? i['total_seconds']?.toString() ?? '00:00:00',
            "raw": i,
          };
        }).toList();
      }
      _isLoading = false;
    });

    if (responseTo['error'] == true && responseBy['error'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseTo['message'] ?? 'Failed to load tasks')),
        );
      }
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : RefreshIndicator(
              onRefresh: _fetchTasks,
              color: AppColors.navy,
              child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 40),
            _buildToggleButtons(),
            const SizedBox(height: 24),
            _buildTableSection(),
            const SizedBox(height: 100),
          ],
        ),
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
                "Task Management",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Manage and track all your tasks in one place",
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
          onPressed: _showAddTaskDialog,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            "Add Task",
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

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // On very small screens, 2 columns, otherwise 4
        final int crossAxisCount = width < 600 ? 2 : 4;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: width < 600 ? 1.4 : 1.8,
          children: [
            _buildStatCard(
                "Assigned To Me",
                _assignedToMeTasks.length.toString(),
                Icons.assignment_ind_rounded,
                AppColors.info,
                isActive: _isAssignedToMe,
                onTap: () => setState(() => _isAssignedToMe = true)),
            _buildStatCard(
                "Tasks Given By Me",
                _assignedByMeTasks.length.toString(),
                Icons.assignment_return_rounded,
                AppColors.navy,
                isActive: !_isAssignedToMe,
                onTap: () => setState(() => _isAssignedToMe = false)),
            _buildStatCard("Pending Tasks", "5", Icons.pending_actions_rounded, AppColors.warning),
            _buildStatCard("Urgent Tasks", "2", Icons.priority_high_rounded, AppColors.error),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? color : AppColors.grey200, width: isActive ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildToggleButtons() {
    return Row(
      children: [
        _buildToggleButton(
          "Assigned to Me",
          _isAssignedToMe,
          () => setState(() => _isAssignedToMe = true),
        ),
        const SizedBox(width: 12),
        _buildToggleButton(
          "Assigned by Me",
          !_isAssignedToMe,
          () => setState(() => _isAssignedToMe = false),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navy : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.navy : AppColors.grey200,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.white : AppColors.grey600,
          ),
        ),
      ),
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
            horizontalMargin: 24,
            dataRowMinHeight: 65,
            dataRowMaxHeight: 85,
            columns: [
              _buildDataColumn("Sr. No."),
              _buildDataColumn("Task Details"),
              _buildDataColumn(_isAssignedToMe ? "Assigned By" : "Assigned To"),
              _buildDataColumn("Priority"),
              _buildDataColumn("Status"),
              _buildDataColumn("Due Date"),
              if (_isAssignedToMe) _buildDataColumn("Time Tracking"),
              _buildDataColumn("Actions"),
            ],
            rows: (_isAssignedToMe ? _assignedToMeTasks : _assignedByMeTasks)
                .map((task) => _buildRow(task))
                .toList(),
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

  DataRow _buildRow(Map<String, dynamic> task) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            task['srNo'].toString(),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              task['taskDetails'],
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                child: Text(
                  _isAssignedToMe ? task['assignedBy'][0] : task['assignedTo'][0],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isAssignedToMe ? task['assignedBy'] : task['assignedTo'],
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.navy),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(_buildBadge(task['priority'], _getPriorityColor(task['priority']))),
        DataCell(_buildBadge(task['status'], _getStatusColor(task['status']))),
        DataCell(
          Text(
            task['dueDate'],
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
          ),
        ),
        if (_isAssignedToMe)
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.navy.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.navy),
                  const SizedBox(width: 6),
                  Text(
                    task['timeTracking'],
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _isAssignedToMe
                ? [
                    _buildActionBtn("View", Icons.visibility_rounded, AppColors.navy, () => _viewTaskDetails(task)),
                    const SizedBox(width: 8),
                    _buildActionBtn("Status", Icons.update_rounded, AppColors.info, () => _showUpdateStatusDialog(task)),
                  ]
                : [
                    _buildActionBtn("Edit", Icons.edit_rounded, AppColors.info, () {}),
                    const SizedBox(width: 8),
                    _buildActionBtn("View", Icons.visibility_rounded, AppColors.navy, () => _viewTaskDetails(task)),
                    const SizedBox(width: 8),
                    _buildActionBtn("Delete", Icons.delete_outline_rounded, AppColors.error, () {}),
                  ],
          ),
        ),
      ],
    );
  }

  void _viewTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.assignment_rounded, color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(child: Text("Task Details", style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            _buildBadge(task['status'], _getStatusColor(task['status'])),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailItem("Title", task['taskDetails']),
              _detailItem("Description", task['raw']['description'] ?? 'No description provided'),
              _detailItem(_isAssignedToMe ? "Assigned By" : "Assigned To", _isAssignedToMe ? task['assignedBy'] : task['assignedTo']),
              Row(
                children: [
                  Expanded(child: _detailItem("Priority", task['priority'])),
                  Expanded(child: _detailItem("Due Date", task['dueDate'])),
                ],
              ),
              _detailItem("Time Spent", task['timeTracking']),
              if (task['raw']['attachments'] != null && (task['raw']['attachments'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text("Attachments", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    ... (task['raw']['attachments'] as List).map((a) => ListTile(
                      leading: const Icon(Icons.attach_file, size: 18),
                      title: Text(a['file_name'] ?? 'File', style: const TextStyle(fontSize: 12)),
                      dense: true,
                    )),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Status", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("In Progress"),
              onTap: () => _updateStatus(task['id'], "in_progress"),
            ),
            ListTile(
              title: const Text("Completed"),
              onTap: () => _updateStatus(task['id'], "completed"),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: AppColors.success),
              title: const Text("Start Timer"),
              onTap: () => _handleTimer(task['id'], true),
            ),
            ListTile(
              leading: const Icon(Icons.stop_rounded, color: AppColors.error),
              title: const Text("Stop Timer"),
              onTap: () => _handleTimer(task['id'], false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(dynamic id, String status) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    final response = await ApiService.updateTaskStatus(id, status);
    if (response['error'] == false) {
      _fetchTasks();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Update failed')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTimer(dynamic id, bool start) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    final response = start 
        ? await ApiService.startTaskTimer(id)
        : await ApiService.stopTaskTimer(id);
    
    if (response['error'] == false) {
      _fetchTasks();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Timer operation failed')),
        );
      }
      setState(() => _isLoading = false);
    }
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
    if (status == "Completed") return AppColors.success;
    if (status == "In Progress") return AppColors.info;
    return AppColors.warning; // Pending
  }

  Color _getPriorityColor(String priority) {
    if (priority == "High" || priority == "Urgent") return AppColors.error;
    if (priority == "Medium") return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const _AddTaskDialog();
      },
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPriority = "Medium";
  DateTime? _selectedDueDate = DateTime.now();

  final List<String> _priorities = ["Low", "Medium", "High", "Urgent"];

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
                        "Add New Task",
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
                  _buildTextField("Task Title"),
                  const SizedBox(height: 16),
                  _buildTextField("Task Details / Description", maxLines: 3),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    "Priority",
                    _selectedPriority,
                    _priorities,
                    (v) => setState(() => _selectedPriority = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Task added successfully"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Save Task",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildTextField(String label, {int maxLines = 1}) {
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
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy),
          decoration: InputDecoration(
            fillColor: AppColors.offWhite,
            filled: true,
            hintText: "Enter $label...",
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
              value == null || value.isEmpty ? "Required component" : null,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Due Date",
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
              initialDate: _selectedDueDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) setState(() => _selectedDueDate = date);
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
                  _selectedDueDate == null
                      ? "Select Date"
                      : DateFormat('dd MMM, yyyy').format(_selectedDueDate!),
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
