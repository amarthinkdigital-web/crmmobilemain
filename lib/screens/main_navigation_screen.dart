import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'navigation/tasks_screen.dart';
import 'navigation/clients_screen.dart';
import 'navigation/reports_screen.dart';
import 'navigation/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userRole;
  final VoidCallback onLogout;

  const MainNavigationScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    final String role = widget.userRole.toLowerCase();

    _screens = [
      DashboardScreen(
        userName: widget.userName,
        userEmail: widget.userEmail,
        userRole: widget.userRole,
        onLogout: widget.onLogout,
      ),
      if (role == 'admin') ...[
        const ClientsScreen(),
        const ReportsScreen(),
      ] else if (role == 'manager') ...[
        const ReportsScreen(),
        const TasksScreen(), 
      ] else ...[
        const TasksScreen(),
        const ClientsScreen(),
      ],
      ProfileScreen(
        userName: widget.userName,
        userEmail: widget.userEmail,
        onLogout: widget.onLogout,
      ),
    ];

    _navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Home',
      ),
      if (role == 'admin') ...[
        const BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clients'),
        const BottomNavigationBarItem(icon: Icon(Icons.assessment_rounded), label: 'Reports'),
      ] else if (role == 'manager') ...[
        const BottomNavigationBarItem(icon: Icon(Icons.assessment_rounded), label: 'Reports'),
        const BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
      ] else ...[
        const BottomNavigationBarItem(icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
        const BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clients'),
      ],
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.white,
            selectedItemColor: AppColors.gold,
            unselectedItemColor: AppColors.grey400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            items: _navItems,
          ),
        ),
      ),
    );
  }
}
