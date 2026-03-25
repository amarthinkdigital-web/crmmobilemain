import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final Function(String name, String email, String role) onRegisterSuccess;

  const RegisterScreen({super.key, required this.onRegisterSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.containsKey('token') || response['status'] == 'success') {
        final token = response['token'] ?? response['access_token'];
        final user = response['user'] ?? {};
        final name = user['name'] ?? _nameController.text.trim();
        final email = user['email'] ?? _emailController.text.trim();
        final role = user['role'] ?? 'Employee';

        final id = user['id']?.toString() ?? '0';

        await AuthService.saveAuth(token, name, email, role, id);
        widget.onRegisterSuccess(name, email, role);
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to connect to server. Check your connection.';
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
              AppColors.navy,
              Color(0xFF0F2140),
              Color(0xFF162D50),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      _buildLogo(),
                      const SizedBox(height: 30),

                      // Card
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Account',
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Join our CRM platform today',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.grey400,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Full Name
                                _buildLabel('Full Name'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameController,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'John Doe',
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 20,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Email
                                _buildLabel('Email address'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'you@company.com',
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                      color: AppColors.grey400,
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
                                const SizedBox(height: 16),

                                // Password
                                _buildLabel('Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: AppColors.grey400,
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
                                    if (v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password
                                _buildLabel('Confirm Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(
                                      Icons.lock_reset_rounded,
                                      size: 20,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
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
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Register button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
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
                                        : Text(
                                            'Create Account',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Back to login
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.grey600,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Already have an account? '),
                                          TextSpan(
                                            text: 'Sign In',
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
                      ),

                      const SizedBox(height: 20),
                      Text(
                        '© 2026 ThinkDigital. All rights reserved.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: AppColors.navy,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'ThinkDigital',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.grey600,
      ),
    );
  }
}
