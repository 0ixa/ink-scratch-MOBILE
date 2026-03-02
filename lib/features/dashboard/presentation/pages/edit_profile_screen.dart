// lib/features/dashboard/presentation/pages/edit_profile_screen.dart
//
// Edit profile is now handled as a tab inside ProfileScreen.
// This file is kept for backward-compatibility with any existing navigation
// that pushes directly to EditProfileScreen.

import 'package:flutter/material.dart';
import 'profile_screen.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simply show the ProfileScreen — user can tap the "Edit Profile" tab.
    // If you want to deep-link straight to the edit tab, replace ProfileScreen
    // with ProfileScreen(initialTab: 1) and add that named parameter.
    return const ProfileScreen();
  }
}
