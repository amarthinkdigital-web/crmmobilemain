import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
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
          'Calendar',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your daily schedule and events',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey400,
          ),
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
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
            });
          },
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.navy),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentDate),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
            });
          },
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.navy),
        ),
      ],
    );
  }

  Widget _buildWeekDaysRow() {
    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
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
    final int daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final int firstDayOffset = DateTime(_currentDate.year, _currentDate.month, 1).weekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth + firstDayOffset,
      itemBuilder: (context, index) {
        if (index < firstDayOffset) {
          return const SizedBox();
        }
        
        final int dayNumber = index - firstDayOffset + 1;
        final DateTime date = DateTime(_currentDate.year, _currentDate.month, dayNumber);
        final bool isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
        final bool isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navy : (isToday ? AppColors.gold.withValues(alpha: 0.1) : Colors.transparent),
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: AppColors.gold, width: 2) : null,
            ),
            child: Center(
              child: Text(
                dayNumber.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: (isSelected || isToday) ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.white : (isToday ? AppColors.gold : AppColors.navy),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Schedule',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            Text(
              DateFormat('EEE, MMM dd').format(_selectedDate),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEventItem(
          time: '09:00 AM',
          title: 'Daily Scrum Meeting',
          description: 'Team updates and planning',
          typeColor: AppColors.info,
        ),
        _buildEventItem(
          time: '11:30 AM',
          title: 'Client Demo - Phase 2',
          description: 'CRM features presentation',
          typeColor: AppColors.success,
        ),
        _buildEventItem(
          time: '04:00 PM',
          title: 'Design Review',
          description: 'Reviewing new mobile components',
          typeColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildEventItem({
    required String time,
    required String title,
    required String description,
    required Color typeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey200),
        ],
      ),
    );
  }
}
