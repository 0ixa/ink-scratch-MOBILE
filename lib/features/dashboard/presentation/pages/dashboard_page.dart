// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../../../manga/presentation/pages/manga_browse_page.dart'; // ✅ added

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // ✅ FIX: Browse tab now uses real MangaBrowsePage instead of ComingSoonScreen
  late final List<Widget> _pages = [
    const HomeScreen(),
    const ComingSoonScreen(
      icon: Icons.collections_bookmark_outlined,
      title: "Library",
      description: "Organize and manage your manga collection",
      features: [
        "Sort by genres and categories",
        "Create custom reading lists",
        "Track your progress",
        "Filter by reading status",
      ],
    ),
    const MangaBrowsePage(), // ✅ Real browse page
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          animationDuration: const Duration(milliseconds: 400),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 80,
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primaryContainer,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: _selectedIndex == 0
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: colorScheme.primary,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.collections_bookmark_outlined,
                color: _selectedIndex == 1
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.collections_bookmark_rounded,
                color: colorScheme.primary,
              ),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.explore_outlined,
                color: _selectedIndex == 2
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.explore_rounded,
                color: colorScheme.primary,
              ),
              label: 'Browse',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline_rounded,
                color: _selectedIndex == 3
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: colorScheme.primary,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coming Soon Screen ────────────────────────────────────────────────────────
class ComingSoonScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  const ComingSoonScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 80, color: colorScheme.primary),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "COMING SOON",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Upcoming Features",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...features.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "We'll notify you when $title is ready!",
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text(
                      "Notify Me When Ready",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
