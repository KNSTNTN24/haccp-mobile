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
    _TabItem(icon: Icons.restaurant_menu_rounded, label: 'Menu', path: '/menu'),
    _TabItem(icon: Icons.inventory_2_rounded, label: 'Deliveries', path: '/deliveries'),
    _TabItem(icon: Icons.warning_rounded, label: 'Incidents', path: '/incidents'),
  ];

  static const _titles = <String, String?>{
    '/dashboard': null,
    '/checklists': 'Checklists',
    '/recipes': 'Recipes',
    '/menu': 'Menu',
    '/profile': 'Profile',
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
    if (location.startsWith('/menu')) return 2;
    if (location.startsWith('/deliveries')) return 3;
    if (location.startsWith('/incidents')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIdx = _currentIndex(location);
    final profile = ref.watch(profileProvider).value;
    final firstName = profile?.fullName?.split(' ').first ?? '';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    final title = location == '/dashboard' && firstName.isNotEmpty
        ? 'Hi, $firstName'
        : _titles[location] ?? 'HACCP';

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
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(
                color: AppColors.primaryPale,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initial,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ),
          ),
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
                      HapticFeedback.selectionClick();
                      context.go(tab.path);
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

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}
