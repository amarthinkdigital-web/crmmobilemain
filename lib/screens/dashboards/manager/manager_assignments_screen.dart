import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class ManagerAssignmentsScreen extends StatefulWidget {
  const ManagerAssignmentsScreen({super.key});

  @override
  State<ManagerAssignmentsScreen> createState() =>
      _ManagerAssignmentsScreenState();
}

class _ManagerAssignmentsScreenState extends State<ManagerAssignmentsScreen> {
  // Filter States
  String _statusFilter = 'All Status';
  String _priorityFilter = 'All Priority';
  String _dateFilter = 'Task Given To Date';
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _employees = [];
  String? _selectedEmployeeId;
  String _employeeFilterName = 'All Employees';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([_fetchTasks(), _fetchEmployees()]);
  }

  Future<void> _fetchEmployees() async {
    final response = await ApiService.getEmployeeProfiles();
    if (response['error'] == false) {
      final List raw = response['data'] ?? [];
      setState(() {
        _employees = raw
            .map(
              (e) => {
                'id': e['user_id']?.toString() ?? e['id']?.toString(),
                'name': e['user']?['name'] ?? e['name'] ?? 'Unknown',
              },
            )
            .toList();
      });
    }
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);

    if (_selectedEmployeeId != null) {
      // Special mode: Fetch tasks related to specific employee
      final futureTo = ApiService.getManagerTasks(
        queryParams: {'assigned_to': _selectedEmployeeId},
      );
      final futureBy = ApiService.getManagerTasks(
        queryParams: {'assigned_by': _selectedEmployeeId},
      );

      final results = await Future.wait([futureTo, futureBy]);
      final respTo = results[0];
      final respBy = results[1];

      if (respTo['error'] == false || respBy['error'] == false) {
        final List tasksTo = respTo['data'] ?? [];
        final List tasksBy = respBy['data'] ?? [];

        setState(() {
          _tasks = [
            ...tasksTo.map((i) => _mapTask(i, category: 'Assigned TO')),
            ...tasksBy.map((i) => _mapTask(i, category: 'Assigned BY')),
          ];
          _isLoading = false;
        });
      } else {
        _handleFetchError(respTo['message'] ?? respBy['message']);
      }
    } else {
      // Normal mode: All manager assignments
      final response = await ApiService.getManagerTasks();
      if (response['error'] == false) {
        final List raw = response['data'] ?? [];
        setState(() {
          _tasks = raw
              .asMap()
              .entries
              .map(
                (e) => _mapTask(e.value, category: 'TASKS', index: e.key + 1),
              )
              .toList();
          _isLoading = false;
        });
      } else {
        _handleFetchError(response['message']);
      }
    }
  }

  Map<String, dynamic> _mapTask(
    Map<String, dynamic> i, {
    String category = 'TASKS',
    int index = 1,
  }) {
    // Robust mapping for assigner/giver
    final giverData = i['assigner'] ?? i['assigned_by_user'] ?? i['giver'];
    String giverName = 'Admin';
    if (giverData is Map) {
      giverName =
          giverData['name'] ??
          giverData['user_name'] ??
          giverData['first_name'] ??
          'Admin';
    } else if (giverData != null) {
      giverName = giverData.toString();
    }

    // Robust mapping for assignee/receiver
    final receiverData =
        i['assignee'] ?? i['assigned_to_user'] ?? i['user'] ?? i['receiver'];
    String receiverName = 'N/A';
    if (receiverData is Map) {
      receiverName =
          receiverData['name'] ??
          receiverData['user_name'] ??
          receiverData['first_name'] ??
          'N/A';
    } else if (receiverData != null) {
      receiverName = receiverData.toString();
    }

    // Robust mapping for title/task
    final taskTitle =
        i['title'] ??
        i['task_details'] ??
        i['task_name'] ??
        i['description'] ??
        i['details'] ??
        'No Title';

    return {
      "id": (i['id'] ?? i['task_id'] ?? '').toString(),
      "srNo": index,
      "details": taskTitle.toString(),
      "giver": giverName,
      "receiver": receiverName,
      "priority": _capitalize(i['priority']?.toString() ?? 'Medium'),
      "status": _capitalize(i['status']?.toString() ?? 'Pending'),
      "due":
          i['due_date']?.toString() ??
          i['deadline']?.toString() ??
          i['date']?.toString() ??
          i['due']?.toString() ??
          'N/A',
      "spent":
          i['total_time_spent']?.toString() ??
          i['total_seconds']?.toString() ??
          i['time_spent']?.toString() ??
          '0h 0m',
      "category": i['category']?.toString() ?? category,
      "raw": i,
    };
  }

  void _handleFetchError(String? msg) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg ?? 'Failed to load tasks')));
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredTasks {
    return _tasks.where((t) {
      final query = _searchController.text.toLowerCase();
      final matchesSearch =
          t['details'].toLowerCase().contains(query) ||
          t['id'].toString().contains(query) ||
          t['giver'].toLowerCase().contains(query) ||
          t['receiver'].toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == "All Status" || t['status'] == _statusFilter;
      final matchesPriority =
          _priorityFilter == "All Priority" || t['priority'] == _priorityFilter;

      bool matchesDate = true;
      if (_dateFilter != 'Task Given To Date') {
        DateTime? taskDate;
        try {
          taskDate = DateTime.parse(t['due']).toLocal();
        } catch (_) {}

        if (taskDate != null) {
          final now = DateTime.now();
          if (_dateFilter == 'Today') {
            matchesDate =
                taskDate.year == now.year &&
                taskDate.month == now.month &&
                taskDate.day == now.day;
          } else if (_dateFilter == 'This Week') {
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            matchesDate =
                taskDate.isAfter(
                  startOfWeek.subtract(const Duration(days: 1)),
                ) &&
                taskDate.isBefore(startOfWeek.add(const Duration(days: 7)));
          } else if (_dateFilter == 'This Month') {
            matchesDate =
                taskDate.year == now.year && taskDate.month == now.month;
          }
        }
      }

      return matchesSearch && matchesStatus && matchesPriority && matchesDate;
    }).toList();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    String formatted = s.replaceAll('_', ' ');
    List<String> words = formatted.split(' ');
    String result = words
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
    if (result == 'In Progress' || result == 'Inprogress') return 'In Progress';
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            )
          : RefreshIndicator(
              onRefresh: _fetchTasks,
              color: AppColors.navy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTaskStats(),
                    const SizedBox(height: 24),
                    _buildFiltersAndSearch(),
                    const SizedBox(height: 24),
                    _buildTaskTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Tasks Management",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddTaskDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text("Create Task"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTaskDialog({Map<String, dynamic>? editTask}) {
    showDialog(
      context: context,
      builder: (context) =>
          _TaskActionDialog(editTask: editTask, onSuccess: () => _fetchTasks()),
    );
  }

  int _countByStatus(String status) {
    return _tasks
        .where(
          (t) => t['status'].toString().toLowerCase() == status.toLowerCase(),
        )
        .length;
  }

  Widget _buildTaskStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatCard(
            "Total Tasks",
            _tasks.length.toString(),
            AppColors.navy,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "Pending",
            _countByStatus("Pending").toString(),
            AppColors.warning,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "In Progress",
            _countByStatus("In Progress").toString(),
            AppColors.info,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "Completed",
            _countByStatus("Completed").toString(),
            AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "Overdue",
            _countByStatus("Overdue").toString(),
            AppColors.error,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "Urgent",
            _tasks.where((t) => t['priority'] == 'Urgent').length.toString(),
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(_statusFilter, [
                  'All Status',
                  'Pending',
                  'In Progress',
                  'Completed',
                ], (v) => setState(() => _statusFilter = v!)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(_priorityFilter, [
                  'All Priority',
                  'High',
                  'Medium',
                  'Low',
                  'Urgent',
                ], (v) => setState(() => _priorityFilter = v!)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  _employeeFilterName,
                  [
                    'All Employees',
                    ..._employees.map((e) => e['name'].toString()),
                  ],
                  (v) {
                    if (v == 'All Employees') {
                      setState(() {
                        _employeeFilterName = v!;
                        _selectedEmployeeId = null;
                      });
                    } else {
                      final emp = _employees.firstWhere((e) => e['name'] == v);
                      setState(() {
                        _employeeFilterName = v!;
                        _selectedEmployeeId = emp['id'];
                      });
                    }
                    _fetchTasks();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(_dateFilter, [
                  'Task Given To Date',
                  'Today',
                  'This Week',
                  'This Month',
                ], (v) => setState(() => _dateFilter = v!)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search tasks...",
              hintStyle: GoogleFonts.inter(
                color: AppColors.grey400,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.grey400,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.offWhite,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.grey600,
            size: 20,
          ),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          items: items
              .map((String e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTaskTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              "Task List",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppColors.offWhite),
              columnSpacing: 40,
              horizontalMargin: 20,
              columns: [
                if (_selectedEmployeeId != null)
                  DataColumn(
                    label: Text(
                      "Relation",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                DataColumn(
                  label: Text(
                    "Sr No",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Task Details",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Assign Giver",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Assign Receiver",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Priority",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Status",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Due Date",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Time Spent",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Actions",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              rows: _filteredTasks.map((task) {
                Color priorityColor = AppColors.grey600;
                if (task['priority'] == 'High') priorityColor = AppColors.error;
                if (task['priority'] == 'Urgent')
                  priorityColor = Colors.deepOrange;
                if (task['priority'] == 'Medium')
                  priorityColor = AppColors.warning;

                Color statusColor = AppColors.grey600;
                if (task['status'] == 'Completed')
                  statusColor = AppColors.success;
                if (task['status'] == 'In Progress')
                  statusColor = AppColors.info;
                if (task['status'] == 'Pending')
                  statusColor = AppColors.warning;

                return DataRow(
                  cells: [
                    DataCell(Text(task['srNo'].toString())),
                    if (_selectedEmployeeId != null)
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (task['category']?.contains('TO') ?? false)
                                ? AppColors.info.withOpacity(0.1)
                                : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task['category'] ?? 'N/A',
                            style: GoogleFonts.inter(
                              color: (task['category']?.contains('TO') ?? false)
                                  ? AppColors.info
                                  : AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          task['details'],
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(task['giver'])),
                    DataCell(Text(task['receiver'])),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task['priority'],
                          style: GoogleFonts.inter(
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task['status'],
                          style: GoogleFonts.inter(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(task['due'])),
                    DataCell(Text(task['spent'])),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              color: AppColors.info,
                              size: 20,
                            ),
                            onPressed: () => _viewTaskDetails(task),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.navy,
                              size: 20,
                            ),
                            onPressed: () =>
                                _showAddTaskDialog(editTask: task['raw']),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () => _deleteTask(task['id']),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _viewTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          task['details'],
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailText("Giver", task['giver']),
            _detailText("Receiver", task['receiver']),
            _detailText("Priority", task['priority']),
            _detailText("Status", task['status']),
            _detailText("Due Date", task['due']),
            _detailText(
              "Description",
              task['raw']['description'] ?? 'No description',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _detailText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(color: AppColors.navy, fontSize: 13),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final response = await ApiService.deleteManagerTask(id);
      if (response['error'] == false) {
        _fetchTasks();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Delete failed')),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }
}

class _TaskActionDialog extends StatefulWidget {
  final Map<String, dynamic>? editTask;
  final VoidCallback onSuccess;
  const _TaskActionDialog({this.editTask, required this.onSuccess});
  @override
  State<_TaskActionDialog> createState() => _TaskActionDialogState();
}

class _TaskActionDialogState extends State<_TaskActionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _priority = 'medium';
  String? _assigneeId;
  DateTime _dueDate = DateTime.now();
  bool _isSaving = false;
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.editTask?['title'] ?? "",
    );
    _descriptionController = TextEditingController(
      text: widget.editTask?['description'] ?? "",
    );
    _priority = (widget.editTask?['priority'] ?? 'medium').toLowerCase();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    final res = await ApiService.getEmployeeProfiles();
    if (res['error'] == false) {
      setState(() {
        _employees = List<Map<String, dynamic>>.from(res['data'] ?? []);
        if (widget.editTask != null) {
          _assigneeId = widget.editTask?['assigned_to']?.toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.editTask == null ? "Add Task" : "Edit Task"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _assigneeId,
                decoration: const InputDecoration(labelText: "Assign To"),
                items: _employees
                    .map(
                      (e) => DropdownMenuItem(
                        value: (e['user_id'] ?? e['id']).toString(),
                        child: Text(
                          e['user']?['name'] ?? e['name'] ?? "Unknown",
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _assigneeId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: "Priority"),
                items: ['low', 'medium', 'high', 'urgent']
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Due Date",
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_dueDate)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? "Saving..." : "Save"),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _assigneeId == null) return;
    setState(() => _isSaving = true);
    final data = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'assigned_to': _assigneeId,
      'priority': _priority,
      'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
    };

    final res = widget.editTask == null
        ? await ApiService.createManagerTask(data)
        : await ApiService.updateManagerTask(widget.editTask!['id'], data);

    if (res['error'] == false) {
      widget.onSuccess();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'] ?? "Error")));
    }
    setState(() => _isSaving = false);
  }
}
