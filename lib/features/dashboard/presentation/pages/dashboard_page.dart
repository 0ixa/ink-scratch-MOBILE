// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import '../../../manga/presentation/pages/manga_browse_page.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kRed = Color(0xFFE63946);
const _kInk = Color(0xFF0A0A0F);
const _kBorder = Color(0x14FFFFFF);

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;

  void _switchToBrowse() => setState(() => _currentIndex = 1);
  void _switchToLibrary() => setState(() => _currentIndex = 2);

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onBrowseTap: _switchToBrowse, onLibraryTap: null),
      const MangaBrowsePage(),
      const LibraryScreen(),
      ProfileScreen(onLibraryTap: _switchToLibrary),
    ];

    return Scaffold(
      backgroundColor: _kInk,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kInk,
        border: const Border(top: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Browse',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.collections_bookmark_outlined,
                activeIcon: Icons.collections_bookmark_rounded,
                label: 'Library',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 20 : 0,
              height: 2,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(colors: [_kOrange, _kRed])
                    : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isActive
                  ? ShaderMask(
                      key: const ValueKey('active'),
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_kOrange, _kRed],
                      ).createShader(b),
                      child: Icon(activeIcon, color: Colors.white, size: 24),
                    )
                  : Icon(
                      key: const ValueKey('inactive'),
                      icon,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 24,
                    ),
            ),
            const SizedBox(height: 3),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? _kOrange
                    : Colors.white.withValues(alpha: 0.3),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
