import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _nameCtrl = TextEditingController();
  Uint8List? _avatarBytes;
  String? _avatarSignedUrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _startEditing(Profile profile) {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = true;
      _nameCtrl.text = profile.fullName ?? '';
      _avatarBytes = null;
    });
  }

  void _cancelEditing() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = false;
      _avatarBytes = null;
    });
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 512, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _avatarBytes = bytes);
  }

  Future<void> _save() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    setState(() => _isSaving = true);
    try {
      String? newAvatarUrl;
      if (_avatarBytes != null) {
        final storagePath = '${profile.businessId}/avatars/${profile.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await SupabaseConfig.client.storage.from('documents').uploadBinary(
          storagePath,
          _avatarBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        newAvatarUrl = storagePath;
      }

      final (success, error) = await ref.read(authNotifierProvider.notifier).updateProfile(
        fullName: _nameCtrl.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      if (success) {
        ref.invalidate(profileProvider);
        if (mounted) {
          setState(() {
            _isEditing = false;
            _avatarBytes = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('Profile updated!', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadAvatarUrl(String storagePath) async {
    try {
      final url = await SupabaseConfig.client.storage.from('documents').createSignedUrl(storagePath, 3600);
      if (mounted) setState(() => _avatarSignedUrl = url);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final business = ref.watch(businessProvider).value;
    final name = profile?.fullName ?? 'User';
    final role = profile?.role.displayName ?? '';
    final email = profile?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isManager = profile?.role == UserRole.owner || profile?.role == UserRole.manager;

    // Load avatar signed URL if needed
    if (profile?.avatarUrl != null && _avatarSignedUrl == null && !_isEditing) {
      _loadAvatarUrl(profile!.avatarUrl!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          // ── Profile card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEDE9E3)),
            ),
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    _buildAvatar(profile, initial, 72),
                    if (!_isEditing)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => profile != null ? _startEditing(profile) : null,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),

                // Avatar upload buttons (edit mode)
                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SmallButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        onTap: () => _pickAvatar(ImageSource.camera),
                      ),
                      const SizedBox(width: 12),
                      _SmallButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: () => _pickAvatar(ImageSource.gallery),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Name (view or edit)
                if (_isEditing)
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _nameCtrl,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkText),
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        hintStyle: GoogleFonts.inter(fontSize: 20, color: AppColors.lightText),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                        ),
                      ),
                    ),
                  )
                else
                  Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkText)),

                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(role, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(email, style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText)),
                ],
                if (business != null) ...[
                  const SizedBox(height: 4),
                  Text(business.name, style: GoogleFonts.inter(fontSize: 14, color: AppColors.lightText)),
                ],

                // Save/Cancel buttons (edit mode)
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isSaving ? null : _cancelEditing,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Center(
                              child: Text('Cancel', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.midText)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isSaving ? null : _save,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _isSaving ? const Color(0xFFD1D5DB) : AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Save', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Menu sections ──
          _SectionLabel('Documents & Logs'),
          const SizedBox(height: 10),
          _MenuCard(children: [
            _MenuItem(icon: Icons.edit_note_rounded, label: 'Daily Diary', color: const Color(0xFF059669),
              onTap: () => context.go('/diary')),
            _MenuItem(icon: Icons.folder_rounded, label: 'Documents', color: const Color(0xFF2563EB),
              onTap: () => context.go('/documents')),
            _MenuItem(icon: Icons.assessment_rounded, label: 'Reports', color: const Color(0xFF7C3AED),
              onTap: () => context.go('/reports')),
            if (isManager)
              _MenuItem(icon: Icons.local_shipping_rounded, label: 'Suppliers', color: const Color(0xFFEA580C),
                onTap: () => context.go('/suppliers')),
          ]),

          const SizedBox(height: 20),
          _SectionLabel('Settings'),
          const SizedBox(height: 10),
          _MenuCard(children: [
            _MenuItem(icon: Icons.notifications_rounded, label: 'Notifications', color: const Color(0xFFD97706),
              onTap: () => context.go('/notifications')),
            if (isManager)
              _MenuItem(icon: Icons.people_rounded, label: 'Team', color: const Color(0xFF7C3AED),
                onTap: () => context.go('/team')),
          ]),

          const SizedBox(height: 24),

          // ── Sign out ──
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDE9E3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: const Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Text('Sign Out',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Profile? profile, String initial, double size) {
    // Show picked bytes if available
    if (_avatarBytes != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(_avatarBytes!),
      );
    }
    // Show signed URL if available
    if (_avatarSignedUrl != null && profile?.avatarUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(_avatarSignedUrl!),
        onBackgroundImageError: (_, __) {},
        child: Text(initial, style: GoogleFonts.inter(fontSize: size * 0.39, fontWeight: FontWeight.w700, color: AppColors.primary)),
      );
    }
    // Default: initial letter
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(color: AppColors.primaryPale, shape: BoxShape.circle),
      child: Center(child: Text(initial, style: GoogleFonts.inter(fontSize: size * 0.39, fontWeight: FontWeight.w700, color: AppColors.primary))),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightText, letterSpacing: 0.3)),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9E3)),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast) Divider(height: 1, indent: 56, color: const Color(0xFFF1F5F9)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkText)),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: const Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}
