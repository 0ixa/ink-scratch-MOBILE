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
    // onLibraryTap is a no-op here because this screen is pushed via
    // Navigator outside the DashboardPage shell. The Library button
    // simply won't navigate when accessed from this standalone route.
    return ProfileScreen(onLibraryTap: () {});
  }
}
