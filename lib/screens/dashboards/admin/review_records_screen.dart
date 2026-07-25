import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class ReviewRecordsScreen extends StatefulWidget {
  const ReviewRecordsScreen({super.key});

  @override
  State<ReviewRecordsScreen> createState() => _ReviewRecordsScreenState();
}

class _ReviewRecordsScreenState extends State<ReviewRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();
  DateTime? selectedDate;

  List<Map<String, dynamic>> _tlRejected = [];
  List<Map<String, dynamic>> _empRejected = [];
  bool _loadingTl = true;
  bool _loadingEmp = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loadingTl = true;
      _loadingEmp = true;
    });

    final tlRes = await ApiService.getAdminDailyWorksheetsByEndpoint(
      'tl-rejected',
      name: searchController.text.isNotEmpty ? searchController.text : null,
      workDate: selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
          : null,
    );
    final empRes = await ApiService.getAdminDailyWorksheetsByEndpoint(
      'employee-records/rejected',
      name: searchController.text.isNotEmpty ? searchController.text : null,
      workDate: selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
          : null,
    );

    if (mounted) {
      setState(() {
        if (tlRes['error'] == false) {
          _tlRejected =
              List<Map<String, dynamic>>.from(tlRes['data']);
        }
        if (empRes['error'] == false) {
          _empRejected =
              List<Map<String, dynamic>>.from(empRes['data']);
        }
        _loadingTl = false;
        _loadingEmp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRejected = _tlRejected.length + _empRejected.length;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Review Records",
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (totalRejected > 0) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.error
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "$totalRejected rejected",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "All rejected worksheets from team leaders and employees",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.grey400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                    labelColor: AppColors.error,
                    unselectedLabelColor: AppColors.grey400,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    indicatorColor: AppColors.error,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("TL Rejected"),
                            if (_tlRejected.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.error
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_tlRejected.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Employee Rejected"),
                            if (_empRejected.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.error
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_empRejected.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_tlRejected, _loadingTl, isTl: true),
                _buildList(_empRejected, _loadingEmp, isTl: false),
              ],
            ),
          ),
        ],
      ),
    );
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
                borderSide:
                    const BorderSide(color: AppColors.navy, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _fetchData(),
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
              _fetchData();
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
              _fetchData();
            },
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.grey400,
            tooltip: 'Clear filters',
          ),
        ],
      ],
    );
  }

  Widget _buildList(
      List<Map<String, dynamic>> data, bool loading,
      {required bool isTl}) {
    if (loading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 48, color: AppColors.success.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                "No rejected ${isTl ? 'TL' : 'employee'} worksheets",
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.grey400),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return _buildRejectedCard(data[index], isTl);
        },
      ),
    );
  }

  Widget _buildRejectedCard(Map<String, dynamic> log, bool isTl) {
    final userName =
        log['user']?['name'] ?? log['user_name'] ?? 'N/A';
    final workDate = log['work_date'] ?? '';
    final items = log['items'] as List? ?? [];
    final projectName = items.isNotEmpty
        ? (items[0]['project_name'] ??
            items[0]['project']?['name'] ??
            'Project')
        : 'N/A';
    final comment = log['leader_comment']?.toString() ??
        log['review_comment']?.toString() ??
        '';

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
                  radius: 16,
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            workDate,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.grey400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isTl
                                  ? AppColors.info.withValues(alpha: 0.1)
                                  : AppColors.gold
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTl ? "TL" : "Employee",
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isTl
                                    ? AppColors.info
                                    : AppColors.goldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_rounded,
                          size: 12, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        "Rejected",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.folder_rounded,
                    size: 14,
                    color: AppColors.navy.withValues(alpha: 0.5)),
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
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                        width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rejection Reason",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
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
                  () => _showViewDialog(log, isTl),
                ),
              ],
            ),
          ],
        ),
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

  void _showViewDialog(Map<String, dynamic> log, bool isTl) {
    final items = log['items'] as List? ?? [];
    final otherWork = log['other_work']?.toString() ?? '';
    final userName =
        log['user']?['name'] ?? log['user_name'] ?? 'N/A';
    final workDate = log['work_date'] ?? '-';
    final comment = log['leader_comment']?.toString() ??
        log['review_comment']?.toString() ??
        '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rejected Worksheet",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text("$userName (${isTl ? 'Team Leader' : 'Employee'})",
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.grey400)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text("Rejected",
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Work Date", workDate),
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
                                color:
                                    AppColors.error.withValues(alpha: 0.4),
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
                                style: GoogleFonts.inter(fontSize: 12)),
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
                                style: GoogleFonts.inter(fontSize: 12)),
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.4),
                          width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rejection Comment",
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error)),
                      const SizedBox(height: 4),
                      Text(comment,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.grey600)),
                    ],
                  ),
                ),
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
