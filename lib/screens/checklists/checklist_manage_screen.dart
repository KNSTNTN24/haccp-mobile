import 'package:flutter/material.dart';
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
  ConsumerState<ChecklistManageScreen> createState() => _ChecklistManageScreenState();
}

class _ChecklistManageScreenState extends ConsumerState<ChecklistManageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ChecklistFrequency _frequency = ChecklistFrequency.daily;
  final List<String> _assignedRoles = [];
  bool _saving = false;
  final List<_ChecklistItemEntry> _items = [];

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  void _addItem() => setState(() => _items.add(_ChecklistItemEntry()));
  void _removeItem(int i) => setState(() => _items.removeAt(i));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    try {
      final profile = ref.read(profileProvider).value;
      if (profile == null) return;
      final db = SupabaseConfig.client;
      final templateResult = await db.from('checklist_templates').insert({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'frequency': _frequency.name,
        'assigned_roles': _assignedRoles.isEmpty ? ['owner', 'manager', 'chef', 'kitchen_staff'] : _assignedRoles,
        'business_id': profile.businessId,
        'active': true,
      }).select('id').single();
      final templateId = templateResult['id'] as String;

      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.name.trim().isEmpty) continue;
        await db.from('checklist_template_items').insert({
          'template_id': templateId, 'name': item.name.trim(), 'item_type': item.type.name,
          'required': item.required, 'sort_order': i,
          'min_value': item.type == ChecklistItemType.temperature && item.minValue.isNotEmpty ? double.tryParse(item.minValue) : null,
          'max_value': item.type == ChecklistItemType.temperature && item.maxValue.isNotEmpty ? double.tryParse(item.maxValue) : null,
          'unit': item.type == ChecklistItemType.temperature ? item.unit : null,
        });
      }

      ref.invalidate(checklistsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checklist created!'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Checklist', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)), backgroundColor: AppColors.darkBlue, foregroundColor: AppColors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Checklist Name *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 12),
            DropdownButtonFormField<ChecklistFrequency>(value: _frequency, decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()), items: ChecklistFrequency.values.map((f) => DropdownMenuItem(value: f, child: Text(f.displayName))).toList(), onChanged: (v) => setState(() => _frequency = v!)),
            const SizedBox(height: 12),
            Text('Assigned Roles', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: UserRole.values.map((role) {
              final selected = _assignedRoles.contains(role.name);
              return FilterChip(label: Text(role.displayName), selected: selected, selectedColor: AppColors.gold.withValues(alpha: 0.3), onSelected: (sel) => setState(() => sel ? _assignedRoles.add(role.name) : _assignedRoles.remove(role.name)));
            }).toList()),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Checklist Items', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBlue)),
              TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add, size: 18), label: const Text('Add Item')),
            ]),
            ..._items.asMap().entries.map((entry) {
              final idx = entry.key; final item = entry.value;
              return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                Row(children: [
                  Expanded(child: TextFormField(decoration: InputDecoration(labelText: 'Item ${idx + 1} *', border: const OutlineInputBorder(), isDense: true), onChanged: (v) => item.name = v)),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _removeItem(idx)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<ChecklistItemType>(value: item.type, decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true), items: ChecklistItemType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(), onChanged: (v) => setState(() => item.type = v!))),
                  const SizedBox(width: 8),
                  Row(children: [
                    Checkbox(value: item.required, activeColor: AppColors.gold, onChanged: (v) => setState(() => item.required = v!)),
                    const Text('Required', style: TextStyle(fontSize: 12)),
                  ]),
                ]),
                if (item.type == ChecklistItemType.temperature) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (v) => item.minValue = v)),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Max', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (v) => item.maxValue = v)),
                    const SizedBox(width: 8),
                    SizedBox(width: 70, child: TextFormField(initialValue: '°C', decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder(), isDense: true), onChanged: (v) => item.unit = v)),
                  ]),
                ],
              ])));
            }),
            const SizedBox(height: 24),
            SizedBox(height: 48, child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Save Checklist', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
