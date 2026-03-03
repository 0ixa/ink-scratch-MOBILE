// lib/features/dashboard/presentation/pages/profile_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ink_scratch/features/auth/presentation/view_model/auth_viewmodel_provider.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kRed = Color(0xFFE63946);
const _kInk = Color(0xFF0A0A0F);
const _kCard = Color(0xFF111118);
const _kBorder = Color(0x12FFFFFF);

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback onLibraryTap;
  const ProfileScreen({super.key, required this.onLibraryTap});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tab = 0; // 0 = Account Info, 1 = Edit Profile

  final _bioCtrl = TextEditingController();
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _saving = false;
  String? _saveMessage;
  bool _saveSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).currentUser;
    _bioCtrl.text = user?.bio ?? '';
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _saveMessage = null;
    });
    await ref
        .read(authViewModelProvider.notifier)
        .updateProfile(
          bio: _bioCtrl.text.isNotEmpty ? _bioCtrl.text : null,
          profilePicturePath: _pickedImage?.path,
        );
    if (!mounted) return;
    final error = ref.read(authViewModelProvider).error;
    setState(() {
      _saving = false;
      _saveSuccess = error == null;
      _saveMessage = error == null
          ? 'Profile updated successfully!'
          : 'Error: $error';
    });
    if (error == null) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _tab = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).currentUser;
    final initials = ((user?.fullName ?? user?.username ?? '?')[0])
        .toUpperCase();
    final profileUrl = user?.profilePicture;

    return Scaffold(
      backgroundColor: _kInk,
      body: Stack(
        children: [
          Positioned(top: -60, left: -40, child: _glow(_kOrange, 400, 0.12)),
          Positioned(bottom: 40, right: -60, child: _glow(_kRed, 300, 0.08)),
          Opacity(
            opacity: 0.02,
            child: SizedBox.expand(child: CustomPaint(painter: _DotPainter())),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ─────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: _kInk.withValues(alpha: 0.92),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                toolbarHeight: 56,
                leading: const SizedBox.shrink(),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    color: _kInk.withValues(alpha: 0.92),
                    border: const Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kOrange, _kRed],
                              ),
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: [
                                BoxShadow(
                                  color: _kOrange.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'IS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [_kOrange, _kRed],
                            ).createShader(b),
                            child: const Text(
                              'PROFILE',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                'USER PROFILE',
                                style: TextStyle(
                                  color: _kOrange.withValues(alpha: 0.5),
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                ' › DASHBOARD',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Profile Card ─────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.025),
                      border: Border.all(color: _kBorder),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Banner(),

                        // Avatar + Role
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: Transform.translate(
                            offset: const Offset(0, -28),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _kInk, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kOrange.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _buildAvatar(
                                    profileUrl: _tab == 1 && _imageBytes != null
                                        ? null
                                        : profileUrl,
                                    imageBytes: _tab == 1 ? _imageBytes : null,
                                    initials: initials,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: user?.role == 'admin'
                                        ? const LinearGradient(
                                            colors: [_kOrange, _kRed],
                                          )
                                        : null,
                                    color: user?.role != 'admin'
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : null,
                                    border: user?.role != 'admin'
                                        ? Border.all(color: _kBorder)
                                        : null,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (user?.role ?? 'user').toUpperCase(),
                                    style: TextStyle(
                                      color: user?.role == 'admin'
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.4),
                                      fontFamily: 'monospace',
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Name + Username + Bio
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Transform.translate(
                            offset: const Offset(0, -20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? user?.username ?? 'Guest',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@${user?.username ?? 'guest'}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (user?.bio != null &&
                                    user!.bio!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    user.bio!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      fontSize: 13,
                                      height: 1.7,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Tabs
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: _kBorder)),
                          ),
                          child: Row(
                            children: [
                              _TabButton(
                                label: 'ACCOUNT INFO',
                                active: _tab == 0,
                                onTap: () => setState(() => _tab = 0),
                              ),
                              _TabButton(
                                label: 'EDIT PROFILE',
                                active: _tab == 1,
                                onTap: () => setState(() => _tab = 1),
                              ),
                            ],
                          ),
                        ),

                        // Tab content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: _tab == 0
                              ? _InfoTab(
                                  user: user,
                                  onEditTap: () => setState(() => _tab = 1),
                                )
                              : _EditTab(
                                  bioCtrl: _bioCtrl,
                                  imageBytes: _imageBytes,
                                  initials: initials,
                                  saving: _saving,
                                  message: _saveMessage,
                                  success: _saveSuccess,
                                  onPickImage: _pickImage,
                                  onSave: _saveProfile,
                                  onCancel: () => setState(() => _tab = 0),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── My Library Button ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: widget.onLibraryTap,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.025),
                        border: Border.all(
                          color: _kOrange.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kOrange, _kRed],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _kOrange.withValues(alpha: 0.3),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('📚', style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Library',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'View your saved manga titles',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _kOrange.withValues(alpha: 0.08),
                              border: Border.all(
                                color: _kOrange.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.chevron_right_rounded,
                                color: _kOrange,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Logout ───────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0x14EF4444),
                        border: Border.all(color: const Color(0x33EF4444)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_outlined,
                            color: Color(0xFFF87171),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'LOGOUT',
                            style: TextStyle(
                              color: Color(0xFFF87171),
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required String? profileUrl,
    required Uint8List? imageBytes,
    required String initials,
  }) {
    if (imageBytes != null) return Image.memory(imageBytes, fit: BoxFit.cover);
    if (profileUrl != null && profileUrl.isNotEmpty) {
      return Image.network(
        profileUrl,
        fit: BoxFit.cover,
        // Fixed: removed leading underscores from local variables
        errorBuilder: (context, error, stackTrace) =>
            _initialsFallback(initials),
      );
    }
    return _initialsFallback(initials);
  }

  Widget _initialsFallback(String initials) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_kOrange, _kRed],
      ),
    ),
    child: Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    ),
  );

  void _showLogoutDialog(BuildContext context) {
    showDialog<bool>(context: context, builder: (_) => _LogoutDialog()).then((
      confirmed,
    ) {
      if (confirmed == true && mounted) {
        ref.read(authViewModelProvider.notifier).logout();
      }
    });
  }

  Widget _glow(Color c, double sz, double op) => Container(
    width: sz,
    height: sz,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          c.withValues(alpha: op),
          Colors.transparent,
        ],
      ),
    ),
  );
}

