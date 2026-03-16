import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/supplier.dart';
import '../../providers/auth_provider.dart';

final suppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('suppliers')
      .select()
      .eq('business_id', profile.businessId)
      .order('name');

  return (response as List).map((e) => Supplier.fromJson(e)).toList();
});

const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    _showSupplierSheet(context, ref, supplier: null);
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Supplier supplier) {
    _showSupplierSheet(context, ref, supplier: supplier);
  }

  void _showSupplierSheet(BuildContext context, WidgetRef ref, {Supplier? supplier}) {
    final isEdit = supplier != null;
    final nameCtrl = TextEditingController(text: supplier?.name ?? '');
    final contactCtrl = TextEditingController(text: supplier?.contactName ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');
    final goodsCtrl = TextEditingController(text: supplier?.goodsSupplied ?? '');
    final selectedDays = <String>[...?supplier?.deliveryDays];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Edit Supplier' : 'Add Supplier',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: goodsCtrl, decoration: const InputDecoration(labelText: 'Goods Supplied', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Text('Delivery Days:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: _weekDays.map((d) {
                    final sel = selectedDays.contains(d);
                    return FilterChip(
                      label: Text(d, style: TextStyle(fontSize: 12, color: sel ? Colors.white : null)),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      onSelected: (s) => setSheetState(() => s ? selectedDays.add(d) : selectedDays.remove(d)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final profile = ref.read(profileProvider).value;
                    if (profile == null) return;

                    final data = {
                      'name': nameCtrl.text.trim(),
                      'contact_name': contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                      'goods_supplied': goodsCtrl.text.trim().isEmpty ? null : goodsCtrl.text.trim(),
                      'delivery_days': selectedDays,
                      'business_id': profile.businessId,
                    };

                    if (isEdit) {
                      await SupabaseConfig.client
                          .from('suppliers')
                          .update(data)
                          .eq('id', supplier.id);
                    } else {
                      await SupabaseConfig.client.from('suppliers').insert(data);
                    }

                    ref.invalidate(suppliersProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Update Supplier' : 'Save Supplier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSupplier(BuildContext context, WidgetRef ref, Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Supplier', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${supplier.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.midText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseConfig.client.from('suppliers').delete().eq('id', supplier.id);
      ref.invalidate(suppliersProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final isManager = ref.watch(profileProvider).value?.isManager == true;

    return Scaffold(
      floatingActionButton: isManager
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showAddSheet(context, ref),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(suppliersProvider),
        child: suppliersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (suppliers) {
            if (suppliers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No suppliers added', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final s = suppliers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(s.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                            if (isManager)
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.midText),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditSheet(context, ref, s);
                                  } else if (value == 'delete') {
                                    _deleteSupplier(context, ref, s);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit, size: 18, color: AppColors.midText),
                                        const SizedBox(width: 8),
                                        Text('Edit', style: GoogleFonts.inter()),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete, size: 18, color: AppColors.error),
                                        const SizedBox(width: 8),
                                        Text('Delete', style: GoogleFonts.inter(color: AppColors.error)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (s.contactName != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.person, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(s.contactName!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ]),
                        ],
                        if (s.phone != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(s.phone!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ]),
                        ],
                        if (s.goodsSupplied != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.inventory, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text(s.goodsSupplied!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                          ]),
                        ],
                        if (s.deliveryDays.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: s.deliveryDays.map((d) => Chip(
                              label: Text(d, style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
