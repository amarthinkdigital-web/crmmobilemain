import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  // Filters & State for Attendance Logs
  String selectedEmployee = "All Employees";
  String? selectedEmployeeId;
  String selectedStatus = "All Status";
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  DateTime? selectedDate;
  final searchController = TextEditingController();

  final List<Map<String, String>> employees = [
    {"id": "all", "name": "All Employees"},
  ];
  final List<String> statuses = [
    "All Status",
    "Present",
    "Absent",
    "Late",
    "On Leave",
    "Half Day",
    "Weekly Off",
    "Overtime",
  ];
  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  List<Map<String, dynamic>> attendanceData = [];
  bool isLoading = true;
  bool _hasSearched = true;
  String _errorMessage = '';

  // Summary Stats
  int _totalEmpCount = 0;
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;
  int _leaveCount = 0;
  int _halfDayCount = 0;
  int _offCount = 0;
  int _otCount = 0;

  // Correction Requests State
  List<dynamic> _correctionRequests = [];
  bool _isCorrectionsLoading = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    _fetchAttendance();
    _fetchCorrections();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendance() async {
    setState(() => isLoading = true);

    // Fetch Employees and Managers for filter/count
    final empRes = await ApiService.getEmployeeProfiles();
    final mgrRes = await ApiService.getManagerProfiles();
    
    final List allStaff = [];
    if (empRes['error'] == false) {
      allStaff.addAll(empRes['data'] ?? []);
    }
    if (mgrRes['error'] == false) {
      allStaff.addAll(mgrRes['data'] ?? []);
    }

    _totalEmpCount = allStaff.length;

    // Populate employees list for filter dropdown
    if (employees.length <= 1) {
      for (var emp in allStaff) {
        final fname = emp['first_name']?.toString() ?? '';
        final lname = emp['last_name']?.toString() ?? '';
        final fullName = '$fname $lname'.trim();
        final id = emp['user_id']?.toString() ?? emp['id']?.toString() ?? '';
        if (fullName.isNotEmpty && id.isNotEmpty) {
          employees.add({"id": id, "name": fullName});
        }
      }
    }

    String? dateStr;
    String? startStr;
    String? endStr;

    if (selectedDate != null) {
      dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    } else {
      final monthIndex = months.indexOf(selectedMonth) + 1;
      if (monthIndex > 0) {
        // Use current year or a specific year if needed
        final now = DateTime.now();
        final year = now.year;
        final start = DateTime(year, monthIndex, 1);
        final end = DateTime(year, monthIndex + 1, 0);
        startStr = DateFormat('yyyy-MM-dd').format(start);
        endStr = DateFormat('yyyy-MM-dd').format(end);
      }
    }

    final res = await ApiService.getAllAttendances(
      date: dateStr,
      startDate: startStr,
      endDate: endStr,
    );

    // Debug: trace API response
    debugPrint('TeamAttendance API result: error=${res['error']}, data count=${(res['data'] as List?)?.length ?? 0}, raw=${res['raw']?.toString().substring(0, (res['raw']?.toString().length ?? 0) < 200 ? (res['raw']?.toString().length ?? 0) : 200)}');
    if (!mounted) return;

    if (res['error'] == false) {
      final List dataList = res['data'] ?? [];
      final Set<String> empSet = {"All Employees"};

      _presentCount = 0;
      _absentCount = 0;
      _lateCount = 0;
      _leaveCount = 0;
      _halfDayCount = 0;
      _offCount = 0;
      _otCount = 0;

      final Map<String, Map<String, dynamic>> monthlyStatsMap = {};

      for (var item in dataList) {
        final Map<String, dynamic> userMap = item['user'] is Map
            ? item['user']
            : item;
        final fname =
            userMap['first_name']?.toString() ??
            item['first_name']?.toString() ??
            '';
        final lname =
            userMap['last_name']?.toString() ??
            item['last_name']?.toString() ??
            '';

        final String nameStr = fname.isNotEmpty
            ? '$fname $lname'.trim()
            : (userMap['name']?.toString() ??
                  item['name']?.toString() ??
                  'Unknown');

        if (nameStr != 'Unknown') empSet.add(nameStr);

        final userId = item['user_id']?.toString() ?? '0';
        monthlyStatsMap.putIfAbsent(
          userId,
          () => {
            'present': 0,
            'absent': 0,
            'late': 0,
            'leave': 0,
            'half': 0,
            'off': 0,
            'ot': 0.0,
            'totalWork': 0.0,
          },
        );

        final status = (item['attendance_status']?.toString() ?? '')
            .toLowerCase();
        final isLate =
            item['is_late'] == 1 ||
            item['is_late'] == true ||
            status.contains('late');
        final otHours =
            double.tryParse(item['ot_hours']?.toString() ?? '0') ?? 0.0;

        if (status.contains('present') ||
            status.contains('working') ||
            isLate) {
          _presentCount++;
          monthlyStatsMap[userId]!['present']++;
          if (isLate) {
            _lateCount++;
            monthlyStatsMap[userId]!['late']++;
          }
          if (status.contains('half')) {
            _halfDayCount++;
            monthlyStatsMap[userId]!['half']++;
          }
        } else if (status.contains('half')) {
          _halfDayCount++;
          monthlyStatsMap[userId]!['half']++;
        } else if (status.contains('absent')) {
          _absentCount++;
          monthlyStatsMap[userId]!['absent']++;
        } else if (status.contains('leave')) {
          _leaveCount++;
          monthlyStatsMap[userId]!['leave']++;
        } else if (status.contains('off') || status.contains('holiday')) {
          _offCount++;
          monthlyStatsMap[userId]!['off']++;
        } else if (status.isEmpty) {
          _absentCount++;
          monthlyStatsMap[userId]!['absent']++;
        }

        if (otHours > 0) {
          _otCount++;
          monthlyStatsMap[userId]!['ot'] += otHours;
        }

        final DateTime? cin = item['clock_in'] != null
            ? DateTime.tryParse(item['clock_in'].toString())
            : null;
        final DateTime? cout = item['clock_out'] != null
            ? DateTime.tryParse(item['clock_out'].toString())
            : null;
        if (cin != null && cout != null) {
          monthlyStatsMap[userId]!['totalWork'] +=
              cout.difference(cin).inMinutes / 60.0;
        }
      }

      setState(() {
        attendanceData = List<Map<String, dynamic>>.from(dataList);

        // Enrich data with calculated stats
        for (var i = 0; i < attendanceData.length; i++) {
          final userId = attendanceData[i]['user_id']?.toString() ?? '0';
          if (attendanceData[i]['stats'] == null) {
            final s = monthlyStatsMap[userId];
            if (s != null) {
              attendanceData[i]['stats'] = {
                'present': s['present'],
                'absent': s['absent'],
                'leave': s['leave'],
                'late': s['late'],
                'half': s['half'],
                'off': s['off'],
                'ot': "${s['ot'].toStringAsFixed(1)}h",
                'totalWork': "${s['totalWork'].toStringAsFixed(1)}h",
              };
            }
          }
        }
        isLoading = false;
        _hasSearched = true;
        _errorMessage = '';
      });
    } else {
      setState(() {
        isLoading = false;
        _hasSearched = true;
        _errorMessage = res['message']?.toString() ?? 'Failed to load attendance data. Check server connection.';
      });
    }
  }

  Future<void> _fetchCorrections() async {
    setState(() => _isCorrectionsLoading = true);

    // Fetch all three statuses in parallel so we get the complete history
    final results = await Future.wait([
      ApiService.getAdminCorrections(status: 'pending'),
      ApiService.getAdminCorrections(status: 'approved'),
      ApiService.getAdminCorrections(status: 'rejected'),
    ]);

    if (mounted) {
      final combined = <dynamic>[];
      for (final res in results) {
        if (res['error'] == false) {
          final list = res['data'];
          if (list is List) combined.addAll(list);
        }
      }

      // Sort: pending first, then approved, then rejected
      combined.sort((a, b) {
        const order = {'pending': 0, 'approved': 1, 'rejected': 2};
        final aOrder = order[a['status']?.toString() ?? 'pending'] ?? 99;
        final bOrder = order[b['status']?.toString() ?? 'pending'] ?? 99;
        return aOrder.compareTo(bOrder);
      });

      setState(() {
        _isCorrectionsLoading = false;
        _correctionRequests = combined;
      });
    }
  }

  List<Map<String, dynamic>> get filteredAttendance {
    return attendanceData.where((d) {
      final Map<String, dynamic> userMap = d['user'] is Map ? d['user'] : d;
      final fname =
          userMap['first_name']?.toString() ??
          d['first_name']?.toString() ??
          '';
      final lname =
          userMap['last_name']?.toString() ?? d['last_name']?.toString() ?? '';
      final nameStr = fname.isNotEmpty
          ? '$fname $lname'.trim()
          : (userMap['name']?.toString() ?? d['name']?.toString() ?? 'Unknown');

      final search = searchController.text.toLowerCase();
      bool matchSearch = nameStr.toLowerCase().contains(search);

      // Match by ID if selected
      bool matchEmp =
          selectedEmployeeId == null ||
          selectedEmployeeId == "all" ||
          d['user_id']?.toString() == selectedEmployeeId;

      String statusStr =
          d['attendance_status']?.toString() ??
          d['status']?.toString() ??
          '';
      bool matchStatus =
          selectedStatus == "All Status" ||
          statusStr.toLowerCase().contains(selectedStatus.toLowerCase());

      return matchSearch && matchEmp && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          toolbarHeight: 0,
          bottom: TabBar(
            labelColor: AppColors.navy,
            unselectedLabelColor: AppColors.grey400,
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: "Attendance Logs"),
              Tab(text: "Correction Requests"),
            ],
          ),
        ),
        body: TabBarView(children: [_buildLogsTab(), _buildCorrectionsTab()]),
      ),
    );
  }

  Widget _buildLogsTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              "Team Attendance",
              "Review and manage team attendance logs",
            ),
            const SizedBox(height: 24),
            // Summary stats grid (always show when data loaded)
            if (!isLoading && attendanceData.isNotEmpty) ...[
              _buildSummaryGrid(),
              const SizedBox(height: 24),
            ],
            _buildFilterSection(),
            const SizedBox(height: 24),
            // Error state
            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text('API Error', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.red, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_errorMessage, style: GoogleFonts.inter(fontSize: 13, color: Colors.red.shade700)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _fetchAttendance,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading attendance data...'),
                        ],
                      ),
                    ),
                  )
                : !_hasSearched
                ? _buildEmptyState(
                    'Please select filters and click Search to view attendance logs.',
                  )
                : filteredAttendance.isEmpty
                ? _buildEmptyState('No attendance records found for the selected period.')
                : _buildGroupedAttendanceTables(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionsTab() {
    return RefreshIndicator(
      onRefresh: _fetchCorrections,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              "Correction Requests",
              "Manage employee attendance regulation requests",
            ),
            const SizedBox(height: 24),
            if (_isCorrectionsLoading && _correctionRequests.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (_correctionRequests.isEmpty)
              _buildEmptyState("No pending correction requests.")
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _correctionRequests.length,
                itemBuilder: (context, index) {
                  return _buildCorrectionRequestCard(
                    _correctionRequests[index],
                  );
                },
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String sub) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sub,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.grey400,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (title == "Team Attendance")
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text("Export", style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSummaryCard(
            "Team",
            _totalEmpCount.toString().padLeft(2, '0'),
            Icons.people_alt_rounded,
            AppColors.navy,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "Present",
            _presentCount.toString().padLeft(2, '0'),
            Icons.check_circle_rounded,
            AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "Absent",
            _absentCount.toString().padLeft(2, '0'),
            Icons.cancel_rounded,
            AppColors.error,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "Late",
            _lateCount.toString().padLeft(2, '0'),
            Icons.access_time_filled_rounded,
            AppColors.warning,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "On Leave",
            _leaveCount.toString().padLeft(2, '0'),
            Icons.beach_access_rounded,
            Colors.purple,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "Half Day",
            _halfDayCount.toString().padLeft(2, '0'),
            Icons.brightness_medium_rounded,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "Weekly Off",
            _offCount.toString().padLeft(2, '0'),
            Icons.event_available_rounded,
            Colors.blueGrey,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "OT",
            _otCount.toString().padLeft(2, '0'),
            Icons.more_time_rounded,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search employee name...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDropdown(
                    null,
                    selectedEmployeeId ?? "all",
                    employees
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e['id'],
                            child: Text(e['name']!),
                          ),
                        )
                        .toList(),
                    (v) {
                      setState(() {
                        selectedEmployeeId = v;
                        selectedEmployee = employees.firstWhere(
                          (e) => e['id'] == v,
                        )['name']!;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDatePicker(),
                  const SizedBox(width: 8),
                  _buildDropdown(
                    null,
                    selectedStatus,
                    statuses
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    (v) => setState(() => selectedStatus = v!),
                  ),
                  const SizedBox(width: 8),
                  _buildDropdown(
                    null,
                    selectedMonth,
                    months
                        .map(
                          (m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(m),
                          ),
                        )
                        .toList(),
                    (v) => setState(() => selectedMonth = v!),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _fetchAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Search"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = null;
                        selectedEmployee = "All Employees";
                        selectedEmployeeId = "all";
                        selectedStatus = "All Status";
                        selectedMonth = DateFormat(
                          'MMMM',
                        ).format(DateTime.now());
                        searchController.clear();
                        _hasSearched = true;
                        attendanceData = [];
                      });
                      _fetchAttendance();
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: AppColors.grey200),
                    ),
                    child: const Text("Clear"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String? label,
    String value,
    List<DropdownMenuItem<String>> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
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
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (d != null) setState(() => selectedDate = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: AppColors.navy,
            ),
            const SizedBox(width: 6),
            Text(
              selectedDate == null
                  ? "Date"
                  : DateFormat('dd/MM').format(selectedDate!),
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

  Widget _buildGroupedAttendanceTables() {
    // Group by date
    final Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var data in filteredAttendance) {
      String dateKey = 'Unknown Date';
      if (data['date'] != null) {
        try {
          final dt = DateTime.parse(data['date'].toString()).toLocal();
          dateKey = DateFormat('yyyy-MM-dd').format(dt);
        } catch (e) {
          final str = data['date'].toString();
          if (str.length >= 10) {
            dateKey = str.substring(0, 10);
          } else {
            dateKey = str;
          }
        }
      }

      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(data);
    }

    // Sort dates descending
    final List<String> sortedDates = groupedData.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 32),
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dailyData = groupedData[dateKey]!;
        return _buildDailyTableCard(dateKey, dailyData);
      },
    );
  }

  Widget _buildDailyTableCard(String dateStr, List<Map<String, dynamic>> dailyData) {
    // Calculate Daily Summary
    int present = 0;
    int absent = 0;
    int leaveOff = 0;
    int late = 0;
    int halfDay = 0;
    double otHours = 0.0;
    double totalWorkMinutes = 0.0;

    for (var data in dailyData) {
      final statusStr = (data['attendance_status']?.toString() ?? data['status']?.toString() ?? '').toLowerCase();
      final isLate = data['is_late'] == 1 || data['is_late'] == true || statusStr.contains('late');
      
      if (statusStr.contains('absent') || statusStr.isEmpty) {
        absent++;
      } else if (statusStr.contains('leave') || statusStr.contains('off') || statusStr.contains('holiday')) {
        leaveOff++;
      } else if (statusStr.contains('half')) {
        // Backend logic: half day counts as BOTH present AND half day
        halfDay++;
        present++;
      } else if (isLate || statusStr.contains('late')) {
        late++;
        present++; // Late is also present
      } else if (statusStr.contains('present') || statusStr.contains('working')) {
        present++;
      } else {
        if (data['clock_in'] != null) {
          present++;
        } else {
          absent++;
        }
      }

      otHours += double.tryParse(data['ot_hours']?.toString() ?? '0') ?? 0.0;

      final String clockInRaw = data['clock_in']?.toString() ?? '';
      final String clockOutRaw = data['clock_out']?.toString() ?? '';

      final DateTime? clockIn = DateTime.tryParse(clockInRaw)?.toLocal();
      final DateTime? clockOut = DateTime.tryParse(clockOutRaw)?.toLocal();

      if (clockIn != null && clockOut != null) {
        totalWorkMinutes += clockOut.difference(clockIn).inMinutes;
      }
    }

    // Account for all employees — those without any attendance record for this day are absent
    final int accounted = present + absent + leaveOff;
    if (_totalEmpCount > accounted) {
      absent += _totalEmpCount - accounted;
    }

    final int totalWorkH = (totalWorkMinutes / 60).floor();
    final int totalWorkM = (totalWorkMinutes % 60).toInt();
    final String totalWorkStr = "${totalWorkH}h ${totalWorkM}m";

    // Format Date string
    DateTime? dt = DateTime.tryParse(dateStr)?.toLocal();
    String displayDate = dateStr;
    bool isWeekend = false;
    if (dt != null) {
      displayDate = DateFormat('dd MMM yyyy (EEEE)').format(dt);
      isWeekend = dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppColors.navy, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      displayDate,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                    if (isWeekend) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("Weekend", style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_history, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text("Total Work: $totalWorkStr", style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text("Export"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // TABLE (Scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1000,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      border: Border(top: BorderSide(color: AppColors.grey100), bottom: BorderSide(color: AppColors.grey100)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: _tableHeader("Employee")),
                        Expanded(flex: 2, child: _tableHeader("Shift Times")),
                        Expanded(flex: 2, child: _tableHeader("Breaks (Total)")),
                        Expanded(flex: 2, child: _tableHeader("Calculations")),
                        Expanded(flex: 2, child: _tableHeader("Actual Work Hours")),
                        Expanded(flex: 1, child: _tableHeader("Status")),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dailyData.length,
                    separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: AppColors.grey100),
                    itemBuilder: (context, index) {
                      return _buildAttendanceTableRow(dailyData[index]);
                    },
                  ),
                ],
              ),
            ),
          ),

          // SUMMARY FOOTER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: AppColors.grey100)),
            ),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_chart_outlined, size: 16, color: AppColors.grey600),
                    const SizedBox(width: 8),
                    Text("Daily Summary:", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ],
                ),
                _summaryBadge("Present: $present", AppColors.success),
                _summaryBadge("Absent: $absent", AppColors.warning.withOpacity(0.9)),
                _summaryBadge("Leave/Off: $leaveOff", Colors.blue),
                _summaryBadge("Late: $late", AppColors.gold),
                _summaryBadge("Half Day: $halfDay", Colors.deepOrange),
                _summaryBadge("OT: ${otHours.toStringAsFixed(1)}h", AppColors.error.withOpacity(0.8)),
                _summaryBadge("Total Work: $totalWorkStr", AppColors.navy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  Widget _tableHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildAttendanceTableRow(Map<String, dynamic> data) {
    final Map<String, dynamic> userMap = data['user'] is Map ? data['user'] : data;
    final String firstName = userMap['first_name']?.toString() ?? data['first_name']?.toString() ?? '';
    final String lastName = userMap['last_name']?.toString() ?? data['last_name']?.toString() ?? '';
    final String nameStr = firstName.isNotEmpty ? '$firstName $lastName'.trim() : (userMap['name']?.toString() ?? data['name']?.toString() ?? 'Unknown');
    final String empId = userMap['id']?.toString() ?? data['user_id']?.toString() ?? '0';
    final String role = userMap['role']?.toString() ?? 'Employee'; // Fallback role if missing

    final statusStr = data['attendance_status']?.toString() ?? data['status']?.toString() ?? '';
    final statusColor = _getStatusColor(statusStr);

    final String clockInRaw = data['clock_in']?.toString() ?? '';
    final String clockOutRaw = data['clock_out']?.toString() ?? '';

    final DateTime? clockIn = DateTime.tryParse(clockInRaw)?.toLocal();
    final DateTime? clockOut = DateTime.tryParse(clockOutRaw)?.toLocal();

    final String clockInStr = clockIn != null ? DateFormat('hh:mm a').format(clockIn) : (clockInRaw.isNotEmpty ? clockInRaw : '--:--');
    final String clockOutStr = clockOut != null ? DateFormat('hh:mm a').format(clockOut) : (clockOutRaw.isNotEmpty ? clockOutRaw : '--:--');
    
    bool isLate = data['is_late'] == 1 || data['is_late'] == true || statusStr.toLowerCase().contains('late');

    String actualStr = data['actual']?.toString() ?? "0h 0m";
    int workMinutes = 0;
    if (clockIn != null && clockOut == null) {
      actualStr = "WORKING...";
    } else if (clockIn != null && clockOut != null) {
      final Duration workDuration = clockOut.difference(clockIn);
      workMinutes = workDuration.inMinutes;
      actualStr = "${(workMinutes / 60).floor()}h ${workMinutes % 60}m";
    }

    final String totalStayStr = actualStr;
    final String lateStr = isLate ? "Late: Yes" : ""; 
    final String breakStr = data['breaks']?.toString() ?? "-";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Employee
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "#$empId",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameStr,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Shift Times
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.login_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(clockInStr, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    if (isLate) ...[
                      const SizedBox(width: 8),
                      Text("Late", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ]
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(clockOutStr, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ],
                ),
              ],
            ),
          ),
          // Breaks (Total)
          Expanded(
            flex: 2,
            child: Text(
              breakStr,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600, fontWeight: FontWeight.w500),
            ),
          ),
          // Calculations
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Stay: $totalStayStr", style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.check, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text("Break within 1h", style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (isLate) ...[
                  const SizedBox(height: 6),
                  Text(lateStr, style: GoogleFonts.inter(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500)),
                ]
              ],
            ),
          ),
          // Actual Work Hours
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actualStr,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.error),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (workMinutes / 480).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusStr,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) => Center(
    heightFactor: 4,
    child: Column(
      children: [
        Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey200),
        const SizedBox(height: 12),
        Text(msg, style: GoogleFonts.inter(color: AppColors.grey400)),
      ],
    ),
  );

  Widget _buildCorrectionRequestCard(dynamic req) {
    final user = req['user'] ?? {};
    final fname = user['first_name']?.toString() ?? '';
    final lname = user['last_name']?.toString() ?? '';
    final name = fname.isNotEmpty
        ? '$fname $lname'.trim()
        : (user['name']?.toString() ?? 'Employee');

    // Normalize status — backend may return 'reject' or 'rejected', 'approve' or 'approved'
    final rawStatus = req['status']?.toString().toLowerCase() ?? 'pending';
    final String status;
    if (rawStatus.contains('approved') || rawStatus == 'approve') {
      status = 'approved';
    } else if (rawStatus.contains('reject')) {
      status = 'rejected';
    } else {
      status = 'pending';
    }

    Color borderColor;
    Color avatarColor;
    if (status == 'approved') {
      borderColor = AppColors.success;
      avatarColor = AppColors.success;
    } else if (status == 'rejected') {
      borderColor = AppColors.error;
      avatarColor = AppColors.error;
    } else {
      borderColor = AppColors.grey100;
      avatarColor = AppColors.gold;
    }

    final adminRemark =
        req['admin_remark']?.toString() ?? req['remark']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: status == 'pending' ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status banner for approved/rejected
          if (status != 'pending')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color:
                    (status == 'approved' ? AppColors.success : AppColors.error)
                        .withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == 'approved'
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 16,
                    color: status == 'approved'
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status == 'approved' ? 'APPROVED' : 'REJECTED',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: status == 'approved'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: avatarColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        req['date'] != null
                            ? DateFormat('EEEE, MMM dd').format(
                                DateTime.parse(
                                  req['date'].toString(),
                                ).toLocal(),
                              )
                            : '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _correctionTime("IN", req['clock_in'] ?? '--:--'),
                          const SizedBox(width: 24),
                          _correctionTime("OUT", req['clock_out'] ?? '--:--'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Reason: ${req['reason'] ?? ''}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.navy.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Show admin remark if available for approved/rejected
                      if (adminRemark.isNotEmpty && status != 'pending') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                (status == 'approved'
                                        ? AppColors.success
                                        : AppColors.error)
                                    .withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Admin Remark: $adminRemark",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: status == 'approved'
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
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
          const Divider(height: 1),
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          _handleCorrectionAction(req['id'], 'rejected'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text(
                        "Reject",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleCorrectionAction(req['id'], 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Approve",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                status == 'approved'
                    ? '✓ Request has been approved'
                    : '✗ Request has been rejected',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: status == 'approved'
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _correctionTime(String l, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(fontSize: 10, color: AppColors.grey400)),
      Text(
        v,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
      ),
    ],
  );

  Future<void> _handleCorrectionAction(int id, String status) async {
    final remarkRes = await showDialog<String>(
      context: context,
      builder: (context) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text("$status Request"),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(hintText: "Remark..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, c.text),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
    if (remarkRes == null) return;
    final res = await ApiService.updateCorrectionStatus(id, status, remarkRes);
    if (res['error'] == false) {
      _fetchCorrections();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request $status successfully"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Color _getStatusColor(String s) {
    s = s.toLowerCase();
    if (s.contains('present') || s.contains('working') || s.contains('late')) {
      if (s.contains('late')) return AppColors.warning;
      if (s.contains('half')) return Colors.orange;
      return AppColors.success;
    }
    if (s.contains('absent')) return AppColors.error;
    if (s.contains('leave')) return Colors.purple;
    if (s.contains('off') || s.contains('holiday')) return Colors.blueGrey;
    return AppColors.grey600;
  }
}