// ── Banner ────────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a0a0a), Color(0xFF0d0014), Color(0xFF0a0a1a)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(painter: _DiagLinePainter()),
            ),
          ),
          Positioned(
            top: -40,
            right: 60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kOrange.withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: 30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kRed.withValues(alpha: 0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 20,
            child: Row(
              children: [
                Container(width: 14, height: 2, color: _kOrange),
                const SizedBox(width: 6),
                Text(
                  'USER PROFILE',
                  style: TextStyle(
                    color: _kOrange.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab button ────────────────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _kOrange : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? _kOrange : Colors.white.withValues(alpha: 0.3),
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Account Info Tab ──────────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final dynamic user;
  final VoidCallback onEditTap;
  const _InfoTab({required this.user, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final fields = [
      _Field(emoji: '👤', label: 'FULL NAME', value: user?.fullName),
      _Field(
        emoji: '🏷️',
        label: 'USERNAME',
        value: user?.username != null ? '@${user!.username}' : null,
      ),
      _Field(emoji: '✉️', label: 'EMAIL', value: user?.email),
      _Field(emoji: '📱', label: 'PHONE', value: user?.phoneNumber?.toString()),
      _Field(emoji: '⚧️', label: 'GENDER', value: user?.gender),
    ];

    return Column(
      children: [
        ...fields.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FieldRow(field: f),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onEditTap,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kOrange, _kRed]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _kOrange.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'EDIT PROFILE',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Field {
  final String emoji, label;
  final String? value;
  const _Field({required this.emoji, required this.label, this.value});
}

class _FieldRow extends StatelessWidget {
  final _Field field;
  const _FieldRow({required this.field});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(field.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: TextStyle(
                  color: _kOrange.withValues(alpha: 0.5),
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                field.value?.isNotEmpty == true ? field.value! : '—',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Edit Profile Tab ──────────────────────────────────────────────────────────
class _EditTab extends StatelessWidget {
  final TextEditingController bioCtrl;
  final Uint8List? imageBytes;
  final String initials;
  final bool saving;
  final String? message;
  final bool success;
  final VoidCallback onPickImage, onSave, onCancel;

  const _EditTab({
    required this.bioCtrl,
    required this.imageBytes,
    required this.initials,
    required this.saving,
    required this.message,
    required this.success,
    required this.onPickImage,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: success
                  ? const Color(0x1422C55E)
                  : const Color(0x14EF4444),
              border: Border.all(
                color: success
                    ? const Color(0x3322C55E)
                    : const Color(0x33EF4444),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(success ? '✅' : '❌', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message!,
                    style: TextStyle(
                      color: success
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        _SubLabel(label: 'PROFILE PICTURE'),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _kOrange.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [_kOrange, _kRed]),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onPickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _kOrange.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'UPLOAD PHOTO',
                  style: TextStyle(
                    color: _kOrange,
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'JPG or PNG\nmax 5MB',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontFamily: 'monospace',
                fontSize: 9,
                height: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _SubLabel(label: 'BIO'),
        const SizedBox(height: 10),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: bioCtrl,
          // Fixed: removed leading underscore from 'w' parameter
          builder: (context, val, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: bioCtrl,
                  maxLength: 160,
                  maxLines: 4,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.7,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell readers about yourself…',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share your reading vibe',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontFamily: 'monospace',
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${val.text.length}/160',
                    style: TextStyle(
                      color: val.text.length > 140
                          ? const Color(0xFFF87171)
                          : Colors.white.withValues(alpha: 0.25),
                      fontFamily: 'monospace',
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: saving ? null : onSave,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: saving
                        ? null
                        : const LinearGradient(colors: [_kOrange, _kRed]),
                    color: saving ? Colors.white.withValues(alpha: 0.05) : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: saving
                        ? []
                        : [
                            BoxShadow(
                              color: _kOrange.withValues(alpha: 0.3),
                              blurRadius: 20,
                            ),
                          ],
                  ),
                  child: Center(
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: _kBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String label;
  const _SubLabel({required this.label});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 14, height: 2, color: _kOrange),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: _kOrange.withValues(alpha: 0.6),
          fontFamily: 'monospace',
          fontSize: 9,
          letterSpacing: 2,
        ),
      ),
    ],
  );
}

// ── Logout Dialog ─────────────────────────────────────────────────────────────
class _LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0x1AEF4444),
                border: Border.all(color: const Color(0x33EF4444)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.logout_outlined,
                  color: Color(0xFFF87171),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Log Out?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'LOGOUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: _kBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────
class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _kOrange;
    for (double x = 0; x < size.width; x += 28) {
      for (double y = 0; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _kOrange
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
