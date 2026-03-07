// lib/core/config/app_config.dart

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io';

class AppConfig {
  // ── Your known IPs ───────────────────────────────────────────────
  static const String _ethernetIp = '10.250.127.169'; // Mobile (PC on Ethernet)
  static const String _wifiIp = '192.168.1.70'; // Tablet (PC on Wi-Fi)

  // ✅ Comment out whichever device you're NOT testing on
  static const String _computerIp = _ethernetIp; // ← Mobile
  // static const String _computerIp = _wifiIp;  // ← Tablet

  // ─────────────────────────────────────────────────────────────────

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'http://$_computerIp:3000/api';
        } else if (Platform.isIOS) {
          return 'http://localhost:3000/api';
        } else {
          return 'http://$_computerIp:3000/api';
        }
      } catch (e) {
        return 'http://localhost:3000/api';
      }
    }
  }

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

  static void printConfig() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📱 App Config:');
    debugPrint('   Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    debugPrint('   API Base URL: $baseUrl');
    debugPrint('   Image Base URL: $imageBaseUrl');
    debugPrint('   Active IP: $_computerIp');
    debugPrint('   Ethernet IP (Mobile): $_ethernetIp');
    debugPrint('   Wi-Fi IP   (Tablet):  $_wifiIp');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
