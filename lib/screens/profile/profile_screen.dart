import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final business = ref.watch(businessProvider).value;
    final name = profile?.fullName ?? 'User';
    final role = profile?.role.displayName ?? '';
    final email = profile?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isManager = profile?.role == UserRole.owner || profile?.role == UserRole.manager;

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
              // no shadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(color: AppColors.primaryPale, shape: BoxShape.circle),
                  child: Center(child: Text(initial, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary))),
                ),
                const SizedBox(height: 16),
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
        // no shadow,
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
