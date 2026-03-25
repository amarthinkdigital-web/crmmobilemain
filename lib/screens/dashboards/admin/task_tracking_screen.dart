import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

class TaskTrackingScreen extends StatefulWidget {
  const TaskTrackingScreen({super.key});

  @override
  State<TaskTrackingScreen> createState() => _TaskTrackingScreenState();
}

class _TaskTrackingScreenState extends State<TaskTrackingScreen> {
  String selectedStatus = "All Status";
  String selectedPriority = "All Priority";
  String selectedGiver = "All Givers";
  String selectedReceiver = "All Receivers";
  DateTime? selectedDate;
  final searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> tasks = [];
  final List<String> statuses = ["All Status", "Pending", "In Progress", "Completed", "Overdue"];
  final List<String> priorities = ["All Priority", "High", "Medium", "Low", "Urgent"];
  final List<String> givers = ["All Givers"];
  final List<String> receivers = ["All Receivers"];
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    _fetchTasks();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final res = await ApiService.getEmployeeProfiles();
    if (res['error'] == false) {
      final List raw = res['data'] ?? [];
      setState(() {
        _allUsers = raw.map((e) => {
          'id': e['user_id']?.toString() ?? e['id']?.toString(),
          'name': e['user']?['name'] ?? e['name'] ?? 'Unknown',
        }).toList();
        
        final List<String> names = _allUsers.map((e) => e['name'].toString()).toList();
        givers.clear();
        givers.add("All Givers");
        givers.addAll(names..sort());
        
        receivers.clear();
        receivers.add("All Receivers");
        receivers.addAll(names..sort());
      });
    }
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getAdminTasks();
    if (response['error'] == false) {
      final List rawTasks = response['data'] ?? [];
      setState(() {
        tasks = rawTasks.map((i) {
          return {
            "id": i['id'],
            "giver": i['assigner']?['name'] ?? 'Admin',
            "receiver": i['assignee']?['name'] ?? 'N/A',
            "task": i['title'] ?? 'No Title',
            "priority": _capitalize(i['priority'] ?? 'Medium'),
            "status": _capitalize(i['status'] ?? 'Pending'),
            "dueDate": i['due_date'] ?? 'N/A',
            "timeSpent": i['total_time_spent'] ?? i['total_seconds']?.toString() ?? '0h 0m',
            "raw": i,
          };
        }).toList();

        // Populate dynamic filters
        final Set<String> g = {"All Givers"};
        final Set<String> r = {"All Receivers"};
        for (var t in tasks) {
          if (t['giver'] != null) g.add(t['giver']);
          if (t['receiver'] != null) r.add(t['receiver']);
        }
        givers.clear();
        givers.addAll(g.toList()..sort());
        receivers.clear();
        receivers.addAll(r.toList()..sort());

        _isLoading = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to load tasks')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredTasks {
    return tasks.where((t) {
      final query = searchController.text.toLowerCase();
      final matchesSearch = t['task'].toLowerCase().contains(query) || 
                           t['id'].toString().contains(query) ||
                           t['giver'].toLowerCase().contains(query) ||
                           t['receiver'].toLowerCase().contains(query);
      
      final matchesStatus = selectedStatus == "All Status" || t['status'] == selectedStatus;
      final matchesPriority = selectedPriority == "All Priority" || t['priority'] == selectedPriority;
      final matchesGiver = selectedGiver == "All Givers" || t['giver'] == selectedGiver;
      final matchesReceiver = selectedReceiver == "All Receivers" || t['receiver'] == selectedReceiver;
      
      bool matchesDate = true;
      if (selectedDate != null) {
        try {
          final taskDate = DateTime.parse(t['dueDate']);
          matchesDate = taskDate.year == selectedDate!.year && 
                        taskDate.month == selectedDate!.month && 
                        taskDate.day == selectedDate!.day;
        } catch (_) {
          matchesDate = false;
        }
      }

      return matchesSearch && matchesStatus && matchesPriority && matchesGiver && matchesReceiver && matchesDate;
    }).toList();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  int _countByStatus(String status) {
    return tasks.where((t) => t['status'].toString().toLowerCase() == status.toLowerCase()).length;
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildFilterSection(),
            const SizedBox(height: 24),
            _buildTaskTable(),
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
      children: [
        Column(
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
            Text(
              "Manage and monitor all team performance and assignments",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.file_download_outlined,
              color: AppColors.navy,
            ),
            tooltip: "Export Report",
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            "Total Tasks",
            tasks.length.toString(),
            Icons.assignment_outlined,
            AppColors.info,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "Pending",
            _countByStatus("Pending").toString(),
            Icons.hourglass_empty_rounded,
            AppColors.warning,
          ),
          const SizedBox(width: 12),
          _buildStatCard("In Progress", _countByStatus("In Progress").toString(), Icons.sync_rounded, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard(
            "Completed",
            _countByStatus("Completed").toString(),
            Icons.check_circle_outline_rounded,
            AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "Overdue",
            _countByStatus("Overdue").toString(),
            Icons.running_with_errors_rounded,
            AppColors.error,
          ),
          const SizedBox(width: 12),
          _buildStatCard("Urgent", tasks.where((t) => t['priority'] == 'Urgent').length.toString(), Icons.bolt_rounded, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.grey100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by task name or ID...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDropdown(
                    "Status",
                    selectedStatus,
                    statuses,
                    (v) => setState(() => selectedStatus = v!),
                  ),
                  const SizedBox(width: 12),
                  _buildDropdown(
                    "Priority",
                    selectedPriority,
                    priorities,
                    (v) => setState(() => selectedPriority = v!),
                  ),
                  const SizedBox(width: 12),
                  _buildDropdown(
                    "Giver",
                    selectedGiver,
                    givers,
                    (v) => setState(() => selectedGiver = v!),
                  ),
                  const SizedBox(width: 12),
                  _buildDropdown(
                    "To",
                    selectedReceiver,
                    receivers,
                    (v) => setState(() => selectedReceiver = v!),
                  ),
                  const SizedBox(width: 12),
                  _buildDatePicker(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: GoogleFonts.inter(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) setState(() => selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: AppColors.navy,
            ),
            const SizedBox(width: 8),
            Text(
              selectedDate == null
                  ? "Select Date"
                  : DateFormat('MMM dd, yyyy').format(selectedDate!),
              style: GoogleFonts.inter(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.navy.withValues(alpha: 0.02),
            ),
            columnSpacing: 30,
            horizontalMargin: 20,
            columns: [
              _buildDataColumn("Assign Giver"),
              _buildDataColumn("Assign Receiver"),
              _buildDataColumn("Task"),
              _buildDataColumn("Priority"),
              _buildDataColumn("Status"),
              _buildDataColumn("Due Date"),
              _buildDataColumn("Time Spent"),
              _buildDataColumn("Actions"),
            ],
            rows: filteredTasks.map((task) => _buildRow(task)).toList(),
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
    final statusColor = _getStatusColor(task['status']);
    final priorityColor = _getPriorityColor(task['priority']);

    return DataRow(
      cells: [
        DataCell(
          Text(
            task['giver'],
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            task['receiver'],
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              task['task'],
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task['priority'],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: priorityColor,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task['status'],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            task['dueDate'],
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600),
          ),
        ),
        DataCell(
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 14,
                color: AppColors.grey400,
              ),
              const SizedBox(width: 4),
              Text(
                task['timeSpent'],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          IconButton(
            onPressed: () => _viewTaskDetails(task),
            icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.navy),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'In Progress':
        return Colors.blue;
      case 'Pending':
        return AppColors.warning;
      case 'Overdue':
        return AppColors.error;
      default:
        return AppColors.grey600;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Urgent':
        return Colors.purple;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.grey600;
    }
  }

  void _viewTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Task: ${task['task']}", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Assigner", task['giver']),
              _detailRow("Assignee", task['receiver']),
              _detailRow("Priority", task['priority']),
              _detailRow("Status", task['status']),
              _detailRow("Due Date", task['dueDate']),
              _detailRow("Time Spent", task['timeSpent']),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
