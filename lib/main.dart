import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/preloader_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const CRMApp());
}

class CRMApp extends StatefulWidget {
  const CRMApp({super.key});

  @override
  State<CRMApp> createState() => _CRMAppState();
}

class _CRMAppState extends State<CRMApp> {
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  bool _showPreloader = true;

  void _onPreloaderComplete() {
    if (!mounted) return;
    setState(() => _showPreloader = false);
  }

  void _onLoginSuccess(String name, String email, String role) {
    setState(() {
      _isLoggedIn = true;
      _userName = name;
      _userEmail = email;
      _userRole = role;
    });
  }

  void _onLogout() async {
    await AuthService.clearAuth();
    setState(() {
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
      _userRole = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget home = _isLoggedIn
        ? MainNavigationScreen(
            key: const ValueKey('dashboard'),
            userName: _userName,
            userEmail: _userEmail,
            userRole: _userRole,
            onLogout: _onLogout,
          )
        : LoginScreen(
            key: const ValueKey('login'),
            onLoginSuccess: _onLoginSuccess,
          );

    return MaterialApp(
      title: 'ThinkDigital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        child: _showPreloader
            ? PreloaderScreen(
                key: const ValueKey('preloader'),
                onComplete: _onPreloaderComplete,
              )
            : home,
      ),
    );
  }
}
