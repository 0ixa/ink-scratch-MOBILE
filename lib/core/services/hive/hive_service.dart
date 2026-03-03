// lib/core/services/hive/hive_service.dart

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../features/auth/data/models/auth_hive_model.dart';
import '../../../features/category/data/models/category_hive_model.dart';
import '../../../features/manga/data/models/library_manga_hive_model.dart';
import '../../../features/manga/data/models/reading_history_hive_model.dart';
import '../../constants/hive_table_constant.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Future<void> init() async {
    await Hive.initFlutter();

    // ── Auth ──────────────────────────────────────────────────────────────────
    if (!Hive.isAdapterRegistered(HiveTableConstant.authTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }

    // ── Category ──────────────────────────────────────────────────────────────
    if (!Hive.isAdapterRegistered(HiveTableConstant.categoryTypeId)) {
      Hive.registerAdapter(CategoryHiveModelAdapter());
    }

    // ── Library (typeId = 1) ──────────────────────────────────────────────────
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LibraryMangaHiveModelAdapter());
    }

    // ── Reading History (typeId = 5) ──────────────────────────────────────────
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ReadingHistoryHiveModelAdapter());
    }

    // ── Open boxes ────────────────────────────────────────────────────────────
    await Hive.openBox<AuthHiveModel>(HiveTableConstant.authBox);
    await Hive.openBox<CategoryHiveModel>(HiveTableConstant.categoryBox);
    await Hive.openBox(HiveTableConstant.sessionBox);
    await Hive.openBox<LibraryMangaHiveModel>('library');
    await Hive.openBox<ReadingHistoryHiveModel>('reading_history');
  }

  // ==================== Auth Methods ====================

  Future<void> saveUser(AuthHiveModel user) async {
    final box = Hive.box<AuthHiveModel>(HiveTableConstant.authBox);
    await box.put(user.id, user);
  }

  List<AuthHiveModel> getAllUsers() {
    final box = Hive.box<AuthHiveModel>(HiveTableConstant.authBox);
    return box.values.toList();
  }

  Future<void> saveCurrentUser(AuthHiveModel user) async {
    final box = Hive.box(HiveTableConstant.sessionBox);
    await box.put(HiveTableConstant.currentUserKey, user.id);
  }

  AuthHiveModel? getCurrentUser() {
    final box = Hive.box(HiveTableConstant.sessionBox);
    final userId = box.get(HiveTableConstant.currentUserKey);
    if (userId == null) return null;
    final authBox = Hive.box<AuthHiveModel>(HiveTableConstant.authBox);
    return authBox.get(userId);
  }

  Future<void> logout() async {
    final box = Hive.box(HiveTableConstant.sessionBox);
    await box.delete(HiveTableConstant.currentUserKey);
  }

  // ==================== Category Methods ====================

  Future<void> saveCategory(CategoryHiveModel category) async {
    final box = Hive.box<CategoryHiveModel>(HiveTableConstant.categoryBox);
    await box.put(category.id, category);
  }

  List<CategoryHiveModel> getAllCategories() {
    final box = Hive.box<CategoryHiveModel>(HiveTableConstant.categoryBox);
    return box.values.toList();
  }

  Future<void> updateCategory(CategoryHiveModel category) async {
    final box = Hive.box<CategoryHiveModel>(HiveTableConstant.categoryBox);
    await box.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    final box = Hive.box<CategoryHiveModel>(HiveTableConstant.categoryBox);
    await box.delete(id);
  }

  // ==================== Onboarding ====================

  Future<void> setOnboardingSeen() async {
    final box = Hive.box(HiveTableConstant.sessionBox);
    await box.put('onboarding_seen', true);
  }

  bool isOnboardingSeen() {
    final box = Hive.box(HiveTableConstant.sessionBox);
    return box.get('onboarding_seen', defaultValue: false);
  }
}
