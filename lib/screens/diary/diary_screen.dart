import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/checklist.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../utils/diary_export.dart';

// Provider: checklists completed on a given date
final diaryChecklistsProvider =
    FutureProvider.family<List<ChecklistCompletion>, String>((ref, date) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final nextDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.parse(date).add(const Duration(days: 1)));

  final response = await SupabaseConfig.client
      .from('checklist_completions')
      .select(
          '*, profiles:completed_by(full_name), signer:profiles!signed_off_by(full_name), checklist_templates!template_id(name, supervisor_role)')
      .eq('business_id', profile.businessId)
      .gte('completed_at', '${date}T00:00:00')
      .lt('completed_at', '${nextDate}T00:00:00')
      .order('completed_at');

  return (response as List)
      .map((e) => ChecklistCompletion.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Provider: incidents on a given date
final diaryIncidentsProvider =
    FutureProvider.family<List<Incident>, String>((ref, date) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('incidents')
      .select('*, profiles:reported_by(full_name)')
      .eq('business_id', profile.businessId)
      .eq('date', date)
      .order('created_at');

  return (response as List)
      .map((e) => Incident.fromJson(e as Map<String, dynamic>))
      .toList();
});

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ExportSheet(currentDate: _selectedDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checklistsAsync = ref.watch(diaryChecklistsProvider(_selectedDate));
    final incidentsAsync = ref.watch(diaryIncidentsProvider(_selectedDate));
    final dateObj = DateTime.parse(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == _selectedDate;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(diaryChecklistsProvider(_selectedDate));
          ref.invalidate(diaryIncidentsProvider(_selectedDate));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date selector ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      color: AppColors.primary,
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateFormat('yyyy-MM-dd')
                              .format(dateObj.subtract(const Duration(days: 1)));
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dateObj,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEEE').format(dateObj),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.midText,
                            ),
                          ),
                          Text(
                            DateFormat('d MMMM yyyy').format(dateObj),
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Today',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      color: dateObj.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                          ? AppColors.primary
                          : AppColors.lightText,
                      onPressed: dateObj.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                          ? () {
                              setState(() {
                                _selectedDate = DateFormat('yyyy-MM-dd')
                                    .format(dateObj.add(const Duration(days: 1)));
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Checklists Section ──
              checklistsAsync.when(
                loading: () => _buildSectionShimmer('Checklists'),
                error: (e, _) => _buildSectionError('Checklists', '$e'),
                data: (checklists) => _buildChecklistsSection(checklists),
              ),

              const SizedBox(height: 20),

              // ── Incidents Section ──
              incidentsAsync.when(
                loading: () => _buildSectionShimmer('Incidents'),
                error: (e, _) => _buildSectionError('Incidents', '$e'),
                data: (incidents) => _buildIncidentsSection(incidents),
              ),

              const SizedBox(height: 24),

              // ── Export Button ──
              GestureDetector(
                onTap: _showExportSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Export Report',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionShimmer(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, count: null),
        const SizedBox(height: 12),
        const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildSectionError(String title, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, count: 0),
        const SizedBox(height: 8),
        Text('Error: $error', style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
      ],
    );
  }

  Widget _buildChecklistsSection(List<ChecklistCompletion> checklists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Checklists',
          count: checklists.length,
          icon: Icons.checklist_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        if (checklists.isEmpty)
          _EmptyCard(
            icon: Icons.checklist_rounded,
            message: 'No checklists completed',
          )
        else
          ...checklists.map((c) => _ChecklistCard(completion: c)),
      ],
    );
  }

  Widget _buildIncidentsSection(List<Incident> incidents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Incidents',
          count: incidents.length,
          icon: Icons.warning_amber_rounded,
          color: AppColors.orange600,
        ),
        const SizedBox(height: 12),
        if (incidents.isEmpty)
          _EmptyCard(
            icon: Icons.shield_outlined,
            message: 'No incidents reported',
          )
        else
          ...incidents.map((i) => _IncidentCard(incident: i)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final IconData? icon;
  final Color? color;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color ?? AppColors.primary),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY CARD
// ─────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.lightText),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.midText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHECKLIST CARD
// ─────────────────────────────────────────────

class _ChecklistCard extends StatelessWidget {
  final ChecklistCompletion completion;
  const _ChecklistCard({required this.completion});

  @override
  Widget build(BuildContext context) {
    final status = completion.displayStatus;
    final timeStr = DateFormat('HH:mm').format(completion.completedAt.toLocal());

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Completed':
        statusColor = AppColors.green600;
        statusIcon = Icons.check_circle;
      case 'Signed Off':
        statusColor = AppColors.green600;
        statusIcon = Icons.verified;
      case 'Awaiting Sign-off':
        statusColor = AppColors.orange600;
        statusIcon = Icons.pending_actions;
      default:
        statusColor = AppColors.midText;
        statusIcon = Icons.circle;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, size: 20, color: statusColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completion.templateName ?? 'Checklist',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: AppColors.midText),
                      const SizedBox(width: 4),
                      Text(
                        completion.completedByName ?? 'Unknown',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: AppColors.midText),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
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
//  INCIDENT CARD
// ─────────────────────────────────────────────

class _IncidentCard extends StatelessWidget {
  final Incident incident;
  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final isResolved = incident.isResolved;
    final isComplaint = incident.type == 'complaint';
    final timeStr = DateFormat('HH:mm').format(incident.createdAt.toLocal());

    final typeColor = isComplaint ? AppColors.orange600 : AppColors.red600;
    final statusColor = isResolved ? AppColors.green600 : AppColors.red600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isComplaint ? Icons.feedback_outlined : Icons.report_problem_outlined,
                size: 20,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isComplaint ? 'Complaint' : 'Incident',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: typeColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isResolved ? 'Resolved' : 'Open',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    incident.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: AppColors.midText),
                      const SizedBox(width: 4),
                      Text(
                        incident.reportedByName ?? 'Unknown',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: AppColors.midText),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText),
                      ),
                    ],
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

