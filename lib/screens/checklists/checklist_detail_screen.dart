import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/checklist.dart';
import '../../providers/auth_provider.dart';
import 'checklists_screen.dart';

class ChecklistDetailScreen extends ConsumerStatefulWidget {
  final String templateId;
  const ChecklistDetailScreen({super.key, required this.templateId});

  @override
  ConsumerState<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends ConsumerState<ChecklistDetailScreen> {
  ChecklistTemplate? _template;
  final Map<String, String> _responses = {};
  final Map<String, String> _notes = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final response = await SupabaseConfig.client
        .from('checklist_templates')
        .select('*, checklist_template_items(*)')
        .eq('id', widget.templateId)
        .single();

    setState(() {
      _template = ChecklistTemplate.fromJson(response);
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null || _template == null) return;

    // Validate required fields
    final requiredItems = _template!.items?.where((i) => i.required) ?? [];
    for (final item in requiredItems) {
      if (!_responses.containsKey(item.id) || _responses[item.id]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please complete: ${item.name}')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Create completion
      final completion = await SupabaseConfig.client
          .from('checklist_completions')
          .insert({
            'template_id': widget.templateId,
            'completed_by': profile.id,
            'business_id': profile.businessId,
          })
          .select()
          .single();

      // Insert responses
      final responseRows = _responses.entries.map((e) => {
            'completion_id': completion['id'],
            'item_id': e.key,
            'value': e.value,
            'notes': _notes[e.key],
            'flagged': _isFlagged(e.key, e.value),
          }).toList();

      await SupabaseConfig.client.from('checklist_responses').insert(responseRows);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist submitted successfully!')),
        );
        context.go('/checklists');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleActive() async {
    if (_template == null) return;
    final newActive = !_template!.active;
    try {
      await SupabaseConfig.client
          .from('checklist_templates')
          .update({'active': newActive})
          .eq('id', widget.templateId);
      ref.invalidate(checklistsProvider);
      await _loadTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newActive ? 'Checklist activated' : 'Checklist deactivated',
              style: GoogleFonts.inter(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.inter())),
        );
      }
    }
  }

  Future<void> _deleteTemplate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Checklist',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.darkText),
        ),
        content: Text(
          'Are you sure you want to delete "${_template!.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.midText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.midText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.red600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseConfig.client
          .from('checklist_templates')
          .delete()
          .eq('id', widget.templateId);
      ref.invalidate(checklistsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checklist deleted', style: GoogleFonts.inter())),
        );
        context.go('/checklists');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting checklist: $e', style: GoogleFonts.inter())),
        );
      }
    }
  }

  bool _isFlagged(String itemId, String value) {
    final item = _template?.items?.firstWhere((i) => i.id == itemId);
    if (item == null) return false;

    if (item.itemType == ChecklistItemType.yes_no && value.toLowerCase() == 'no') {
      return true;
    }
    if (item.itemType == ChecklistItemType.temperature) {
      final numVal = double.tryParse(value);
      if (numVal != null) {
        if (item.minValue != null && numVal < item.minValue!) return true;
        if (item.maxValue != null && numVal > item.maxValue!) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = _template!.items ?? [];
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: AppBar(
        title: Text(_template!.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/checklists'),
        ),
        actions: [
          if (ref.watch(profileProvider).value?.isManager == true)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'history') {
                  context.go('/checklists/${widget.templateId}/history');
                } else if (value == 'toggle_active') {
                  _toggleActive();
                } else if (value == 'delete') {
                  _deleteTemplate();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18, color: AppColors.midText),
                      const SizedBox(width: 10),
                      Text('Completion History', style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Row(
                    children: [
                      Icon(
                        _template!.active ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.midText,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _template!.active ? 'Deactivate' : 'Activate',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: AppColors.red600),
                      const SizedBox(width: 10),
                      Text('Delete', style: GoogleFonts.inter(fontSize: 14, color: AppColors.red600)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (item.required)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.red50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Required',
                                    style: TextStyle(fontSize: 10, color: AppColors.red600)),
                              ),
                          ],
                        ),
                        if (item.description != null) ...[
                          const SizedBox(height: 4),
                          Text(item.description!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                        const SizedBox(height: 12),
                        _buildInput(item),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Submit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : Text('Submit Checklist', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(ChecklistTemplateItem item) {
    switch (item.itemType) {
      case ChecklistItemType.tick:
        return CheckboxListTile(
          value: _responses[item.id] == 'true',
          onChanged: (v) => setState(() => _responses[item.id] = (v ?? false).toString()),
          title: const Text('Done', style: TextStyle(fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );

      case ChecklistItemType.yes_no:
        return Row(
          children: [
            ChoiceChip(
              label: const Text('Yes'),
              selected: _responses[item.id] == 'yes',
              selectedColor: AppColors.green50,
              onSelected: (_) => setState(() => _responses[item.id] = 'yes'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('No'),
              selected: _responses[item.id] == 'no',
              selectedColor: AppColors.red50,
              onSelected: (_) => setState(() => _responses[item.id] = 'no'),
            ),
          ],
        );

      case ChecklistItemType.temperature:
        return TextFormField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter temperature',
            suffixText: item.unit ?? '°C',
            helperText: item.minValue != null && item.maxValue != null
                ? 'Range: ${item.minValue} - ${item.maxValue} ${item.unit ?? '°C'}'
                : null,
          ),
          onChanged: (v) => setState(() => _responses[item.id] = v),
        );

      case ChecklistItemType.text:
        return TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter details...'),
          onChanged: (v) => setState(() => _responses[item.id] = v),
        );
    }
  }
}
