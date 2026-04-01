import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class TeamAttendanceViewScreen extends StatefulWidget {
  const TeamAttendanceViewScreen({super.key});

  @override
  State<TeamAttendanceViewScreen> createState() => _TeamAttendanceViewScreenState();
}

class _TeamAttendanceViewScreenState extends State<TeamAttendanceViewScreen> {
  // Filters & State for Attendance Logs
  String selectedEmployee = "All Employees";
  String? selectedEmployeeId;
  String selectedStatus = "All Status";
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  DateTime? selectedDate;
  final searchController = TextEditingController();

  final List<Map<String, String>> employees = [
    {"id": "all", "name": "All Employees"}
  ];
  final List<String> statuses = [
    "All Status", "Present", "Absent", "Late", "On Leave", "Half Day", "Weekly Off", "Overtime",
  ];
  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  List<Map<String, dynamic>> attendanceData = [];
  bool isLoading = true;

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

    // 1. Fetch Employee Profiles for Dropdown
    try {
      final empRes = await ApiService.getEmployeeProfiles();
      if (empRes['error'] == false) {
        final List empData = empRes['data'] ?? [];
        _totalEmpCount = empData.length;

        // Reset and populate employees list
        List<Map<String, String>> fetchedEmps = [
          {"id": "all", "name": "All Employees"}
        ];
        
        for (var emp in empData) {
          final fname = emp['first_name']?.toString() ?? '';
          final lname = emp['last_name']?.toString() ?? '';
          final fullName = '$fname $lname'.trim();
          final id = emp['user_id']?.toString() ?? emp['id']?.toString() ?? '';
          if (fullName.isNotEmpty && id.isNotEmpty) {
            fetchedEmps.add({"id": id, "name": fullName});
          }
        }
        
        setState(() {
          employees.clear();
          employees.addAll(fetchedEmps);
        });
      }
    } catch (e) {
      debugPrint("Error fetching employees: $e");
    }

    // 2. Prepare Date/Filter strings
    String? dateStr;
    String? startStr;
    String? endStr;

    if (selectedDate != null) {
      dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    } else {
      final monthIndex = months.indexOf(selectedMonth) + 1;
      if (monthIndex > 0) {
        final now = DateTime.now();
        final year = now.year;
        final start = DateTime(year, monthIndex, 1);
        final end = DateTime(year, monthIndex + 1, 0).subtract(const Duration(seconds: 1)); // End of month
        startStr = DateFormat('yyyy-MM-dd').format(start);
        endStr = DateFormat('yyyy-MM-dd').format(end);
      }
    }

