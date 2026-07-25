import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() =>
      _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();
  DateTime? selectedDate;

  final Map<int, List<Map<String, dynamic>>> _tabData = {};
  final Map<int, bool> _tabLoading = {};

  static const _tabs = [
    _TabDef(label: 'All', endpoint: 'employee-records'),
    _TabDef(label: 'Approved', endpoint: 'employee-records/approved'),
    _TabDef(label: 'Rejected', endpoint: 'employee-records/rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    for (var i = 0; i < _tabs.length; i++) {
      _tabData[i] = [];
      _tabLoading[i] = false;
    }
    _tabController.addListener(_onTabChange);
    _fetchTab(0);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) return;
    final idx = _tabController.index;
    if (_tabData[idx]!.isEmpty && !_tabLoading[idx]!) {
      _fetchTab(idx);
    }
  }

  Future<void> _fetchTab(int tabIndex) async {
    setState(() => _tabLoading[tabIndex] = true);

    final res = await ApiService.getAdminDailyWorksheetsByEndpoint(
      _tabs[tabIndex].endpoint,
      name: searchController.text.isNotEmpty ? searchController.text : null,
      workDate: selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
          : null,
    );

    if (mounted) {
      setState(() {
        if (res['error'] == false) {
          _tabData[tabIndex] =
              List<Map<String, dynamic>>.from(res['data']);
        }
        _tabLoading[tabIndex] = false;
      });
      if (res['error'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to load'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Employee Records",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Employee worksheets reviewed by team leaders",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFilterBar(),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: AppColors.navy,
                    unselectedLabelColor: AppColors.grey400,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    indicatorColor: AppColors.navy,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: _tabs.asMap().entries.map((e) {
                      final idx = e.key;
                      final count = _tabData[idx]?.length ?? 0;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.value.label),
                            if (count > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getTabColor(idx)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: _getTabColor(idx),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (idx) {
                return _buildTabContent(idx);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTabColor(int idx) {
    switch (idx) {
      case 0:
        return AppColors.navy;
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.error;
      default:
        return AppColors.navy;
    }
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search by name...",
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: AppColors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _refreshAll(),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() => selectedDate = date);
              _refreshAll();
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16,
                    color: selectedDate != null
                        ? AppColors.navy
                        : AppColors.grey400),
                const SizedBox(width: 8),
                Text(
                  selectedDate == null
                      ? "Date"
                      : DateFormat('dd MMM').format(selectedDate!),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selectedDate != null
                        ? AppColors.navy
                        : AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selectedDate != null || searchController.text.isNotEmpty) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                selectedDate = null;
                searchController.clear();
              });
              _refreshAll();
            },
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.grey400,
            tooltip: 'Clear filters',
          ),
        ],
      ],
    );
  }

  void _refreshAll() {
    for (var i = 0; i < _tabs.length; i++) {
      _fetchTab(i);
    }
  }

  Widget _buildTabContent(int tabIndex) {
    if (_tabLoading[tabIndex]! && _tabData[tabIndex]!.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }
    if (_tabData[tabIndex]!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: AppColors.grey200),
              const SizedBox(height: 12),
              Text(
                "No ${_tabs[tabIndex].label.toLowerCase()} records",
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.grey400),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTab(tabIndex),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _tabData[tabIndex]!.length,
        itemBuilder: (context, index) {
          final log = _tabData[tabIndex]![index];
          return _buildRecordCard(log);
        },
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> log) {
    final userName =
        log['user']?['name'] ?? log['user_name'] ?? 'N/A';
    final workDate = log['work_date'] ?? '';
    final approvalStatus = log['approval_status']?.toString() ?? 'pending';
    final items = log['items'] as List? ?? [];
    final projectName = items.isNotEmpty
        ? (items[0]['project_name'] ??
            items[0]['project']?['name'] ??
            'Project')
        : 'N/A';
    final reviewedBy =
        log['approver']?['name'] ?? log['approved_by_name'] ?? 'N/A';
    final comment = log['leader_comment']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        workDate,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildApprovalBadge(approvalStatus),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.folder_rounded,
                    size: 14, color: AppColors.navy.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    projectName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 14, color: AppColors.grey400),
                const SizedBox(width: 6),
                Text(
                  "Reviewed by: $reviewedBy",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comment,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionBtn(
                  "View Details",
                  Icons.visibility_outlined,
                  AppColors.navy,
                  () => _showViewDialog(log),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalBadge(String status) {
    Color color;
    String label;
    String s = status.toLowerCase();
    if (s == 'approved') {
      color = AppColors.success;
      label = 'Approved';
    } else if (s == 'rejected') {
      color = AppColors.error;
      label = 'Rejected';
    } else {
      color = AppColors.warning;
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            s == 'approved'
                ? Icons.check_circle_rounded
                : (s == 'rejected'
                    ? Icons.cancel_rounded
                    : Icons.schedule_rounded),
            size: 12,
            color: color,
          ),
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
    );
  }

  Widget _buildActionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> log) {
    final items = log['items'] as List? ?? [];
    final otherWork = log['other_work']?.toString() ?? '';
    final userName =
        log['user']?['name'] ?? log['user_name'] ?? 'N/A';
    final workDate = log['work_date'] ?? '-';
    final approvalStatus = log['approval_status']?.toString() ?? 'pending';
    final reviewedBy =
        log['approver']?['name'] ?? log['approved_by_name'] ?? 'N/A';
    final comment = log['leader_comment']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Employee Record",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(userName,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.grey400)),
                ],
              ),
            ),
            _buildApprovalBadge(approvalStatus),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Work Date", workDate),
              _buildDetailRow("Reviewed By", reviewedBy),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text("Projects",
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy)),
                const SizedBox(height: 8),
                ...items.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                            left: BorderSide(
                                color: AppColors.navy.withValues(alpha: 0.4),
                                width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['project_name'] ??
                                p['project']?['name'] ??
                                'Project',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.navy),
                          ),
                          if (p['todays_work']
                                  ?.toString()
                                  .isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 6),
                            Text("Today's Work:",
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey400)),
                            Text(p['todays_work'].toString(),
                                style:
                                    GoogleFonts.inter(fontSize: 12)),
                          ],
                          if ((p['next_step'] ?? p['next_plan'])
                                  ?.toString()
                                  .isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 6),
                            Text("Next Step:",
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey400)),
                            Text(
                                (p['next_step'] ?? p['next_plan'])
                                    .toString(),
                                style:
                                    GoogleFonts.inter(fontSize: 12)),
                          ],
                        ],
                      ),
                    )),
              ],
              if (otherWork.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow("Other Work", otherWork),
              ],
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow("TL Comment", comment),
              ],
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey400)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy)),
        ],
      ),
    );
  }
}

class _TabDef {
  final String label;
  final String endpoint;
  const _TabDef({required this.label, required this.endpoint});
}
