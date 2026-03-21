import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/reports_export.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  bool _isGenerating = false;
  bool _isLoadingTemplates = true;

  List<_TemplateOption> _templates = [];
  final Set<String> _selectedTemplateIds = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = now.subtract(const Duration(days: 7));
    _toDate = now;
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final profile = ref.read(profileProvider).value;
      if (profile == null) return;

      final data = await SupabaseConfig.client
          .from('checklist_templates')
          .select('id, name')
          .eq('business_id', profile.businessId)
          .eq('active', true)
          .order('name');

      if (mounted) {
        setState(() {
          _templates = (data as List)
              .map((t) => _TemplateOption(id: t['id'] as String, name: t['name'] as String))
              .toList();
          _isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTemplates = false);
      }
    }
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
    setState(() => _isGenerating = true);

    try {
      final profile = ref.read(profileProvider).value;
      final business = ref.read(businessProvider).value;
      if (profile == null) return;

      final businessName = business?.name ?? 'Business';

      final completions = await loadReportData(
        businessId: profile.businessId,
        fromDate: _fromDate,
        toDate: _toDate,
        templateIds: _selectedTemplateIds,
      );

      final pdfBytes = await generateReportPdf(
        businessName: businessName,
        fromDate: _fromDate,
        toDate: _toDate,
        completions: completions,
      );

      final filename = 'compliance_report_${DateFormat('yyyyMMdd').format(_fromDate)}_${DateFormat('yyyyMMdd').format(_toDate)}.pdf';
      await downloadReportFile(pdfBytes, filename);

      if (mounted) {
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
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Generate a compliance report for EHO inspections. Select a date range and checklists to include.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText, height: 1.5),
            ),
            const SizedBox(height: 24),

            // ── Date Range ──
            Text('Date Range', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkText)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: 'From',
                    date: dateFormat.format(_fromDate),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateCard(
                    label: 'To',
                    date: dateFormat.format(_toDate),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick presets
            Row(
              children: [
                _PresetChip(
                  label: '7 days',
                  onTap: () {
                    setState(() {
                      _toDate = DateTime.now();
                      _fromDate = _toDate.subtract(const Duration(days: 7));
                    });
                  },
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: '30 days',
                  onTap: () {
                    setState(() {
                      _toDate = DateTime.now();
                      _fromDate = _toDate.subtract(const Duration(days: 30));
                    });
                  },
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: '90 days',
                  onTap: () {
                    setState(() {
                      _toDate = DateTime.now();
                      _fromDate = _toDate.subtract(const Duration(days: 90));
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Checklists ──
            Text('Checklists', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkText)),
            const SizedBox(height: 4),
            Text(
              _selectedTemplateIds.isEmpty ? 'All checklists included' : '${_selectedTemplateIds.length} selected',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText),
            ),
            const SizedBox(height: 12),

            if (_isLoadingTemplates)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _templates.map((t) {
                  final isSelected = _selectedTemplateIds.contains(t.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTemplateIds.remove(t.id);
                        } else {
                          _selectedTemplateIds.add(t.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: ShapeDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF9FAFB),
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 0.6),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            t.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? AppColors.primary : AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 36),

            // ── Generate Button ──
            GestureDetector(
              onTap: _isGenerating ? null : _generate,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: ShapeDecoration(
                  gradient: _isGenerating
                      ? null
                      : const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF047857)]),
                  color: _isGenerating ? Colors.grey.shade300 : null,
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 0.6),
                  ),
                  shadows: _isGenerating
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF047857).withValues(alpha: 0.3),
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
                            const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Generate PDF Report',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Report includes per-item breakdown with flagged items highlighted',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightText),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateOption {
  final String id;
  final String name;
  _TemplateOption({required this.id, required this.name});
}

class _DateCard extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;
  const _DateCard({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 0.6),
            side: const BorderSide(color: Color(0xFFEDE9E3)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.midText)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midText),
        ),
      ),
    );
  }
}
