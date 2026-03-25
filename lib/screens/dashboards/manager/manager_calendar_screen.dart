import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ManagerCalendarScreen extends StatefulWidget {
  const ManagerCalendarScreen({super.key});

  @override
  State<ManagerCalendarScreen> createState() => _ManagerCalendarScreenState();
}

class _ManagerCalendarScreenState extends State<ManagerCalendarScreen> {
  int _selectedDay = 9;
  final int _month = 3;
  final int _year = 2026;

  final List<Map<String, dynamic>> _events = [
    {'day': 9, 'title': 'Team Standup', 'time': '10:00 AM', 'type': 'Meeting', 'color': Colors.blue},
    {'day': 9, 'title': 'Client Review — Tech Solutions', 'time': '2:00 PM', 'type': 'Client', 'color': Colors.orange},
    {'day': 12, 'title': 'Sprint Planning', 'time': '11:00 AM', 'type': 'Meeting', 'color': Colors.blue},
    {'day': 15, 'title': 'Performance Review', 'time': '3:00 PM', 'type': 'HR', 'color': Colors.green},
    {'day': 20, 'title': 'Board Presentation', 'time': '09:30 AM', 'type': 'Important', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_year, _month);
    final firstWeekday = DateTime(_year, _month, 1).weekday % 7;
    final todayEvents = _events.where((e) => e['day'] == _selectedDay).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Calendar',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.5)),
          Text('March 2026', style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400)),
          const SizedBox(height: 24),
          _buildCalendarGrid(daysInMonth, firstWeekday),
          const SizedBox(height: 24),
          Text(
            _selectedDay == 9 ? "Today's Events" : 'Events on $_selectedDay Mar',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 12),
          if (todayEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No events scheduled', style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400)),
              ),
            )
          else
            ...todayEvents.map((e) => _buildEventCard(e)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(int days, int firstWeekday) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(d,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey400)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: days + firstWeekday,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox();
              final day = index - firstWeekday + 1;
              final hasEvent = _events.any((e) => e['day'] == day);
              final isSelected = day == _selectedDay;
              final isToday = day == 9;

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navy : (isToday ? AppColors.gold.withOpacity(0.15) : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$day',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? AppColors.white : (isToday ? AppColors.gold : AppColors.navy),
                          ),
                        ),
                      ),
                      if (hasEvent && !isSelected)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> e) {
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
            width: 4,
            height: 50,
            decoration: BoxDecoration(color: e['color'], borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['title'],
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(e['time'], style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (e['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(e['type'],
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: e['color'])),
          ),
        ],
      ),
    );
  }
}
