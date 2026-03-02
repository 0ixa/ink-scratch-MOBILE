// lib/features/dashboard/presentation/pages/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/view_model/auth_viewmodel_provider.dart';

// ── Brand colors ──────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kRed = Color(0xFFE63946);
const _kInk = Color(0xFF0A0A0F);

class HomeScreen extends ConsumerWidget {
  /// Called when "Browse Manga" / any CTA is tapped.
  /// Parent (DashboardPage) passes switchTab(1) here so the nav bar stays visible.
  final VoidCallback onBrowseTap;

  const HomeScreen({super.key, required this.onBrowseTap});

  static const _genres = [
    'Action',
    'Romance',
    'Fantasy',
    'Horror',
    'Sci-Fi',
    'Slice of Life',
    'Shōnen',
    'Seinen',
  ];

  static const _features = [
    (
      icon: '⚡',
      title: 'Instant Access',
      desc: 'Start reading in seconds — no wait, no hassle.',
    ),
    (
      icon: '☁️',
      title: 'Cloud Sync',
      desc: 'Your progress follows you on every device.',
    ),
    (
      icon: '🔖',
      title: 'Smart Bookmarks',
      desc: 'Save chapters and panels with a single tap.',
    ),
    (icon: '🌙', title: 'Dark Mode', desc: 'Easy on the eyes, day or night.'),
    (
      icon: '🔍',
      title: 'Powerful Search',
      desc: 'Find manga by genre, author, or rating.',
    ),
    (
      icon: '📱',
      title: 'Mobile First',
      desc: 'Optimised for every screen size.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).currentUser;
    final isAuth = user != null;
    final username = user?.username ?? 'Reader';

    return Scaffold(
      backgroundColor: _kInk,
      body: Stack(
        children: [
          _BackgroundGlow(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _InkAppBar(username: username),
              SliverToBoxAdapter(
                child: _HeroSection(
                  isAuth: isAuth,
                  onPrimary: onBrowseTap, // ← uses callback, NOT Navigator.push
                ),
              ),
              const SliverToBoxAdapter(child: _StatsBar()),
              const SliverToBoxAdapter(child: _FeaturesSection()),
              SliverToBoxAdapter(
                child: _GenresSection(onGenreTap: (genre) => onBrowseTap()),
              ),
              SliverToBoxAdapter(
                child: _FinalCTA(
                  isAuth: isAuth,
                  onTap: onBrowseTap, // ← uses callback, NOT Navigator.push
                ),
              ),
              const SliverToBoxAdapter(child: _Footer()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND GLOW
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: w * 0.25 - 200,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_kOrange.withValues(alpha: 0.25), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 400,
          right: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_kRed.withValues(alpha: 0.15), Colors.transparent],
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.03,
          child: SizedBox.expand(child: CustomPaint(painter: _DotPainter())),
        ),
        Opacity(
          opacity: 0.015,
          child: SizedBox.expand(
            child: CustomPaint(painter: _ScanlinePainter()),
          ),
        ),
      ],
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kOrange;
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _InkAppBar extends StatelessWidget {
  final String username;
  const _InkAppBar({required this.username});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kInk.withValues(alpha: 0.92),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 60,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: _kInk.withValues(alpha: 0.92),
          border: const Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'IS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_kOrange, _kRed],
                  ).createShader(bounds),
                  child: const Text(
                    'INK SCRATCH',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  username,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool isAuth;
  final VoidCallback onPrimary;
  const _HeroSection({required this.isAuth, required this.onPrimary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 28, height: 2, color: _kOrange),
              const SizedBox(width: 10),
              Text(
                'CHAPTER 01 — THE BEGINNING',
                style: TextStyle(
                  color: _kOrange.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, _kOrange, _kRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'INK\nSCRATCH',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 0.92,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Your portal into thousands of manga, comics & novels.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No downloads. Instant access, synced everywhere.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),

          // Genre badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HomeScreen._genres
                .map(
                  (g) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: g == 'Action'
                          ? _kOrange.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: g == 'Action'
                            ? _kOrange.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        color: g == 'Action'
                            ? _kOrange
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),

          // CTA
          GestureDetector(
            onTap: onPrimary,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isAuth ? 'Browse Manga' : 'Start Reading Free',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Social proof
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 24,
                child: Stack(
                  children: [
                    for (int i = 0; i < 5; i++)
                      Positioned(
                        left: i * 10.0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: [
                              _kOrange,
                              _kRed,
                              const Color(0xFFFF9A56),
                              const Color(0xFFC0392B),
                              const Color(0xFFFF7043),
                            ][i],
                            shape: BoxShape.circle,
                            border: Border.all(color: _kInk, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  children: const [
                    TextSpan(
                      text: '12,000+',
                      style: TextStyle(
                        color: _kOrange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(text: ' readers in the story'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS BAR
// ─────────────────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: Colors.white10)),
        color: Color(0x08FF6B35),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _StatItem(value: '50K+', label: 'Manga Titles'),
          _StatDivider(),
          _StatItem(value: '2.4M+', label: 'Chapters'),
          _StatDivider(),
          _StatItem(value: '12K+', label: 'Readers'),
          _StatDivider(),
          _StatItem(value: '99%', label: 'Uptime'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value.replaceAll(RegExp(r'[+%K M]'), ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: value.contains('+')
                    ? '+'
                    : value.contains('%')
                    ? '%'
                    : '',
                style: const TextStyle(
                  color: _kOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontFamily: 'monospace',
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 20, height: 2, color: _kOrange),
              const SizedBox(width: 8),
              Text(
                'CHAPTER 02 — FEATURES',
                style: TextStyle(
                  color: _kOrange.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'WHY READERS\nLOVE US',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: HomeScreen._features.length,
            itemBuilder: (context, i) {
              final f = HomeScreen._features[i];
              return _FeatureCard(icon: f.icon, title: f.title, desc: f.desc);
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENRES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _GenresSection extends StatelessWidget {
  final ValueChanged<String> onGenreTap;
  const _GenresSection({required this.onGenreTap});

  static const _allGenres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
    'Historical',
    'Psychological',
    'Mecha',
    'Isekai',
    'Shōnen',
    'Shōjo',
    'Seinen',
    'Josei',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 20, height: 2, color: _kOrange),
              const SizedBox(width: 8),
              Text(
                'CHAPTER 03 — LIBRARY',
                style: TextStyle(
                  color: _kOrange.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'EVERY GENRE.\nEVERY STORY.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'From heart-pounding battles to quiet slice-of-life moments.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allGenres
                .map(
                  (g) => GestureDetector(
                    onTap: () => onGenreTap(g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        g,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FINAL CTA
// ─────────────────────────────────────────────────────────────────────────────
class _FinalCTA extends StatelessWidget {
  final bool isAuth;
  final VoidCallback onTap;
  const _FinalCTA({required this.isAuth, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1,
          colors: [_kOrange.withValues(alpha: 0.1), Colors.transparent],
        ),
        border: Border.all(color: _kOrange.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: _kOrange.withValues(alpha: 0.3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'FINAL ARC',
                  style: TextStyle(
                    color: _kOrange.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: _kOrange.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'YOUR STORY\nSTARTS NOW',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_kOrange, _kRed],
            ).createShader(bounds),
            child: const Text(
              'Free forever. No credit card.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isAuth ? 'Browse Manga' : 'Begin the Journey',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kOrange, _kRed]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'IS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'INK SCRATCH',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '© 2025 INK SCRATCH · ALL RIGHTS RESERVED',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
