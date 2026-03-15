import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/dashboard'),
    _TabItem(icon: Icons.checklist_outlined, activeIcon: Icons.checklist, label: 'Checklists', path: '/checklists'),
    _TabItem(icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu, label: 'Recipes', path: '/recipes'),
    _TabItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Menu', path: '/menu'),
    _TabItem(icon: Icons.more_horiz_outlined, activeIcon: Icons.more_horiz, label: 'More', path: '/more'),
  ];

  int _currentIndex(String location) {
    if (location.startsWith('/checklists')) return 1;
    if (location.startsWith('/recipes')) return 2;
    if (location.startsWith('/menu')) return 3;
    if (location.startsWith('/diary') ||
        location.startsWith('/incidents') ||
        location.startsWith('/suppliers') ||
        location.startsWith('/team') ||
        location.startsWith('/notifications')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIdx = _currentIndex(location);
    final profile = ref.watch(profileProvider).value;
    final business = ref.watch(businessProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(business?.name ?? 'HACCP Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIdx,
        onTap: (index) {
          if (index == 4) {
            _showMoreMenu(context, profile?.role.name ?? 'kitchen_staff');
          } else {
            context.go(_tabs[index].path);
          }
        },
        items: _tabs.map((tab) {
          return BottomNavigationBarItem(
            icon: Icon(tab.icon),
            activeIcon: Icon(tab.activeIcon),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, String role) {
    final isManager = role == 'owner' || role == 'manager';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _MoreMenuItem(
                icon: Icons.calendar_today,
                label: 'Daily Diary',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/diary');
                },
              ),
              _MoreMenuItem(
                icon: Icons.warning_amber,
                label: 'Incidents',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/incidents');
                },
              ),
              if (isManager) ...[
                _MoreMenuItem(
                  icon: Icons.local_shipping,
                  label: 'Suppliers',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/suppliers');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.people,
                  label: 'Team',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/team');
                  },
                ),
              ],
              _MoreMenuItem(
                icon: Icons.notifications,
                label: 'Notifications',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/notifications');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkBlue),
      title: Text(label),
      onTap: onTap,
    );
  }
}
