// lib/core/api/api_endpoints.dart

import '../config/app_config.dart';

class ApiEndpoints {
  // ── Base URL from AppConfig ───────────────────────────────────────────────
  // AppConfig.baseUrl already includes '/api' (e.g. http://192.168.1.70:3000/api)
  // So all paths below are just the suffix AFTER /api
  static String get baseUrl => AppConfig.baseUrl;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/update-profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ── Manga ─────────────────────────────────────────────────────────────────
  static const String manga = '/manga';
  static const String mangaSearch = '/manga/search';

  static String mangaById(String id) => '/manga/$id';
  static String mangaChapters(String id) => '/manga/$id/chapters';
  static String chapterPages(String id) => '/manga/chapters/$id';

  // ── Library ───────────────────────────────────────────────────────────────
  static const String library = '/library';
  static String libraryItem(String mangaId) => '/library/$mangaId';

  // ── History ───────────────────────────────────────────────────────────────
  static const String history = '/history';
  static String historyItem(String mangaId) => '/history/$mangaId';
}
