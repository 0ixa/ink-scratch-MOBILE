// lib/features/auth/presentation/pages/reset_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/themes/app_colors.dart';
import '../view_model/auth_viewmodel_provider.dart';
import '../widgets/auth_widgets.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _kOrange = AppColors.orange;
const _kRed = AppColors.red;

/// Navigated to from the email deep link.
/// Expects a [token] string extracted from the reset URL.
class ResetPasswordPage extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

// Mirrors the web's Status type
enum _Status { loading, valid, invalid, success }

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  _Status _status = _Status.loading;

  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPass = false;
  bool _showConfirm = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    _verifyToken();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    await ref
        .read(authViewModelProvider.notifier)
        .verifyResetToken(widget.token);

    if (!mounted) return;
    final isValid = ref.read(authViewModelProvider).resetTokenValid;
    setState(() {
      _status = (isValid == true) ? _Status.valid : _Status.invalid;
    });
    _fadeCtrl
      ..reset()
      ..forward();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final success = await ref
        .read(authViewModelProvider.notifier)
        .resetPassword(
          token: widget.token,
          password: _passwordCtrl.text,
          confirmPassword: _confirmCtrl.text,
        );

    if (!mounted) return;

    if (success) {
      setState(() => _status = _Status.success);
      _fadeCtrl
        ..reset()
        ..forward();
      // Auto-redirect to login after 2.5 s
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } else {
      setState(() {
        _errorMessage =
            ref.read(authViewModelProvider).error ??
            'Failed to reset password. The link may have expired.';
      });
    }
  }

  // ── Password strength ─────────────────────────────────────────────────────
  String _strengthLabel(int len) {
    if (len < 6) return 'Too short';
    if (len < 8) return 'Weak';
    if (len < 12) return 'Good';
    return 'Strong';
  }

  Color _strengthColor(int level, int len) {
    if (len < level * 2) return Colors.white.withValues(alpha: 0.1);
    switch (level) {
      case 1:
        return _kRed;
      case 2:
        return _kOrange;
      case 3:
        return const Color(0xFFFACC15);
      default:
        return const Color(0xFF4ADE80);
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────────────
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

          Positioned(top: -100, right: -80, child: _glow(_kOrange, 300, 0.10)),
          Positioned(bottom: -60, left: -60, child: _glow(_kRed, 240, 0.08)),

          // ── Animated content ─────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // Back button (only show when not loading)
                    if (_status != _Status.loading)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _buildBody(
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              textMuted: textMuted,
                              isLoading: isLoading,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required bool isLoading,
  }) {
    switch (_status) {
      // ── Loading ────────────────────────────────────────────────────────
      case _Status.loading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3, color: _kOrange),
            ),
            const SizedBox(height: 20),
            Text(
              'Verifying your link…',
              style: TextStyle(
                color: textMuted,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        );

      // ── Invalid / expired ──────────────────────────────────────────────
      case _Status.invalid:
        return Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.1),
                border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.close_rounded, color: _kRed, size: 32),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'LINK EXPIRED',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This password reset link is invalid or has expired.\nReset links are only valid for 1 hour.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Request a New Link',
              isLoading: false,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );

      // ── Success ────────────────────────────────────────────────────────
      case _Status.success:
        return Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0x1A22C55E),
                border: Border.all(color: const Color(0x4D22C55E)),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Color(0xFF4ADE80),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PASSWORD RESET',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your password has been updated.\nRedirecting you to login…',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Go to Log In',
              isLoading: false,
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        );

      // ── Reset form ─────────────────────────────────────────────────────
      case _Status.valid:
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _passwordCtrl,
          builder: (context, passVal, child) {
            final passLen = passVal.text.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: InkScratchLogo(badgeSize: 40, fontSize: 28),
                ),
                const SizedBox(height: 32),

                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.1),
                    border: Border.all(color: _kOrange.withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.key_rounded, color: _kOrange, size: 26),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'NEW PASSWORD',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a strong password for your account.',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        AlertBox.error(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      // ── New password ──────────────────────────────────
                      Text(
                        'New password',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: !_showPass,
                        autofocus: true,
                        style: TextStyle(color: textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'New password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _showPass = !_showPass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      // ── Strength meter ────────────────────────────────
                      if (passLen > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ...List.generate(4, (i) {
                              final level = i + 1;
                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: _strengthColor(level, passLen),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              _strengthLabel(passLen),
                              style: TextStyle(
                                fontSize: 10,
                                color: textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ── Confirm password ──────────────────────────────
                      Text(
                        'Confirm new password',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: !_showConfirm,
                        style: TextStyle(color: textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Confirm new password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _showConfirm = !_showConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      GradientButton(
                        label: isLoading ? 'Resetting…' : 'Reset Password',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleSubmit,
                      ),

                      const SizedBox(height: 20),
                      const OrDivider(),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Log In',
                            style: TextStyle(
                              color: _kOrange,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
    }
  }

  Widget _glow(Color c, double sz, double op) => Container(
    width: sz,
    height: sz,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          c.withValues(alpha: op),
          Colors.transparent,
        ],
      ),
    ),
  );
}
