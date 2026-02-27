import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
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
      setState(() {
        _isLoggedIn = true;
        _userName = name ?? 'User';
        _userEmail = email ?? '';
      });
    }
  }

  void _onLoginSuccess(String name, String email) {
    setState(() {
      _isLoggedIn = true;
      _userName = name;
      _userEmail = email;
    });
  }

  void _onLogout() async {
    await AuthService.clearAuth();
    setState(() {
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThinkDigital CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoggedIn
          ? DashboardScreen(
              userName: _userName,
              userEmail: _userEmail,
              onLogout: _onLogout,
            )
          : LoginScreen(onLoginSuccess: _onLoginSuccess),
    );
  }
}
