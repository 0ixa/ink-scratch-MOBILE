// lib/core/services/storage/user_session_service.dart

import 'package:hive_ce/hive.dart'; // ✅ was: package:hive/hive.dart

class UserSessionService {
  static const String _boxName = 'user_session';
  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_tokenKey, token);
    await box.close();
  }

  Future<String?> getToken() async {
    final box = await Hive.openBox(_boxName);
    final token = box.get(_tokenKey) as String?;
    await box.close();
    return token;
  }

  Future<void> clearToken() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_tokenKey);
    await box.close();
  }
}