    // 3. Fetch Attendance Records
    try {
      final res = await ApiService.getAllAttendances(
        date: dateStr,
        startDate: startStr,
        endDate: endStr,
        userId: selectedEmployeeId == "all" ? null : selectedEmployeeId,
      );

      if (!mounted) return;

      if (res['error'] == false) {
        final List dataList = res['data'] ?? [];
        
        // Reset summary counts
        _presentCount = 0; _absentCount = 0; _lateCount = 0; _leaveCount = 0;
        _halfDayCount = 0; _offCount = 0; _otCount = 0;

        final Map<String, Map<String, dynamic>> userStatsMap = {};

        for (var item in dataList) {
          final userId = item['user_id']?.toString() ?? '0';
          userStatsMap.putIfAbsent(userId, () => {
            'present': 0, 'absent': 0, 'late': 0, 'leave': 0, 'half': 0, 'off': 0, 'ot': 0.0, 'totalWork': 0.0
          });

          final status = (item['attendance_status']?.toString() ?? '').toLowerCase();
          final isLate = item['is_late'] == 1 || item['is_late'] == true || status.contains('late');
          final otHours = double.tryParse(item['ot_hours']?.toString() ?? '0') ?? 0.0;
          
          if (status.contains('present') || status.contains('working') || isLate) {
            _presentCount++; userStatsMap[userId]!['present']++;
            if (isLate) { _lateCount++; userStatsMap[userId]!['late']++; }
            if (status.contains('half')) { _halfDayCount++; userStatsMap[userId]!['half']++; }
          } else if (status.contains('absent')) {
            _absentCount++; userStatsMap[userId]!['absent']++;
          } else if (status.contains('leave') || status.contains('official_leave')) {
            _leaveCount++; userStatsMap[userId]!['leave']++;
          } else if (status.contains('off') || status.contains('holiday') || status.contains('weekly_off')) {
            _offCount++; userStatsMap[userId]!['off']++;
          }
          
          if (otHours > 0) { _otCount++; userStatsMap[userId]!['ot'] += otHours; }

          // Calculate work hours if available
          final DateTime? cin = item['clock_in'] != null ? DateTime.tryParse(item['clock_in'].toString()) : null;
          final DateTime? cout = item['clock_out'] != null ? DateTime.tryParse(item['clock_out'].toString()) : null;
          if (cin != null && cout != null) {
             userStatsMap[userId]!['totalWork'] += cout.difference(cin).inMinutes / 60.0;
          }
        }

        setState(() {
          attendanceData = List<Map<String, dynamic>>.from(dataList);

          // Enrich each data item with its user's summary stats for the current view
          for (var i = 0; i < attendanceData.length; i++) {
            final uId = attendanceData[i]['user_id']?.toString() ?? '0';
            final s = userStatsMap[uId];
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
          isLoading = false;
        });
      } else {
        setState(() {
          attendanceData = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCorrections() async {
    setState(() => _isCorrectionsLoading = true);
    final res = await ApiService.getManagerCorrections(status: 'pending');
    if (mounted) {
      setState(() {
        _isCorrectionsLoading = false;
        if (res['error'] == false) {
          _correctionRequests = res['data'] ?? [];
        }
      });
    }
  }

  List<Map<String, dynamic>> get filteredAttendance {
    return attendanceData.where((d) {
      final Map<String, dynamic> userMap = d['user'] is Map ? d['user'] : d;
      final fname =
          userMap['first_name']?.toString() ?? d['first_name']?.toString() ?? '';
      final lname =
          userMap['last_name']?.toString() ?? d['last_name']?.toString() ?? '';
      final nameStr = fname.isNotEmpty
          ? '$fname $lname'.trim()
          : (userMap['name']?.toString() ?? d['name']?.toString() ?? 'Unknown');

      final search = searchController.text.toLowerCase();
      bool matchSearch = nameStr.toLowerCase().contains(search);

      // Match by ID if selected
      bool matchEmp = selectedEmployeeId == null ||
          selectedEmployeeId == "all" ||
          d['user_id']?.toString() == selectedEmployeeId;

      String statusStr =
          d['attendance_status']?.toString() ?? d['status']?.toString() ?? 'Present';
      bool matchStatus = selectedStatus == "All Status" ||
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
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: "Attendance Logs"),
              Tab(text: "Correction Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLogsTab(),
            _buildCorrectionsTab(),
          ],
        ),
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
            _buildHeader("Team Attendance", "Review and manage team attendance logs"),
            const SizedBox(height: 24),
            _buildSummaryGrid(),
            const SizedBox(height: 24),
            _buildFilterSection(),
            const SizedBox(height: 24),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAttendance.isEmpty
                    ? _buildEmptyState("No attendance records found.")
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredAttendance.length,
                        itemBuilder: (context, index) {
                          return _buildEmployeeAttendanceCard(filteredAttendance[index]);
                        },
                      ),
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
            _buildHeader("Correction Requests", "Manage regulation requests from your team"),
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
                  return _buildCorrectionRequestCard(_correctionRequests[index]);
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
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                      letterSpacing: -0.5),
                  overflow: TextOverflow.ellipsis),
              Text(sub,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
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
                      borderRadius: BorderRadius.circular(10))),
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
          _buildSummaryCard("Team", _totalEmpCount.toString().padLeft(2, '0'), Icons.people_alt_rounded, AppColors.navy),
          const SizedBox(width: 12),
          _buildSummaryCard("Present", _presentCount.toString().padLeft(2, '0'), Icons.check_circle_rounded, AppColors.success),
          const SizedBox(width: 12),
          _buildSummaryCard("Absent", _absentCount.toString().padLeft(2, '0'), Icons.cancel_rounded, AppColors.error),
          const SizedBox(width: 12),
          _buildSummaryCard("Late", _lateCount.toString().padLeft(2, '0'), Icons.access_time_filled_rounded, AppColors.warning),
          const SizedBox(width: 12),
          _buildSummaryCard("On Leave", _leaveCount.toString().padLeft(2, '0'), Icons.beach_access_rounded, Colors.purple),
          const SizedBox(width: 12),
          _buildSummaryCard("Half Day", _halfDayCount.toString().padLeft(2, '0'), Icons.brightness_medium_rounded, Colors.orange),
          const SizedBox(width: 12),
          _buildSummaryCard("Weekly Off", _offCount.toString().padLeft(2, '0'), Icons.event_available_rounded, Colors.blueGrey),
          const SizedBox(width: 12),
          _buildSummaryCard("OT", _otCount.toString().padLeft(2, '0'), Icons.more_time_rounded, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 140, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey400)),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.grey100)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search team member...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true, fillColor: AppColors.offWhite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                          .map((e) => DropdownMenuItem<String>(
                              value: e['id'], child: Text(e['name']!)))
                          .toList(), (v) {
                    setState(() {
                      selectedEmployeeId = v;
                      selectedEmployee = employees
                          .firstWhere((e) => e['id'] == v)['name']!;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildDatePicker(),
                  const SizedBox(width: 8),
                  _buildDropdown(
                      null,
                      selectedStatus,
                      statuses
                          .map((s) => DropdownMenuItem<String>(
                              value: s, child: Text(s)))
                          .toList(),
                      (v) => setState(() => selectedStatus = v!)),
                  const SizedBox(width: 8),
                  _buildDropdown(
                      null,
                      selectedMonth,
                      months
                          .map((m) => DropdownMenuItem<String>(
                              value: m, child: Text(m)))
                          .toList(),
                      (v) => setState(() => selectedMonth = v!)),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _fetchAttendance, style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Search")),
                  const SizedBox(width: 8),
                  OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedDate = null;
                          selectedEmployee = "All Employees";
                          selectedEmployeeId = "all";
                          selectedStatus = "All Status";
                          selectedMonth =
                              DateFormat('MMMM').format(DateTime.now());
                          searchController.clear();
                        });
                        _fetchAttendance();
                      },
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: AppColors.grey200)),
                      child: const Text("Clear")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String? label, String value,
      List<DropdownMenuItem<String>> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey100)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: GoogleFonts.inter(
              color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
        if (d != null) setState(() => selectedDate = d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.grey100)),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.navy),
            const SizedBox(width: 6),
            Text(selectedDate == null ? "Date" : DateFormat('dd/MM').format(selectedDate!), style: GoogleFonts.inter(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeAttendanceCard(Map<String, dynamic> data) {
    final Map<String, dynamic> userMap = data['user'] is Map ? data['user'] : data;
    final String firstName = userMap['first_name']?.toString() ?? data['first_name']?.toString() ?? '';
    final String lastName = userMap['last_name']?.toString() ?? data['last_name']?.toString() ?? '';
    final String nameStr = firstName.isNotEmpty ? '$firstName $lastName'.trim() : (userMap['name']?.toString() ?? data['name']?.toString() ?? 'Unknown');

    final statusStr = data['attendance_status']?.toString() ?? data['status']?.toString() ?? 'Present';
    final statusColor = _getStatusColor(statusStr);
    final stats = (data['stats'] is Map) ? data['stats'] : {};
    
    final String shiftStr = data['shift']?.toString() ?? "09:00 AM - 06:00 PM";
    final String breaksStr = data['breaks']?.toString() ?? "0h 00m";
    String actualStr = data['actual']?.toString() ?? "0h 00m";
    
    final DateTime? clockIn = data['clock_in'] != null ? DateTime.tryParse(data['clock_in'].toString()) : null;
    final DateTime? clockOut = data['clock_out'] != null ? DateTime.tryParse(data['clock_out'].toString()) : null;

    if (clockIn != null && clockOut == null) {
      actualStr = "WORKING...";
    } else if (clockIn != null && clockOut != null) {
      final Duration workDuration = clockOut.difference(clockIn);
      final int workMinutes = workDuration.inMinutes;
      actualStr = "${(workMinutes/60).floor()}h ${workMinutes%60}m";
    }

    final double otHours = double.tryParse(data['ot_hours']?.toString() ?? '0') ?? 0;
    final String otStr = otHours > 0 ? "${otHours.toStringAsFixed(1)}h OT" : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grey100)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: AppColors.navy.withOpacity(0.05), child: Text(nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'E', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nameStr, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    Row(children: [
                      Icon(Icons.calendar_today_rounded, size: 10, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(data['date'] != null ? DateFormat('dd MMM, yyyy').format(DateTime.parse(data['date'].toString()).toLocal()) : 'N/A', style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400, fontWeight: FontWeight.w500)),
                    ]),
                  ]),
                ),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(statusStr, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor))),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildTableItem("Shift Timing", shiftStr)),
                Expanded(child: _buildTableItem("Breaks", breaksStr, align: TextAlign.center)),
                Expanded(child: _buildTableItem("Actual", actualStr, isBold: true, align: TextAlign.end)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16), color: AppColors.offWhite.withOpacity(0.5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Monthly Breakdown", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12, runSpacing: 12, alignment: WrapAlignment.spaceEvenly,
                children: [
                  _buildMiniStat("Present", stats['present']?.toString() ?? "0", AppColors.success),
                  _buildMiniStat("Absent", stats['absent']?.toString() ?? "0", AppColors.error),
                  _buildMiniStat("Leave", stats['leave']?.toString() ?? "0", Colors.purple),
                  _buildMiniStat("Late", stats['late']?.toString() ?? "0", AppColors.warning),
                  _buildMiniStat("Half Day", stats['half']?.toString() ?? "0", Colors.orange),
                  _buildMiniStat("OT", stats['ot']?.toString() ?? "0h", AppColors.gold),
                  _buildMiniStat("Off", stats['off']?.toString() ?? "0", Colors.blueGrey),
                ],
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Total Monthly Work Hours", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
                  if (otStr.isNotEmpty) Text("+ $otStr (Record Overtime)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.teal)),
                ]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
                  child: Text(stats['totalWork']?.toString() ?? "0h", style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.gold))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableItem(String label, String value, {bool isBold = false, TextAlign align = TextAlign.start}) {
    final crossAlign = align == TextAlign.center ? CrossAxisAlignment.center : (align == TextAlign.end ? CrossAxisAlignment.end : CrossAxisAlignment.start);
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grey400), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) => Column(children: [
    Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.grey400)),
  ]);

  Widget _buildEmptyState(String msg) => Center(heightFactor: 4, child: Column(children: [Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey200), const SizedBox(height: 12), Text(msg, style: GoogleFonts.inter(color: AppColors.grey400))]));

  Widget _buildCorrectionRequestCard(dynamic req) {
    final user = req['user'] ?? {};
    final fname = user['first_name']?.toString() ?? '';
    final lname = user['last_name']?.toString() ?? '';
    final name = fname.isNotEmpty ? '$fname $lname'.trim() : (user['name']?.toString() ?? 'Employee');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.grey100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 24, backgroundColor: AppColors.gold.withOpacity(0.1), child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'E', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.gold))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    Text(req['date'] != null ? DateFormat('EEEE, MMM dd').format(DateTime.parse(req['date'].toString()).toLocal()) : '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(children: [
                      _correctionTime("IN", req['clock_in'] ?? '--:--'),
                      const SizedBox(width: 24),
                      _correctionTime("OUT", req['clock_out'] ?? '--:--'),
                    ]),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.all(12), width: double.infinity, decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12)),
                      child: Text("Reason: ${req['reason'] ?? ''}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.navy.withOpacity(0.7), fontWeight: FontWeight.w500))),
                  ]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: TextButton(onPressed: () => _handleCorrectionAction(req['id'], 'rejected'), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w700)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => _handleCorrectionAction(req['id'], 'approved'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Approve", style: TextStyle(fontWeight: FontWeight.w700)))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _correctionTime(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, color: AppColors.grey400)), Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy))]);

  Future<void> _handleCorrectionAction(int id, String status) async {
    final remarkRes = await showDialog<String>(context: context, builder: (context) {
      final c = TextEditingController();
      return AlertDialog(title: Text("$status Request"), content: TextField(controller: c, decoration: const InputDecoration(hintText: "Remark...")), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text("Confirm"))]);
    });
    if (remarkRes == null) return;
    final res = await ApiService.updateCorrectionStatus(id, status, remarkRes);
    if (res['error'] == false) { _fetchCorrections(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request $status successfully"), backgroundColor: AppColors.success)); }
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
