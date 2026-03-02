// lib/core/config/app_config.dart

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io';

class AppConfig {
  // ✅ STEP 1: Set your computer's current IP address here
  // Find it by running 'ipconfig' on Windows (look for IPv4 Address)
  // Update this when your IP changes!
  static const String _computerIp =
      '192.168.1.70'; // ← UPDATE THIS WHEN YOUR IP CHANGES

  // ✅ STEP 2: The config automatically handles the rest!
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web (Chrome, Edge, etc.)
      return 'http://localhost:3000/api';
    } else {
      try {
        if (Platform.isAndroid) {
          // Android Emulator uses special IP
          // For physical Android devices, use your computer's IP
          return 'http://$_computerIp:3000/api';
        } else if (Platform.isIOS) {
          // iOS Simulator can use localhost
          return 'http://localhost:3000/api';
        } else {
          // Physical device fallback
          return 'http://$_computerIp:3000/api';
        }
      } catch (e) {
        // Fallback if Platform is not available
        return 'http://localhost:3000/api';
      }
    }
  }

  // ✅ Helper to get the full image base URL (without /api)
  static String get imageBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'http://$_computerIp:3000';
        } else if (Platform.isIOS) {
          return 'http://localhost:3000';
        } else {
          return 'http://$_computerIp:3000';
        }
      } catch (e) {
        return 'http://localhost:3000';
      }
    }
  }

  // App name
  static const String appName = 'InkScratch';

  // API timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // ✅ Print config info (useful for debugging)
  static void printConfig() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📱 App Config:');
    debugPrint('   Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    debugPrint('   API Base URL: $baseUrl');
    debugPrint('   Image Base URL: $imageBaseUrl');
    debugPrint('   Computer IP: $_computerIp');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
