import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.grid_view_rounded, label: 'Home', path: '/dashboard'),
    _TabItem(icon: Icons.checklist_rounded, label: 'Checks', path: '/checklists'),
    _TabItem(icon: Icons.restaurant_rounded, label: 'Recipes', path: '/recipes'),
    _TabItem(icon: Icons.egg_alt_rounded, label: 'Menu', path: '/menu'),
    _TabItem(icon: Icons.more_horiz_rounded, label: 'More', path: '/more'),
  ];

  static const _titles = {
    '/dashboard': 'Home',
    '/checklists': 'Checklists',
    '/recipes': 'Recipes',
    '/menu': 'Menu',
    '/diary': 'Daily Diary',
    '/incidents': 'Incidents',
    '/suppliers': 'Suppliers',
    '/team': 'Team',
    '/notifications': 'Notifications',
    '/documents': 'Documents',
    '/ai-import': 'AI Import',
    '/deliveries': 'Deliveries',
  };

  int _currentIndex(String location) {
    if (location.startsWith('/checklists')) return 1;
    if (location.startsWith('/recipes')) return 2;
    if (location.startsWith('/menu')) return 3;
    if (location.startsWith('/diary') ||
        location.startsWith('/incidents') ||
        location.startsWith('/suppliers') ||
        location.startsWith('/team') ||
        location.startsWith('/documents') ||
        location.startsWith('/notifications') ||
        location.startsWith('/ai-import') ||
        location.startsWith('/deliveries')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIdx = _currentIndex(location);
    final profile = ref.watch(profileProvider).value;
    final title = _titles[location] ?? 'HACCP';

    return Scaffold(
      appBar: AppBar(
        title: Text(title,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkText),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 24, color: AppColors.midText),
            onPressed: () => context.go('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final isActive = i == currentIdx;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i == 4) {
                        HapticFeedback.lightImpact();
                        _showMoreMenu(context, ref, profile?.role.name ?? 'kitchen_staff');
                      } else {
                        HapticFeedback.selectionClick();
                        context.go(tab.path);
                      }
                    },
                    child: _NavBarItem(icon: tab.icon, label: tab.label, isActive: isActive),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref, String role) {
    final isManager = role == 'owner' || role == 'manager';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _MoreItem(icon: Icons.edit_note_rounded, label: 'Daily Diary', color: AppColors.green600,
                        onTap: () { Navigator.pop(context); context.go('/diary'); }),
                      _MoreItem(icon: Icons.warning_rounded, label: 'Incidents', color: AppColors.red600,
                        onTap: () { Navigator.pop(context); context.go('/incidents'); }),
                      _MoreItem(icon: Icons.inventory_2_rounded, label: 'Deliveries', color: const Color(0xFF0891B2),
                        onTap: () { Navigator.pop(context); context.go('/deliveries'); }),
                      if (isManager) ...[
                        _MoreItem(icon: Icons.local_shipping_rounded, label: 'Suppliers', color: AppColors.orange600,
                          onTap: () { Navigator.pop(context); context.go('/suppliers'); }),
                        _MoreItem(icon: Icons.people_rounded, label: 'Team', color: AppColors.purple600,
                          onTap: () { Navigator.pop(context); context.go('/team'); }),
                      ],
                      _MoreItem(icon: Icons.folder_rounded, label: 'Documents', color: AppColors.blue600,
                        onTap: () { Navigator.pop(context); context.go('/documents'); }),
                      _MoreItem(icon: Icons.auto_awesome_rounded, label: 'AI Recipe Import', color: AppColors.primary,
                        onTap: () { Navigator.pop(context); context.go('/ai-import'); }),
                      _MoreItem(icon: Icons.notifications_rounded, label: 'Notifications', color: AppColors.yellow600,
                        onTap: () { Navigator.pop(context); context.go('/notifications'); }),
                      const Divider(height: 24),
                      _MoreItem(icon: Icons.logout_rounded, label: 'Sign Out', color: AppColors.midText,
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(authNotifierProvider.notifier).signOut();
                          if (context.mounted) context.go('/login');
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  const _NavBarItem({required this.icon, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: isActive ? 20 : 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 24, color: isActive ? AppColors.primary : const Color(0xFFADB5BD)),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.primary : const Color(0xFFADB5BD),
          )),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MoreItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 16),
                Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkText)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 20, color: const Color(0xFFD1D5DB)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}
