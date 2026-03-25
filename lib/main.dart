import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await AuthService.getToken();
    if (token != null) {
      final name = await AuthService.getUserName();
      final email = await AuthService.getUserEmail();
      final role = await AuthService.getUserRole();
      setState(() {
        _isLoggedIn = true;
        _userName = name ?? 'User';
        _userEmail = email ?? '';
        _userRole = role ?? 'Employee';
      });
    }
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
    return MaterialApp(
      title: 'ThinkDigital',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoggedIn
          ? MainNavigationScreen(
              userName: _userName,
              userEmail: _userEmail,
              userRole: _userRole,
              onLogout: _onLogout,
            )
          : LoginScreen(onLoginSuccess: _onLoginSuccess),
    );
  }
}
