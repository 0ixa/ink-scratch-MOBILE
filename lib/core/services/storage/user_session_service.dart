// lib/core/services/storage/user_session_service.dart

import 'package:hive_ce/hive.dart';

class UserSessionService {
  static const String _boxName = 'user_session';
  static const String _tokenKey = 'auth_token';

  /// Returns the already-open box, or opens it if not yet open.
  /// Never closes it — Hive boxes are meant to stay open for the app's lifetime.
  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  Future<void> saveToken(String token) async {
    final box = await _getBox();
    await box.put(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final box = await _getBox();
    return box.get(_tokenKey) as String?;
  }

  Future<void> clearToken() async {
    final box = await _getBox();
    await box.delete(_tokenKey);
  }
}
