// lib/features/splash/presentation/pages/splash_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/themes/app_colors.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../../../auth/presentation/view_model/auth_viewmodel_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../../core/services/hive/hive_service.dart';

// Import your onboarding page if it exists:
// import '../../../onboarding/presentation/pages/onboarding_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut));
    _taglineOpacity = CurvedAnimation(
      parent: _shimmerCtrl,
      curve: Curves.easeIn,
    );

    // Stagger animations
    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _shimmerCtrl.forward();
    });

    // Start navigation check
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNavigation());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkNavigation() async {
    await ref.read(authViewModelProvider.notifier).checkCurrentUser();
    await Future.delayed(const Duration(milliseconds: 2400));

    if (!mounted) return;

    final authState = ref.read(authViewModelProvider);
    final hive = HiveService();
    final isOnboardingSeen = hive.isOnboardingSeen();

    Widget nextPage;
    if (!isOnboardingSeen) {
      // Uncomment when onboarding page exists:
      // nextPage = const OnboardingPage();
      nextPage = const LoginPage();
    } else if (!authState.isAuthenticated || authState.currentUser == null) {
      nextPage = const LoginPage();
    } else {
      nextPage = const DashboardPage();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, route) => nextPage,
        transitionsBuilder: (ctx, animation, route, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Deep gradient background ─────────────────────────────────────
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

          // ── Halftone dot grid ────────────────────────────────────────────
          const HalftoneBackground(),

          // ── Orange glow orb (top) ────────────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orange.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Red glow orb (bottom right) ──────────────────────────────────
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.red.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Floating ink particles ────────────────────────────────────────
          const InkParticlesLayer(),

          // ── Central content ───────────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo badge (scaled in with elastic spring)
                  ScaleTransition(scale: _scaleAnim, child: _LogoBadge()),

                  const SizedBox(height: 28),

                  // "INK SCRATCH" wordmark gradient
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.brandGradient.createShader(bounds),
                      child: const Text(
                        'INK SCRATCH',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tagline
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: const Text(
                      'Thousands of manga, one portal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0x59FFFFFF), // ~35% white
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Loading indicator — thin orange line
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: _LoadingDots(),
                  ),
                ],
              ),
            ),
          ),

          // ── Section tag bottom left (.section-tag) ────────────────────────
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineOpacity,
              child: const Center(
                child: Text(
                  'READING BEGINS HERE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0x59FF6B35), // orange 35%
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Big "IS" badge ────────────────────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOrange,
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'IS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ── Animated loading dots ─────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _controllers.add(ctrl);
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (ctx, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6 + _controllers[i].value * 6,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}
