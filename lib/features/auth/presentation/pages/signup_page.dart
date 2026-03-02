// lib/features/auth/presentation/pages/signup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/themes/app_colors.dart';
import '../state/auth_state.dart';
import '../view_model/auth_viewmodel_provider.dart';
import '../widgets/auth_widgets.dart';
import 'login_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage>
    with SingleTickerProviderStateMixin {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'male';
  String? _errorMessage;
  String? _successMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _listenToAuthState(AuthState? previous, AuthState next) {
    if (next.isAuthenticated && next.currentUser != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (ctx, a, route) => const DashboardPage(),
          transitionsBuilder: (ctx, a, route, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }
    if (next.error != null && !next.isAuthenticated) {
      setState(() => _errorMessage = next.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = ref.read(authViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);
    ref.listen(authViewModelProvider, _listenToAuthState);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final textMuted = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (isDark)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A0F),
                    Color(0xFF0F0F1A),
                    Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),

          const HalftoneBackground(),

          // Glow orbs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orange.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.red.withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo
                          const InkScratchLogo(badgeSize: 36, fontSize: 26),

                          const SizedBox(height: 24),

                          // Title
                          Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Join and start reading instantly',
                            style: TextStyle(
                              fontSize: 15,
                              color: textSecondary,
                            ),
                          ),

                          const SizedBox(height: 28),

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Alerts
                                if (_errorMessage != null) ...[
                                  AlertBox.error(message: _errorMessage!),
                                  const SizedBox(height: 14),
                                ],
                                if (_successMessage != null) ...[
                                  AlertBox.success(message: _successMessage!),
                                  const SizedBox(height: 14),
                                ],

                                // Full Name
                                _label('Full Name', textMuted),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _fullNameController,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Your full name',
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Please enter your full name'
                                      : v.length < 2
                                      ? 'Must be at least 2 characters'
                                      : null,
                                ),

                                const SizedBox(height: 14),

                                // Phone + Gender row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Phone Number', textMuted),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: _phoneController,
                                            keyboardType: TextInputType.phone,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 15,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: '+977...',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Gender', textMuted),
                                          const SizedBox(height: 6),
                                          _GenderDropdown(
                                            value: _selectedGender,
                                            isDark: isDark,
                                            onChanged: (v) => setState(
                                              () =>
                                                  _selectedGender = v ?? 'male',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Username
                                _label('Username', textMuted),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _usernameController,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Choose a username',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter a username';
                                    }
                                    if (v.length < 3) {
                                      return 'Must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),

                                // Email
                                _label('Email address', textMuted),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'you@example.com',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                                    ).hasMatch(v)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),

                                // Password
                                _label('Password', textMuted),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Min. 6 characters',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: textMuted,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),

                                // Confirm Password
                                _label('Confirm Password', textMuted),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Repeat your password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: textMuted,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 26),

                                // Submit
                                GradientButton(
                                  label: 'Create Account',
                                  isLoading: authState.isLoading,
                                  onPressed: authState.isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _errorMessage = null;
                                            _successMessage = null;
                                          });
                                          if (_formKey.currentState!
                                              .validate()) {
                                            authVM.register(
                                              fullName: _fullNameController.text
                                                  .trim(),
                                              username: _usernameController.text
                                                  .trim(),
                                              email: _emailController.text
                                                  .trim(),
                                              phoneNumber:
                                                  _phoneController.text.isEmpty
                                                  ? null
                                                  : _phoneController.text
                                                        .trim(),
                                              gender: _selectedGender,
                                              password:
                                                  _passwordController.text,
                                              confirmPassword:
                                                  _confirmPasswordController
                                                      .text,
                                            );
                                          }
                                        },
                                ),

                                const SizedBox(height: 20),

                                // Login link
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 15,
                                      ),
                                      children: [
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () =>
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const LoginPage(),
                                                  ),
                                                ),
                                            child: const Text(
                                              'Log In',
                                              style: TextStyle(
                                                color: AppColors.orange,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                              ],
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
        ],
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Gender dropdown (styled to match the input-field theme) ──────────────────
class _GenderDropdown extends StatelessWidget {
  final String value;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _GenderDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.bgInputDark : AppColors.bgInputLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppColors.orange,
          ),
          dropdownColor: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
          style: TextStyle(color: text, fontSize: 14),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
