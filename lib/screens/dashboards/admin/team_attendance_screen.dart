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
  String selectedEmployee = "All Employees";
  String selectedStatus = "All Status";
  String selectedMonth = "March";
  DateTime? selectedDate;
  final searchController = TextEditingController();

  final List<String> employees = ["All Employees"];
  final List<String> statuses = [
    "All Status",
    "Present",
    "Absent",
    "Late",
    "On Leave",
  ];
  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
  ];

  List<Map<String, dynamic>> attendanceData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {});
    });
    _fetchAttendance();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendance() async {
    setState(() => isLoading = true);
    final res = await ApiService.getAllAttendances();
    print("ATTENDANCE API RESPONSE: $res");
    if (!mounted) return;

    if (res['error'] == false) {
      final List dataList = res['data'] ?? [];

      final Set<String> empSet = {"All Employees"};
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
        final nameStr = fname.isNotEmpty
            ? '$fname $lname'.trim()
            : (userMap['name']?.toString() ??
                  item['name']?.toString() ??
                  'Unknown');
        if (nameStr != 'Unknown') empSet.add(nameStr);
      }

      setState(() {
        attendanceData = List<Map<String, dynamic>>.from(dataList);
        employees.clear();
        employees.addAll(empSet);
        if (!employees.contains(selectedEmployee)) {
          selectedEmployee = "All Employees";
        }
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to load attendance')),
      );
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

      bool matchEmp =
          selectedEmployee == "All Employees" || nameStr == selectedEmployee;

      String statusStr = d['status']?.toString() ?? 'Present';
      bool matchStatus =
          selectedStatus == "All Status" ||
          statusStr.toLowerCase() == selectedStatus.toLowerCase();

      return matchSearch && matchEmp && matchStatus;
    }).toList();
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
            _buildSummaryGrid(),
            const SizedBox(height: 24),
            _buildFilterSection(),
            const SizedBox(height: 24),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAttendance.isEmpty
                ? Center(
                    child: Text(
                      "No attendance records found.",
                      style: GoogleFonts.inter(
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAttendance.length,
                    itemBuilder: (context, index) {
                      return _buildEmployeeAttendanceCard(
                        filteredAttendance[index],
                      );
                    },
                  ),
            const SizedBox(height: 100),
          ],
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
              "Attendance Logs",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              "Per-employee detailed attendance logs",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 20),
          label: const Text("Export Report"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
            "Today Present",
            "35",
            Icons.check_circle_rounded,
            AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "Today Absent",
            "03",
            Icons.cancel_rounded,
            AppColors.error,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "Today Late",
            "02",
            Icons.access_time_filled_rounded,
            AppColors.warning,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            "On Leave",
            "02",
            Icons.beach_access_rounded,
            Colors.purple,
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
        border: Border.all(color: color.withValues(alpha: 0.1)),
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
                    selectedEmployee,
                    employees,
                    (v) => setState(() => selectedEmployee = v!),
                  ),
                  const SizedBox(width: 8),
                  _buildDatePicker(),
                  const SizedBox(width: 8),
                  _buildDropdown(
                    null,
                    selectedStatus,
                    statuses,
                    (v) => setState(() => selectedStatus = v!),
                  ),
                  const SizedBox(width: 8),
                  _buildDropdown(
                    null,
                    selectedMonth,
                    months,
                    (v) => setState(() => selectedMonth = v!),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
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
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: AppColors.grey200),
                    ),
                    child: const Text("Reset"),
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
    List<String> items,
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
          items: items
              .map(
                (String item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
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
    );
  }

  Widget _buildEmployeeAttendanceCard(Map<String, dynamic> data) {
    final statusColor = _getStatusColor(
      data['status']?.toString() ?? 'Present',
    );

    final Map<String, dynamic> userMap = data['user'] is Map
        ? data['user']
        : data;
    final String firstName =
        userMap['first_name']?.toString() ??
        data['first_name']?.toString() ??
        '';
    final String lastName =
        userMap['last_name']?.toString() ?? data['last_name']?.toString() ?? '';
    final String nameStr = firstName.isNotEmpty
        ? '$firstName $lastName'.trim()
        : (userMap['name']?.toString() ??
              data['name']?.toString() ??
              'Unknown');

    final String idStr =
        userMap['employee_id']?.toString() ??
        data['employee_id']?.toString() ??
        userMap['id']?.toString() ??
        data['id']?.toString() ??
        'N/A';
    final String statusStr = data['status']?.toString() ?? 'Present';

    // Attempting safe extraction from properties if missing. You can adjust default fallback values.
    final stats = (data['stats'] is Map) ? data['stats'] : {};
    final String shiftStr = data['shift']?.toString() ?? "09:00 AM - 06:00 PM";
    final String breaksStr = data['breaks']?.toString() ?? "0h 00m";
    final String actualStr = data['actual']?.toString() ?? "0h 00m";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.navy.withValues(alpha: 0.05),
                  child: Text(
                    nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'E',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
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
                        nameStr,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        idStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Information "Table" Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTableItem("Shift Timing", shiftStr),
                _buildTableItem("Breaks Calc", breaksStr),
                _buildTableItem("Actual Work", actualStr, isBold: true),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.offWhite.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Monthly Breakdown",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    _buildMiniStat(
                      "Present",
                      stats['present']?.toString() ?? "0",
                      AppColors.success,
                    ),
                    _buildMiniStat(
                      "Absent",
                      stats['absent']?.toString() ?? "0",
                      AppColors.error,
                    ),
                    _buildMiniStat(
                      "Leave",
                      stats['leave']?.toString() ?? "0",
                      Colors.purple,
                    ),
                    _buildMiniStat(
                      "Late",
                      stats['late']?.toString() ?? "0",
                      AppColors.warning,
                    ),
                    _buildMiniStat(
                      "Half Day",
                      stats['half']?.toString() ?? "0",
                      Colors.orange,
                    ),
                    _buildMiniStat(
                      "OT",
                      stats['ot']?.toString() ?? "0h",
                      AppColors.goldDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Footer Total Work
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Monthly Work Hours",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    stats['totalWork']?.toString() ?? "0h",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableItem(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.grey400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return AppColors.success;
      case 'Late':
        return AppColors.warning;
      case 'Absent':
        return AppColors.error;
      case 'On Leave':
        return Colors.purple;
      default:
        return AppColors.grey600;
    }
  }
}
