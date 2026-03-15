import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final profile = ref.watch(profileProvider).value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back${profile?.fullName != null ? ', ${profile!.fullName}' : ''}',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Food safety overview',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Today's Status Card
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading stats: $e'),
                ),
              ),
              data: (stats) => Column(
                children: [
                  // Today's Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Status",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatusChip(
                                label: 'Opening',
                                done: stats.openingDone,
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(
                                label: 'Closing',
                                done: stats.closingDone,
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(
                                label: 'Diary',
                                done: stats.diarySigned,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        label: 'Checklists',
                        value: stats.totalChecklists,
                        icon: Icons.checklist,
                        color: AppColors.blue600,
                        bgColor: AppColors.blue50,
                        onTap: () => context.go('/checklists'),
                      ),
                      _StatCard(
                        label: 'Done Today',
                        value: stats.todayCompletions,
                        icon: Icons.check_circle_outline,
                        color: AppColors.green600,
                        bgColor: AppColors.green50,
                        onTap: () => context.go('/diary'),
                      ),
                      _StatCard(
                        label: 'Recipes',
                        value: stats.totalRecipes,
                        icon: Icons.restaurant_menu,
                        color: AppColors.orange600,
                        bgColor: AppColors.orange50,
                        onTap: () => context.go('/recipes'),
                      ),
                      _StatCard(
                        label: 'Incidents',
                        value: stats.openIncidents,
                        icon: Icons.warning_amber,
                        color: AppColors.red600,
                        bgColor: AppColors.red50,
                        onTap: () => context.go('/incidents'),
                      ),
                      _StatCard(
                        label: 'Team',
                        value: stats.teamMembers,
                        icon: Icons.people,
                        color: AppColors.purple600,
                        bgColor: AppColors.purple50,
                        onTap: () => context.go('/team'),
                      ),
                      _StatCard(
                        label: 'Alerts',
                        value: stats.unreadNotifications,
                        icon: Icons.notifications,
                        color: AppColors.yellow600,
                        bgColor: AppColors.yellow50,
                        onTap: () => context.go('/notifications'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _QuickAction(
                                icon: Icons.checklist,
                                label: 'Fill\nChecklist',
                                color: AppColors.blue600,
                                onTap: () => context.go('/checklists'),
                              ),
                              _QuickAction(
                                icon: Icons.calendar_today,
                                label: 'Sign\nDiary',
                                color: AppColors.green600,
                                onTap: () => context.go('/diary'),
                              ),
                              _QuickAction(
                                icon: Icons.menu_book,
                                label: 'Check\nAllergens',
                                color: AppColors.orange600,
                                onTap: () => context.go('/menu'),
                              ),
                              _QuickAction(
                                icon: Icons.warning_amber,
                                label: 'Report\nIncident',
                                color: AppColors.red600,
                                onTap: () => context.go('/incidents'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool done;

  const _StatusChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: done ? AppColors.green50 : AppColors.yellow50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: done ? AppColors.green600 : AppColors.yellow600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: done ? AppColors.green600 : AppColors.yellow600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                '$value',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
