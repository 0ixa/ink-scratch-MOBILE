// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class InkScratchApp extends ConsumerWidget {
  const InkScratchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ink Scratch',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.dark),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const SplashPage(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const kOrange = Color(0xFFFF6B35);
    const kRed = Color(0xFFE63946);
    const kInk = Color(0xFF0A0A0F);
    const kInk2 = Color(0xFF16161F);

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: kInk,
      colorScheme: ColorScheme.dark(
        primary: kOrange,
        secondary: kRed,
        surface: kInk,
        surfaceContainerHighest: kInk2,
        error: kRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      fontFamily: 'NotoSans',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white60),
        bodySmall: TextStyle(color: Colors.white38),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kOrange, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIconColor: kOrange.withValues(alpha: 0.6),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A0F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
