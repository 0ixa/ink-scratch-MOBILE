import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/services/hive/hive_service.dart';
import 'app/themes/theme_provider.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive using the singleton instance
  await HiveService().init();

  // Print API config to debug console — confirms correct IP/URL on startup
  AppConfig.printConfig();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Ink Scratch',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: ThemeMode.system, // Respects user's system light/dark mode
      home: const SplashPage(),
    );
  }
}
