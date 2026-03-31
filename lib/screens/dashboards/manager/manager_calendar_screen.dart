import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api_service.dart';

class ManagerCalendarScreen extends StatefulWidget {
  const ManagerCalendarScreen({super.key});

  @override
  State<ManagerCalendarScreen> createState() => _ManagerCalendarScreenState();
}

class _ManagerCalendarScreenState extends State<ManagerCalendarScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<dynamic> _allEvents = [];
  List<dynamic> _allHolidays = [];
  List<dynamic> _allTasks = [];
  List<dynamic> _allLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getEvents(),
        ApiService.getOfficialLeaves(),
        ApiService.getTasks(),
        ApiService.getPersonalLeaves(),
      ]);

      if (mounted) {
        setState(() {
          if (results[0]['error'] == false)
            _allEvents = results[0]['data'] ?? [];
          if (results[1]['error'] == false)
            _allHolidays = results[1]['data'] ?? [];
          if (results[2]['error'] == false)
            _allTasks = results[2]['data'] ?? [];
          if (results[3]['error'] == false)
            _allLeaves = results[3]['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getEntriesForDate(
    DateTime date,
    List<dynamic> list,
    String dateKey,
  ) {
    return list.where((item) {
      final dStr = item[dateKey]?.toString() ?? '';
      final d = DateTime.tryParse(dStr);
      if (d == null) return false;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.gold,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCalendarCard(),
            const SizedBox(height: 24),
            _buildEventsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Calendar',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMMM yyyy').format(_currentDate),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMonthPicker(),
          const SizedBox(height: 20),
          _buildWeekDaysRow(),
          const SizedBox(height: 10),
          _buildDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(
            () => _currentDate = DateTime(
              _currentDate.year,
              _currentDate.month - 1,
            ),
          ),
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.navy,
            size: 20,
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentDate),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        IconButton(
          onPressed: () => setState(
            () => _currentDate = DateTime(
              _currentDate.year,
              _currentDate.month + 1,
            ),
          ),
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.navy,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDaysRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
        return Expanded(
          child: Center(
            child: Text(
              d,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final int daysInMonth = DateTime(
      _currentDate.year,
      _currentDate.month + 1,
      0,
    ).day;
    final int firstDayOffset =
        DateTime(_currentDate.year, _currentDate.month, 1).weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: daysInMonth + (firstDayOffset < 0 ? 0 : firstDayOffset),
      itemBuilder: (context, index) {
        if (index < firstDayOffset) return const SizedBox();

        final int dayNum =
            index - (firstDayOffset < 0 ? 0 : firstDayOffset) + 1;
        final DateTime date = DateTime(
          _currentDate.year,
          _currentDate.month,
          dayNum,
        );
        final bool isSelected =
            date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final bool isToday =
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        Color? bgColor;
        if (_getEntriesForDate(date, _allHolidays, 'leave_date').isNotEmpty)
          bgColor = AppColors.success.withValues(alpha: 0.15);
        else if (_getEntriesForDate(date, _allEvents, 'start_date').isNotEmpty)
          bgColor = AppColors.gold.withValues(alpha: 0.15);
        else if (_getEntriesForDate(date, _allTasks, 'due_date').isNotEmpty)
          bgColor = AppColors.info.withValues(alpha: 0.15);
        else if (_getEntriesForDate(date, _allLeaves, 'leave_from').isNotEmpty)
          bgColor = AppColors.warning.withValues(alpha: 0.15);

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.gold
                  : (isToday ? AppColors.navy.withValues(alpha: 0.1) : bgColor),
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(color: AppColors.gold, width: 2)
                  : (bgColor != null
                        ? Border.all(
                            color: bgColor.withValues(alpha: 0.5),
                            width: 1,
                          )
                        : null),
            ),
            child: Center(
              child: Text(
                '$dayNum',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected || isToday || bgColor != null
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: isSelected ? AppColors.navy : AppColors.navy,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsSection() {
    final holidays = _getEntriesForDate(
      _selectedDate,
      _allHolidays,
      'leave_date',
    );
    final events = _getEntriesForDate(_selectedDate, _allEvents, 'start_date');
    final tasks = _getEntriesForDate(_selectedDate, _allTasks, 'due_date');
    final leaves = _getEntriesForDate(_selectedDate, _allLeaves, 'leave_from');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday(_selectedDate)
              ? "Today's Schedule"
              : 'Events on ${DateFormat('MMM dd').format(_selectedDate)}',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        if (holidays.isEmpty &&
            events.isEmpty &&
            tasks.isEmpty &&
            leaves.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No events scheduled',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.grey400,
                ),
              ),
            ),
          )
        else ...[
          ...holidays.map(
            (h) => _buildEventCard(
              'Holiday',
              h['title'],
              'Full Day',
              AppColors.success,
              Icons.beach_access_rounded,
            ),
          ),
          ...events.map(
            (e) => _buildEventCard(
              'Event',
              e['title'],
              e['start_date'] != null
                  ? DateFormat(
                      'hh:mm a',
                    ).format(DateTime.parse(e['start_date']))
                  : 'All Day',
              AppColors.gold,
              Icons.meeting_room_rounded,
            ),
          ),
          ...tasks.map(
            (t) => _buildEventCard(
              'Task',
              t['title'],
              'Priority: ${t['priority']}',
              AppColors.info,
              Icons.assignment_rounded,
            ),
          ),
          ...leaves.map(
            (l) => _buildEventCard(
              'Leave',
              'Leave Request',
              'Personal Leave',
              AppColors.warning,
              Icons.person_off_rounded,
            ),
          ),
        ],
      ],
    );
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildEventCard(
    String type,
    String title,
    String time,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(icon, color: color.withValues(alpha: 0.5), size: 18),
        ],
      ),
    );
  }
}
