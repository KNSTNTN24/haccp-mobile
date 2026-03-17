import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/checklist.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import 'checklists_screen.dart';

class _ChecklistItemEntry {
  String name = '';
  ChecklistItemType type = ChecklistItemType.tick;
  bool required = true;
  String minValue = '';
  String maxValue = '';
  String unit = '°C';
}

class ChecklistManageScreen extends ConsumerStatefulWidget {
  const ChecklistManageScreen({super.key});

  @override
  ConsumerState<ChecklistManageScreen> createState() =>
      _ChecklistManageScreenState();
}

class _ChecklistManageScreenState
    extends ConsumerState<ChecklistManageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ChecklistFrequency _frequency = ChecklistFrequency.daily;
  final List<String> _assignedRoles = [];
  String? _supervisorRole;
  SfbbSection _sfbbSection = SfbbSection.general;
  bool _saving = false;
  final List<_ChecklistItemEntry> _items = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    HapticFeedback.lightImpact();
    setState(() => _items.add(_ChecklistItemEntry()));
  }

  void _removeItem(int i) {
    HapticFeedback.lightImpact();
    setState(() => _items.removeAt(i));
  }

  void _toggleRole(String role) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_assignedRoles.contains(role)) {
        _assignedRoles.remove(role);
      } else {
        _assignedRoles.add(role);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add at least one checklist item',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final profile = ref.read(profileProvider).value;
      if (profile == null) return;
      final db = SupabaseConfig.client;
      final templateResult = await db
          .from('checklist_templates')
          .insert({
            'name': _nameCtrl.text.trim(),
            'description': _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            'frequency': _frequency.name,
            'assigned_roles': _assignedRoles.isEmpty
                ? ['owner', 'manager', 'chef', 'kitchen_staff']
                : _assignedRoles,
            'business_id': profile.businessId,
            'active': true,
            'supervisor_role': _supervisorRole,
            'sfbb_section': _sfbbSection.name,
          })
          .select('id')
          .single();
      final templateId = templateResult['id'] as String;

      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.name.trim().isEmpty) continue;
        await db.from('checklist_template_items').insert({
          'template_id': templateId,
          'name': item.name.trim(),
          'item_type': item.type.name,
          'required': item.required,
          'sort_order': i,
          'min_value':
              item.type == ChecklistItemType.temperature &&
                      item.minValue.isNotEmpty
                  ? double.tryParse(item.minValue)
                  : null,
          'max_value':
              item.type == ChecklistItemType.temperature &&
                      item.maxValue.isNotEmpty
                  ? double.tryParse(item.maxValue)
                  : null,
          'unit':
              item.type == ChecklistItemType.temperature ? item.unit : null,
        });
      }

      ref.invalidate(checklistsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Checklist created!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/checklists');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('New Checklist',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) { context.pop(); } else { context.go('/checklists'); }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // ── Basics section ──
            _SectionHeader(
              icon: Icons.edit_rounded,
              title: 'Basics',
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            _FormCard(
              children: [
                _StyledTextField(
                  controller: _nameCtrl,
                  label: 'Checklist Name',
                  hint: 'e.g. Opening Checks',
                  required: true,
                  icon: Icons.badge_rounded,
                ),
                const SizedBox(height: 16),
                _StyledTextField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Optional notes about this checklist',
                  maxLines: 3,
                  icon: Icons.notes_rounded,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Schedule section ──
            _SectionHeader(
              icon: Icons.schedule_rounded,
              title: 'Schedule',
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 14),
            _FormCard(
              children: [
                Text(
                  'How often should this be completed?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.midText,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ChecklistFrequency.values.map((f) {
                    final selected = _frequency == f;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _frequency = f);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2563EB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          f.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : AppColors.darkText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── SFBB Category section ──
            _SectionHeader(
              icon: Icons.category_rounded,
              title: 'SFBB Category',
              color: const Color(0xFF0891B2),
            ),
            const SizedBox(height: 14),
            _FormCard(
              children: [
                Text(
                  'Which SFBB section does this relate to?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.midText,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SfbbSection.values.map((s) {
                    final selected = _sfbbSection == s;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _sfbbSection = s);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF0891B2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF0891B2)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          s.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : AppColors.darkText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Roles section ──
            _SectionHeader(
              icon: Icons.people_rounded,
              title: 'Assigned Roles',
              color: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 14),
            _FormCard(
              children: [
                Text(
                  'Who should complete this checklist?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.midText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave empty for all roles',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: UserRole.values.map((role) {
                    final selected = _assignedRoles.contains(role.name);
                    return GestureDetector(
                      onTap: () => _toggleRole(role.name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF7C3AED)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) ...[
                              const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              role.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : AppColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Supervisor section ──
            _SectionHeader(
              icon: Icons.verified_user_rounded,
              title: 'Supervisor',
              color: const Color(0xFFD97706),
            ),
            const SizedBox(height: 14),
            _FormCard(
              children: [
                Text(
                  'Optionally assign a role to sign off completions',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.midText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave as "None" if sign-off is not required',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _supervisorRole = null);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _supervisorRole == null
                              ? const Color(0xFFD97706)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _supervisorRole == null
                                ? const Color(0xFFD97706)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          'None',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _supervisorRole == null
                                ? Colors.white
                                : AppColors.darkText,
                          ),
                        ),
                      ),
                    ),
                    ...UserRole.values.map((role) {
                      final selected = _supervisorRole == role.name;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _supervisorRole = role.name);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFD97706)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) ...[
                                const Icon(Icons.check_rounded,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                role.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Items section ──
            Row(
              children: [
                Expanded(
                  child: _SectionHeader(
                    icon: Icons.list_alt_rounded,
                    title: 'Checklist Items',
                    color: const Color(0xFFEA580C),
                  ),
                ),
                GestureDetector(
                  onTap: _addItem,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: GoogleFonts.inter(
                            fontSize: 14,
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
            const SizedBox(height: 14),

            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.playlist_add_rounded,
                        size: 36, color: AppColors.lightText),
                    const SizedBox(height: 10),
                    Text(
                      'No items yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.midText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "+ Add" to create checklist items',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return _ItemCard(
                  index: idx,
                  item: item,
                  onRemove: () => _removeItem(idx),
                  onTypeChanged: (v) => setState(() => item.type = v),
                  onRequiredChanged: (v) =>
                      setState(() => item.required = v),
                );
              }),

            const SizedBox(height: 32),

            // ── Save button ──
            GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _saving
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                  color: _saving ? const Color(0xFFD1D5DB) : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _saving
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Checklist',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  FORM CARD
// ─────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STYLED TEXT FIELD
// ─────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  final int maxLines;
  final IconData icon;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
    this.maxLines = 1,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.midText),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            if (required)
              Text(' *',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 15, color: AppColors.lightText),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
          ),
          validator: required
              ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
              : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  ITEM CARD
// ─────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final int index;
  final _ChecklistItemEntry item;
  final VoidCallback onRemove;
  final ValueChanged<ChecklistItemType> onTypeChanged;
  final ValueChanged<bool> onRequiredChanged;

  const _ItemCard({
    required this.index,
    required this.item,
    required this.onRemove,
    required this.onTypeChanged,
    required this.onRequiredChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Item ${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Name field
            TextFormField(
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'What needs to be checked?',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.lightText),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF10B981), width: 2),
                ),
              ),
              onChanged: (v) => item.name = v,
            ),
            const SizedBox(height: 12),

            // Type + Required row
            Row(
              children: [
                // Type selector
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ChecklistItemType>(
                        value: item.type,
                        isExpanded: true,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.darkText),
                        icon: const Icon(Icons.expand_more_rounded,
                            size: 20),
                        items: ChecklistItemType.values
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onTypeChanged(v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Required toggle
                GestureDetector(
                  onTap: () => onRequiredChanged(!item.required),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: item.required
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.required
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.required
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 16,
                          color: item.required
                              ? const Color(0xFF10B981)
                              : AppColors.lightText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Required',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: item.required
                                ? const Color(0xFF059669)
                                : AppColors.midText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Temperature fields
            if (item.type == ChecklistItemType.temperature) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: GoogleFonts.inter(fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min',
                        labelStyle: GoogleFonts.inter(fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      onChanged: (v) => item.minValue = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      style: GoogleFonts.inter(fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max',
                        labelStyle: GoogleFonts.inter(fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      onChanged: (v) => item.maxValue = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      initialValue: '°C',
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: GoogleFonts.inter(fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      onChanged: (v) => item.unit = v,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
