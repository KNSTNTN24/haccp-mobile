import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/checklist.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';

final checklistsProvider = FutureProvider<List<ChecklistTemplate>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('checklist_templates')
      .select('*, checklist_template_items(*)')
      .eq('business_id', profile.businessId)
      .eq('active', true)
      .order('name');

  return (response as List).map((e) => ChecklistTemplate.fromJson(e)).toList();
});

class ChecklistsScreen extends ConsumerWidget {
  const ChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistsAsync = ref.watch(checklistsProvider);
    final profile = ref.watch(profileProvider).value;
    final isManager =
        profile?.role == UserRole.owner || profile?.role == UserRole.manager;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isManager
          ? Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => context.go('/checklists/new'),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(checklistsProvider),
        child: checklistsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
          error: (e, _) => _ErrorState(message: '$e'),
          data: (checklists) {
            final filtered = checklists.where((c) {
              if (c.assignedRoles.isEmpty) return true;
              return c.assignedRoles.contains(profile?.role.name ?? '');
            }).toList();

            if (filtered.isEmpty) {
              return _EmptyState(isManager: isManager);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final c = filtered[index];
                return _ChecklistCard(checklist: c);
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  final bool isManager;
  const _EmptyState({required this.isManager});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _checkController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated illustration
              SizedBox(
                width: 180,
                height: 180,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_floatController, _checkController]),
                  builder: (context, child) {
                    final floatY = math.sin(_floatController.value * math.pi) * 8;
                    return Transform.translate(
                      offset: Offset(0, floatY),
                      child: CustomPaint(
                        painter: _ClipboardPainter(
                          checkProgress: _checkController.value,
                        ),
                        size: const Size(180, 180),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Your kitchen is ready',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isManager
                    ? 'Create your first checklist to start\ntracking food safety compliance'
                    : 'Checklists will appear here once\nyour manager sets them up',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.midText,
                  height: 1.5,
                ),
              ),

              if (widget.isManager) ...[
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => context.go('/checklists/new'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Create First Checklist',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Offset for bottom nav
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CLIPBOARD PAINTER — animated empty state
// ─────────────────────────────────────────────

class _ClipboardPainter extends CustomPainter {
  final double checkProgress;

  _ClipboardPainter({required this.checkProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 52, 28, 104, 130),
        const Radius.circular(12),
      ),
      Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Clipboard body
    final bodyPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 48, 24, 96, 126),
        const Radius.circular(10),
      ),
      bodyPaint,
    );

    // Clipboard body border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 48, 24, 96, 126),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Clip at top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 20, 18, 40, 14),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF10B981),
    );

    // Lines
    final linePaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx - 28, 60), Offset(cx + 28, 60), linePaint);
    canvas.drawLine(Offset(cx - 28, 78), Offset(cx + 28, 78), linePaint);
    canvas.drawLine(Offset(cx - 28, 96), Offset(cx + 18, 96), linePaint);

    // Animated checkmarks
    final phase = checkProgress;
    _drawAnimatedCheck(canvas, cx - 32, 55, phase, 0.0);
    _drawAnimatedCheck(canvas, cx - 32, 73, phase, 0.33);
    _drawAnimatedCheck(canvas, cx - 32, 91, phase, 0.66);

    // Sparkles
    _drawSparkle(canvas, cx + 42, 30, phase, 0.0);
    _drawSparkle(canvas, cx - 50, 50, phase, 0.5);
    _drawSparkle(canvas, cx + 50, 80, phase, 0.25);
  }

  void _drawAnimatedCheck(
      Canvas canvas, double x, double y, double phase, double offset) {
    final t = ((phase - offset) % 1.0);
    if (t < 0.15 || t > 0.65) return;

    final opacity = t < 0.3
        ? ((t - 0.15) / 0.15)
        : t > 0.5
            ? ((0.65 - t) / 0.15)
            : 1.0;

    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(x - 3, y + 1)
      ..lineTo(x, y + 4)
      ..lineTo(x + 5, y - 2);

    canvas.drawPath(path, paint);
  }

  void _drawSparkle(
      Canvas canvas, double x, double y, double phase, double offset) {
    final t = ((phase - offset) % 1.0);
    final opacity = (math.sin(t * math.pi * 2) * 0.5 + 0.5) * 0.6;
    final scale = 2 + math.sin(t * math.pi * 2) * 1.5;

    canvas.drawCircle(
      Offset(x, y),
      scale,
      Paint()..color = const Color(0xFF10B981).withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _ClipboardPainter old) =>
      old.checkProgress != checkProgress;
}

// ─────────────────────────────────────────────
//  CHECKLIST CARD
// ─────────────────────────────────────────────

class _ChecklistCard extends StatelessWidget {
  final ChecklistTemplate checklist;
  const _ChecklistCard({required this.checklist});

  @override
  Widget build(BuildContext context) {
    final itemCount = checklist.items?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.go('/checklists/${checklist.id}'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: Color(0xFF059669),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checklist.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            checklist.frequency.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.list_rounded,
                            size: 14, color: AppColors.lightText),
                        const SizedBox(width: 3),
                        Text(
                          '$itemCount items',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.midText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.lightText),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.red600),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.midText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
