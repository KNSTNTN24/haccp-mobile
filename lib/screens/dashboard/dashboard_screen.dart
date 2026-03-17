import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final profile = ref.watch(profileProvider).value;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(dashboardStatsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: statsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
                error: (e, _) => _ErrorBox(message: '$e'),
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily Diary
                    GestureDetector(
                      onTap: () => context.go('/diary'),
                      child: _DailyProgress(stats: stats),
                    ),
                    const SizedBox(height: 28),
                    _SectionLabel('Overview'),
                    const SizedBox(height: 14),
                    _StatsGrid(stats: stats),
                    const SizedBox(height: 28),
                    _SectionLabel('Quick Actions'),
                    const SizedBox(height: 14),
                    _QuickActions(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Profile? profile;
  const _Header({this.profile});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName?.split(' ').first ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting${name.isNotEmpty ? ',' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.midText,
                  ),
                ),
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DAILY PROGRESS
// ─────────────────────────────────────────────

class _DailyProgress extends StatelessWidget {
  final DashboardStats stats;
  const _DailyProgress({required this.stats});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      _Task('Opening check', stats.openingDone),
      _Task('Closing check', stats.closingDone),
      _Task('Diary signed', stats.diarySigned),
    ];
    final done = tasks.where((t) => t.done).length;
    final progress = done / tasks.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              // Ring
              SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: progress,
                    trackColor: Colors.white.withValues(alpha: 0.2),
                    fillColor: Colors.white,
                    strokeWidth: 5,
                  ),
                  child: Center(
                    child: Text(
                      '$done/${tasks.length}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Tasks",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done == tasks.length
                          ? 'All done! Great job.'
                          : '${tasks.length - done} remaining',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Task rows
          ...tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.done
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        border: t.done
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1.5),
                      ),
                      child: t.done
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Color(0xFF059669))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: t.done ? FontWeight.w600 : FontWeight.w400,
                        color: t.done
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Task {
  final String label;
  final bool done;
  const _Task(this.label, this.done);
}

// ─────────────────────────────────────────────
//  RING PAINTER
// ─────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint..color = trackColor);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = fillColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
//  STATS GRID
// ─────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Stat('Checklists', stats.totalChecklists, Icons.checklist_rounded,
          const Color(0xFF2563EB), const Color(0xFFEFF6FF), '/checklists'),
      _Stat('Completed', stats.todayCompletions, Icons.task_alt_rounded,
          const Color(0xFF059669), const Color(0xFFECFDF5), '/diary'),
      _Stat('Recipes', stats.totalRecipes, Icons.restaurant_rounded,
          const Color(0xFFEA580C), const Color(0xFFFFF7ED), '/recipes'),
      _Stat('Incidents', stats.openIncidents, Icons.warning_rounded,
          const Color(0xFFDC2626), const Color(0xFFFEF2F2), '/incidents'),
      _Stat('Team', stats.teamMembers, Icons.people_rounded,
          const Color(0xFF7C3AED), const Color(0xFFF5F3FF), '/team'),
      _Stat('Alerts', stats.unreadNotifications, Icons.notifications_active_rounded,
          const Color(0xFFD97706), const Color(0xFFFFFBEB), '/notifications'),
    ];

    return Column(
      children: [
        for (int r = 0; r < 3; r++) ...[
          if (r > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(data: items[r * 2])),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(data: items[r * 2 + 1])),
            ],
          ),
        ],
      ],
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  final String route;
  const _Stat(this.label, this.value, this.icon, this.color, this.bg, this.route);
}

class _StatTile extends StatelessWidget {
  final _Stat data;
  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasIssue = data.label == 'Incidents' && data.value > 0;

    return GestureDetector(
      onTap: () => context.go(data.route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Colored dot accent
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: data.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, size: 20, color: data.color),
                ),
                if (hasIssue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Open',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: data.color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${data.value}',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.midText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUICK ACTIONS
// ─────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(Icons.checklist_rounded, 'Checklist', const Color(0xFF2563EB), '/checklists'),
      _Action(Icons.edit_note_rounded, 'Diary', const Color(0xFF10B981), '/diary'),
      _Action(Icons.egg_alt_rounded, 'Allergens', const Color(0xFFEA580C), '/menu'),
      _Action(Icons.warning_rounded, 'Incident', const Color(0xFFDC2626), '/incidents'),
    ];

    return Row(
      children: actions.asMap().entries.map((e) {
        final i = e.key;
        final a = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 6,
              right: i == actions.length - 1 ? 0 : 6,
            ),
            child: GestureDetector(
              onTap: () => context.go(a.route),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Icon(a.icon, size: 28, color: a.color),
                    const SizedBox(height: 10),
                    Text(
                      a.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _Action(this.icon, this.label, this.color, this.route);
}

// ─────────────────────────────────────────────
//  ERROR
// ─────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.red600)),
          ),
        ],
      ),
    );
  }
}
