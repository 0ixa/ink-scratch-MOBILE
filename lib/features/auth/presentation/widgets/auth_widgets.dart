// lib/features/auth/presentation/widgets/auth_widgets.dart
//
// Shared design-system widgets for all auth screens.
// Mirrors the CSS component classes in globals.css:
//   .logo-gradient, .btn-primary, .input-field, .alert-error, .alert-success, .halftone

import 'package:flutter/material.dart';

import '../../../../app/themes/app_colors.dart';

// ── Logo Badge + Wordmark ─────────────────────────────────────────────────────
class InkScratchLogo extends StatelessWidget {
  final double badgeSize;
  final double fontSize;

  const InkScratchLogo({super.key, this.badgeSize = 40, this.fontSize = 30});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "IS" badge — matches the square gradient badge on web
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(badgeSize * 0.22),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowOrange,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'IS',
              style: TextStyle(
                color: Colors.white,
                fontSize: badgeSize * 0.38,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        SizedBox(width: badgeSize * 0.3),
        // "INK SCRATCH" gradient wordmark
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.brandGradient.createShader(bounds),
          child: Text(
            'INK SCRATCH',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: fontSize * 0.08,
              color: Colors.white, // masked by shader
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gradient Primary Button (matches .btn-primary) ────────────────────────────
class GradientButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GradientButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isLoading || widget.onPressed == null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!disabled) widget.onPressed!();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: disabled ? 0.45 : 1.0,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.shadowOrange,
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Alert boxes (.alert-error / .alert-success) ───────────────────────────────
class AlertBox extends StatelessWidget {
  final String message;
  final bool isError;

  const AlertBox.error({super.key, required this.message}) : isError = true;
  const AlertBox.success({super.key, required this.message}) : isError = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? AppColors.alertErrorBg : AppColors.alertSuccessBg,
        border: Border.all(
          color: isError
              ? AppColors.alertErrorBorder
              : AppColors.alertSuccessBorder,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? AppColors.alertErrorText
              : AppColors.alertSuccessText,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── OR divider (matches the "or" separator on web) ───────────────────────────
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, height: 1)),
      ],
    );
  }
}

// ── Halftone dot background (.halftone) ──────────────────────────────────────
class HalftoneBackground extends StatelessWidget {
  const HalftoneBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _HalftotePainter(), size: Size.infinite),
    );
  }
}

class _HalftotePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    const radius = 1.0;
    final paint = Paint()
      ..color =
          const Color(0x14FF6B35) // rgba(255,107,53,0.08)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Floating ink particle (decorative, matches auth layout right panel) ───────
class InkParticle extends StatefulWidget {
  final double startX; // 0.0 – 1.0 (fraction of screen width)
  final Duration duration;
  final double size;
  final Duration delay;

  const InkParticle({
    super.key,
    required this.startX,
    required this.duration,
    required this.size,
    required this.delay,
  });

  @override
  State<InkParticle> createState() => _InkParticleState();
}

class _InkParticleState extends State<InkParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.8), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.4), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 15),
    ]).animate(_ctrl);
    _translateY = Tween(begin: 0.0, end: -600.0).animate(_ctrl);

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        return Positioned(
          left: widget.startX * MediaQuery.of(context).size.width,
          bottom: _translateY.value + 20,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0x80FF6B35),
                    const Color(0x33E63946),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Particles layer (12 particles matching auth layout) ──────────────────────
class InkParticlesLayer extends StatelessWidget {
  const InkParticlesLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(12, (i) {
        final x = ((i * 41 + 7) % 90) / 100.0;
        return InkParticle(
          startX: x,
          size: 4 + (i % 4) * 3.0,
          delay: Duration(milliseconds: (i * 900)),
          duration: Duration(seconds: 7 + (i % 5)),
        );
      }),
    );
  }
}