// ─────────────────────────────────────────────
//  EXPORT BOTTOM SHEET
// ─────────────────────────────────────────────

class _ExportSheet extends ConsumerStatefulWidget {
  final String currentDate;
  const _ExportSheet({required this.currentDate});

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  late DateTime _fromDate;
  late DateTime _toDate;
  bool _includeChecklists = true;
  bool _includeIncidents = true;
  String _format = 'pdf';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Default: current week
    final now = DateTime.now();
    final weekday = now.weekday;
    _fromDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
    _toDate = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
          if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
        }
      });
    }
  }

  Future<void> _generate() async {
    if (!_includeChecklists && !_includeIncidents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one category to include')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final profile = ref.read(profileProvider).value;
      final business = ref.read(businessProvider).value;
      if (profile == null) return;

      final businessName = business?.name ?? 'Business';

      // Load data
      final data = await loadDiaryReportData(
        businessId: profile.businessId,
        fromDate: _fromDate,
        toDate: _toDate,
        includeChecklists: _includeChecklists,
        includeIncidents: _includeIncidents,
      );

      if (_format == 'pdf') {
        final pdfBytes = await generateDiaryPdf(
          businessName: businessName,
          fromDate: _fromDate,
          toDate: _toDate,
          checklists: data.checklists,
          incidents: data.incidents,
        );
        await downloadFile(pdfBytes, 'diary_report_${DateFormat('yyyyMMdd').format(_fromDate)}_${DateFormat('yyyyMMdd').format(_toDate)}.pdf');
      } else {
        final csvContent = generateDiaryCsv(
          fromDate: _fromDate,
          toDate: _toDate,
          checklists: data.checklists,
          incidents: data.incidents,
        );
        final csvBytes = Uint8List.fromList(utf8.encode(csvContent));
        await downloadFile(csvBytes, 'diary_report_${DateFormat('yyyyMMdd').format(_fromDate)}_${DateFormat('yyyyMMdd').format(_toDate)}.csv');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Report generated!', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Export Report',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkText),
          ),
          const SizedBox(height: 20),

          // Date range
          Text('Date Range', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _DateButton(label: 'From', date: _fromDate, onTap: () => _pickDate(true))),
              const SizedBox(width: 12),
              Expanded(child: _DateButton(label: 'To', date: _toDate, onTap: () => _pickDate(false))),
            ],
          ),
          const SizedBox(height: 20),

          // Include
          Text('Include', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ToggleChip(
                label: 'Checklists',
                icon: Icons.checklist_rounded,
                selected: _includeChecklists,
                onTap: () => setState(() => _includeChecklists = !_includeChecklists),
              ),
              const SizedBox(width: 10),
              _ToggleChip(
                label: 'Incidents',
                icon: Icons.warning_amber_rounded,
                selected: _includeIncidents,
                onTap: () => setState(() => _includeIncidents = !_includeIncidents),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Format
          Text('Format', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 10),
          Row(
            children: [
              _FormatChip(label: 'PDF', icon: Icons.picture_as_pdf, selected: _format == 'pdf', onTap: () => setState(() => _format = 'pdf')),
              const SizedBox(width: 10),
              _FormatChip(label: 'CSV', icon: Icons.table_chart_outlined, selected: _format == 'csv', onTap: () => setState(() => _format = 'csv')),
            ],
          ),
          const SizedBox(height: 24),

          // Generate
          GestureDetector(
            onTap: _isGenerating ? null : _generate,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: _isGenerating
                    ? null
                    : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                color: _isGenerating ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isGenerating
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: _isGenerating
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Generate ${_format.toUpperCase()}',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.midText)),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.midText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FormatChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.midText),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
