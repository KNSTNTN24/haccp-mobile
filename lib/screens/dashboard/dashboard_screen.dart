import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/startup_checks.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardDataProvider);
    final profile = ref.watch(profileProvider).value;
    final isManager = profile?.isManager ?? false;
    final user = ref.watch(currentUserProvider);

    // Run startup checks (overdue checklists, expiring docs) — once per day
    if (profile != null && user != null) {
      StartupChecks.run(
        businessId: profile.businessId,
        userId: user.id,
        userRole: profile.role.name,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(todayCheckinsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: dataAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
            ),
            error: (e, _) => _ErrorBox(message: '$e'),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Check-in ──
                const _CheckInBlock(),
                const SizedBox(height: 20),

                // ── My Tasks ──
                _MyTasksBlock(data: data),
                const SizedBox(height: 20),

                // ── Team Tasks (managers only) ──
                if (isManager && data.teamTasks.isNotEmpty) ...[
                  _TeamTasksBlock(teamTasks: data.teamTasks),
                  const SizedBox(height: 20),
                ],

                // ── Open Incidents ──
                _IncidentsBlock(incidents: data.openIncidents),
                const SizedBox(height: 20),

                // ── Notifications ──
                _NotificationsBlock(notifications: data.recentNotifications),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHECK-IN / CHECK-OUT
// ─────────────────────────────────────────────

class _CheckInBlock extends ConsumerStatefulWidget {
  const _CheckInBlock();

  @override
  ConsumerState<_CheckInBlock> createState() => _CheckInBlockState();
}

class _CheckInBlockState extends ConsumerState<_CheckInBlock> {
  bool _isLoading = false;

  static const _moodEmojis = ['😊', '🔥', '😴', '💪', '🤒', '😎'];

  Future<void> _toggleCheckIn() async {
    final active = ref.read(myActiveCheckinProvider);
    if (active != null) {
      // Check out directly
      setState(() => _isLoading = true);
      try {
        await checkOut(ref);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Show mood picker bottom sheet
      _showMoodPicker();
    }
  }

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              'How are you feeling?',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a mood for your check-in',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moodEmojis.map((emoji) => GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _doCheckIn(emoji);
                },
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                _doCheckIn(null);
              },
              child: Text(
                'Skip',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doCheckIn(String? mood) async {
    setState(() => _isLoading = true);
    try {
      await checkIn(ref, mood: mood);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(todayCheckinsProvider);
    final activeCheckin = ref.watch(myActiveCheckinProvider);
    final onSite = ref.watch(onSiteStaffProvider);
    final isCheckedIn = activeCheckin != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: 0.6),
          side: BorderSide(color: isCheckedIn ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFEDE9E3)),
        ),
      ),
      child: Column(
        children: [
          // Button row
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isCheckedIn ? AppColors.primaryPale : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCheckedIn ? Icons.location_on_rounded : Icons.location_off_rounded,
                  size: 20,
                  color: isCheckedIn ? AppColors.primary : AppColors.midText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'On Site' : 'Off Site',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkText),
                    ),
                    if (isCheckedIn)
                      Text(
                        'Since ${DateFormat('HH:mm').format(activeCheckin.checkedInAt.toLocal())}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _toggleCheckIn,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: ShapeDecoration(
                    gradient: isCheckedIn
                        ? null
                        : const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF047857)]),
                    color: isCheckedIn ? Colors.white : null,
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: 0.6),
                      side: isCheckedIn
                          ? BorderSide(color: AppColors.error.withValues(alpha: 0.3))
                          : BorderSide.none,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isCheckedIn ? AppColors.error : Colors.white,
                          ),
                        )
                      : Text(
                          isCheckedIn ? 'Leave' : "I'm Here",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isCheckedIn ? AppColors.error : Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // On-site avatars with mood
          if (onSite.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                // Avatar stack
                SizedBox(
                  width: onSite.length > 5
                      ? 5 * 26.0 + 28
                      : onSite.length * 26.0 + 2,
                  height: 42,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < (onSite.length > 5 ? 5 : onSite.length); i++)
                        Positioned(
                          left: i * 26.0,
                          child: Column(
                            children: [
                              Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPale,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    (onSite[i].fullName ?? '?')[0].toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              if (onSite[i].mood != null)
                                Text(onSite[i].mood!, style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${onSite.length} on site',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MY TASKS
// ─────────────────────────────────────────────

class _MyTasksBlock extends StatelessWidget {
  final DashboardData data;
  const _MyTasksBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF065F46), Color(0xFF047857)],
        ),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 22, cornerSmoothing: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 52, height: 52,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: data.progress,
                    trackColor: Colors.white.withValues(alpha: 0.2),
                    fillColor: Colors.white,
                    strokeWidth: 4.5,
                  ),
                  child: Center(
                    child: Text(
                      '${data.completedCount}/${data.totalCount}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Tasks", style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      data.completedCount == data.totalCount
                          ? 'All done! Great job.'
                          : '${data.totalCount - data.completedCount} remaining',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.myTasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...data.myTasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => context.go('/checklists/${task.templateId}'),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted ? Colors.white : Colors.white.withValues(alpha: 0.15),
                        border: task.isCompleted ? null : Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check_rounded, size: 14, color: Color(0xFF059669))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.templateName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: task.isCompleted ? FontWeight.w600 : FontWeight.w400,
                          color: task.isCompleted ? Colors.white : Colors.white.withValues(alpha: 0.65),
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ] else ...[
            const SizedBox(height: 12),
            Text('No checklists assigned', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TEAM TASKS (manager/owner)
// ─────────────────────────────────────────────

class _TeamTasksBlock extends StatelessWidget {
  final List<TeamMemberTasks> teamTasks;
  const _TeamTasksBlock({required this.teamTasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: 0.6),
          side: const BorderSide(color: Color(0xFFEDE9E3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_rounded, size: 20, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text('Team Tasks', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText)),
            ],
          ),
          const SizedBox(height: 14),
          ...teamTasks.map((member) {
            final progressVal = member.total == 0 ? 0.0 : member.completed / member.total;
            final initial = member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: AppColors.primaryPale, shape: BoxShape.circle),
                    child: Center(child: Text(initial, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(member.fullName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                            const SizedBox(width: 8),
                            Text('${member.completed}/${member.total}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.midText)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressVal,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation(
                              progressVal >= 1.0 ? AppColors.primary : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  OPEN INCIDENTS
// ─────────────────────────────────────────────

class _IncidentsBlock extends StatelessWidget {
  final List incidents;
  const _IncidentsBlock({required this.incidents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: 0.6),
          side: const BorderSide(color: Color(0xFFEDE9E3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.go('/incidents'),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, size: 20, color: incidents.isEmpty ? AppColors.midText : const Color(0xFFC2410C)),
                const SizedBox(width: 8),
                Text('Open Incidents', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText)),
                const Spacer(),
                if (incidents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFF1E6), borderRadius: BorderRadius.circular(8)),
                    child: Text('${incidents.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFC2410C))),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.lightText),
              ],
            ),
          ),
          if (incidents.isEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('No open incidents', style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText)),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...incidents.take(3).map((incident) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => context.go('/incidents'),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFC2410C), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        incident.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM').format(DateTime.parse(incident.date)),
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightText),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NOTIFICATIONS
// ─────────────────────────────────────────────

class _NotificationsBlock extends StatelessWidget {
  final List notifications;
  const _NotificationsBlock({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: 0.6),
          side: const BorderSide(color: Color(0xFFEDE9E3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.go('/notifications'),
            child: Row(
              children: [
                Icon(Icons.notifications_rounded, size: 20, color: notifications.isEmpty ? AppColors.midText : const Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text('Notifications', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText)),
                const Spacer(),
                if (notifications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                    child: Text('${notifications.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFD97706))),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.lightText),
              ],
            ),
          ),
          if (notifications.isEmpty) ...[
            const SizedBox(height: 12),
            Text('No new notifications', style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText)),
          ] else ...[
            const SizedBox(height: 12),
            ...notifications.take(3).map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                        Text(n.message, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RING PAINTER
// ─────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  _RingPainter({required this.progress, required this.trackColor, required this.fillColor, required this.strokeWidth});

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
//  ERROR
// ─────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red600, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 14, color: AppColors.red600))),
        ],
      ),
    );
  }
}
