// lib/features/auth/presentation/pages/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/themes/app_colors.dart';
import '../view_model/auth_viewmodel_provider.dart';
import '../widgets/auth_widgets.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _kOrange = AppColors.orange;
const _kRed = AppColors.red;

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _submitted = false;
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final success = await ref
        .read(authViewModelProvider.notifier)
        .forgotPassword(_emailController.text.trim());

    if (!mounted) return;
    if (success) {
      setState(() => _submitted = true);
      _fadeCtrl
        ..reset()
        ..forward();
    } else {
      setState(
        () => _errorMessage =
            ref.read(authViewModelProvider).error ??
            'Something went wrong. Please try again.',
      );
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

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
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
                            child: _submitted
                                ? _SuccessView(
                                    email: _emailController.text.trim(),
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    textMuted: textMuted,
                                    onTryAgain: () {
                                      setState(() {
                                        _submitted = false;
                                        _emailController.clear();
                                      });
                                      _fadeCtrl
                                        ..reset()
                                        ..forward();
                                    },
                                    onBackToLogin: () => Navigator.pop(context),
                                  )
                                : _FormView(
                                    formKey: _formKey,
                                    emailController: _emailController,
                                    errorMessage: _errorMessage,
                                    isLoading: isLoading,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    textMuted: textMuted,
                                    onSubmit: _handleSubmit,
                                    onBackToLogin: () => Navigator.pop(context),
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

// ── Form View ─────────────────────────────────────────────────────────────────
class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final String? errorMessage;
  final bool isLoading;
  final Color textPrimary, textSecondary, textMuted;
  final VoidCallback onSubmit, onBackToLogin;

  const _FormView({
    required this.formKey,
    required this.emailController,
    required this.errorMessage,
    required this.isLoading,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onSubmit,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: InkScratchLogo(badgeSize: 40, fontSize: 28)),
        const SizedBox(height: 32),

        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _kOrange.withValues(alpha: 0.1),
            border: Border.all(color: _kOrange.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.lock_reset_rounded, color: _kOrange, size: 26),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'RESET PASSWORD',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Enter your email and we'll send a reset link if your account exists.",
          style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
        ),
        const SizedBox(height: 28),

        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null) ...[
                AlertBox.error(message: errorMessage!),
                const SizedBox(height: 16),
              ],

              Text(
                'Email address',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: TextStyle(color: textPrimary, fontSize: 15),
                decoration: const InputDecoration(hintText: 'you@example.com'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                  ).hasMatch(v.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              GradientButton(
                label: isLoading ? 'Sending…' : 'Send Reset Link',
                isLoading: isLoading,
                onPressed: isLoading ? null : onSubmit,
              ),

              const SizedBox(height: 20),
              const OrDivider(),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: onBackToLogin,
                  child: RichText(
                    text: TextSpan(
                      text: 'Remembered it? ',
                      style: TextStyle(color: textSecondary, fontSize: 15),
                      children: const [
                        TextSpan(
                          text: 'Back to Log In',
                          style: TextStyle(
                            color: _kOrange,
                            fontWeight: FontWeight.w700,
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
      ],
    );
  }
}

// ── Success View ──────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String email;
  final Color textPrimary, textSecondary, textMuted;
  final VoidCallback onTryAgain, onBackToLogin;

  const _SuccessView({
    required this.email,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onTryAgain,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
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
          'CHECK YOUR EMAIL',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: textSecondary, fontSize: 14, height: 1.6),
            children: [
              const TextSpan(text: 'If '),
              TextSpan(
                text: email,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: ' is registered, we\'ve sent a\npassword reset link.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The link expires in 1 hour.\nCheck your spam folder if you don\'t see it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
            height: 1.6,
            fontFamily: 'monospace',
          ),
        ),

        const SizedBox(height: 32),

        GradientButton(
          label: 'Back to Log In',
          isLoading: false,
          onPressed: onBackToLogin,
        ),

        const SizedBox(height: 16),

        Center(
          child: RichText(
            text: TextSpan(
              text: "Didn't receive it? ",
              style: TextStyle(color: textMuted, fontSize: 13),
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    onTap: onTryAgain,
                    child: const Text(
                      'Try again',
                      style: TextStyle(
                        color: _kOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: _kOrange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
