import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';


class LoginScreen extends StatefulWidget {
  final Function(String name, String email, String role) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response['error'] == true) {
        setState(() {
          _errorMessage = response['message']?.toString() ??
              'Login failed. Please try again.';
        });
        return;
      }

      final token = response['token'] ?? response['access_token'];

      if (token != null && token.toString().isNotEmpty) {
        final user = response['user'] as Map<String, dynamic>? ?? {};

        final name = user['name']?.toString() ??
            _emailController.text.split('@').first;
        final email =
            user['email']?.toString() ?? _emailController.text.trim();

        String role = 'Employee';
        if (user['role'] != null) {
          role = user['role'].toString();
        } else if (user['user_type'] != null) {
          role = user['user_type'].toString();
        } else if (user['roles'] is List && (user['roles'] as List).isNotEmpty) {
          role = (user['roles'] as List).first.toString();
        }

        final id = user['id']?.toString() ?? '0';

        // Check account status before allowing login
        final profileRes = await ApiService.getUserProfile();
        final profileUser = profileRes['user'] as Map<String, dynamic>? ?? {};
        final accountStatus = (profileUser['status'] ?? user['status'] ?? '').toString().toLowerCase();

        if (accountStatus == 'terminate' || accountStatus == 'terminated' || accountStatus == 'resigned') {
          await AuthService.clearAuth();
          setState(() {
            _errorMessage = accountStatus == 'resigned'
                ? 'Your account has been marked as Resigned. Please contact HR.'
                : 'Your account has been Terminated. Please contact administration.';
          });
          return;
        }

        await AuthService.saveAuth(token.toString(), name, email, role, id);
        widget.onLoginSuccess(name, email, role);
      } else {
        setState(() {
          _errorMessage = response['message']?.toString() ??
              response['error']?.toString() ??
              'Invalid credentials. Please check your email and password.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050C1C),
              Color(0xFF0A1628),
              Color(0xFF0F2140),
              Color(0xFF162D50),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background elements
              Positioned(
                top: -120,
                right: -120,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.08),
                        AppColors.gold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.info.withValues(alpha: 0.06),
                        AppColors.info.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                left: 40,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.25),
                  ),
                ),
              ),
              Positioned(
                top: 160,
                left: 80,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                right: 60,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brand section
                          _buildBrandHeader(),
                          const SizedBox(height: 40),
                          // Login form card
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 420),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 60,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                children: [
                                  // Top accent bar
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.gold,
                                          AppColors.goldLight,
                                          AppColors.gold,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome back',
                                            style: GoogleFonts.inter(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.navy,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Sign in to your account to continue',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.grey400,
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // Email
                                          _buildLabel('Email Address'),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: AppColors.black,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'you@company.com',
                                              hintStyle: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppColors.grey200,
                                              ),
                                              prefixIcon: Container(
                                                width: 48,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.email_outlined,
                                                  size: 20,
                                                  color: AppColors.grey400,
                                                ),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.trim().isEmpty) {
                                                return 'Email is required';
                                              }
                                              if (!v.contains('@')) {
                                                return 'Enter a valid email';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 18),

                                          // Password
                                          _buildLabel('Password'),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: AppColors.black,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Enter your password',
                                              hintStyle: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppColors.grey200,
                                              ),
                                              prefixIcon: Container(
                                                width: 48,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.lock_outline_rounded,
                                                  size: 20,
                                                  color: AppColors.grey400,
                                                ),
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility_off_outlined
                                                      : Icons.visibility_outlined,
                                                  size: 20,
                                                  color: AppColors.grey400,
                                                ),
                                                onPressed: () => setState(
                                                    () => _obscurePassword = !_obscurePassword),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.isEmpty) {
                                                return 'Password is required';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 14),

                                          // Remember me + Forgot Password
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: Checkbox(
                                                      value: _rememberMe,
                                                      onChanged: (val) => setState(
                                                          () => _rememberMe = val ?? false),
                                                      activeColor: AppColors.navy,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      side: BorderSide(
                                                        color: AppColors.grey200,
                                                        width: 1.5,
                                                      ),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Remember me',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.grey600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              TextButton(
                                                onPressed: () {},
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  'Forgot password?',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.info,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),

                                          // Error
                                          if (_errorMessage != null) ...[
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.errorBg,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.error.withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.error_outline,
                                                      size: 18, color: AppColors.error),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _errorMessage!,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        color: AppColors.error,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],

                                          // Sign In button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 52,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(14),
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    AppColors.gold,
                                                    AppColors.goldLight,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.gold.withValues(alpha: 0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                onPressed: _isLoading ? null : _handleLogin,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  shadowColor: Colors.transparent,
                                                  foregroundColor: AppColors.navy,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: AppColors.navy,
                                                        ),
                                                      )
                                                    : Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            'Sign In',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w700,
                                                              letterSpacing: 0.3,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          const Icon(
                                                            Icons.arrow_forward_rounded,
                                                            size: 18,
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          // Divider with "OR"
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: AppColors.grey100,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                child: Text(
                                                  'OR',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.grey400,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: AppColors.grey100,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 20),

                                          // Register link
                                          Center(
                                            child: TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => RegisterScreen(
                                                      onRegisterSuccess: widget.onLoginSuccess,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  side: BorderSide(color: AppColors.grey200),
                                                ),
                                              ),
                                              child: RichText(
                                                text: TextSpan(
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: AppColors.grey600,
                                                  ),
                                                  children: [
                                                    const TextSpan(text: "Don't have an account? "),
                                                    TextSpan(
                                                      text: 'Create Account',
                                                      style: GoogleFonts.inter(
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.navy,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Server info
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Connected to: 192.168.1.12:8000',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.5),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          Text(
                            '© 2026 ThinkDigital. All rights reserved.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.3),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        children: [
          // Logo & company name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/theme/logo.png',
                width: 48,
                height: 52,
                color: AppColors.gold,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ThinkDigital',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'CRM Platform',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold.withValues(alpha: 0.7),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
        letterSpacing: 0.3,
      ),
    );
  }
}
