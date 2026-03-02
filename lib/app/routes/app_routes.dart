// lib/app/routes/app_routes.dart

class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ── Public ────────────────────────────────────────────────────────────────
  static const String home = '/';
  static const String about = '/about';
  static const String mangaBrowse = '/manga';

  // ── Protected ─────────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String library = '/library';
  static const String profile = '/profile';

  // ── Manga detail & reader ─────────────────────────────────────────────────
  static const String mangaDetail = '/manga/:id';
  static const String chapterReader = '/manga/:id/read/:chapterId';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminUsers = '/admin/users';
}
