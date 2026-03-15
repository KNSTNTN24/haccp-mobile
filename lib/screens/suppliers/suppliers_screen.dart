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
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final goodsCtrl = TextEditingController();
    final selectedDays = <String>[];

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
                Text('Add Supplier', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
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
                const Text('Delivery Days:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: _weekDays.map((d) {
                    final sel = selectedDays.contains(d);
                    return FilterChip(
                      label: Text(d, style: TextStyle(fontSize: 12, color: sel ? Colors.white : null)),
                      selected: sel,
                      selectedColor: AppColors.gold,
                      onSelected: (s) => setSheetState(() => s ? selectedDays.add(d) : selectedDays.remove(d)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final profile = ref.read(profileProvider).value;
                    if (profile == null) return;

                    await SupabaseConfig.client.from('suppliers').insert({
                      'name': nameCtrl.text.trim(),
                      'contact_name': contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                      'goods_supplied': goodsCtrl.text.trim().isEmpty ? null : goodsCtrl.text.trim(),
                      'delivery_days': selectedDays,
                      'business_id': profile.businessId,
                    });

                    ref.invalidate(suppliersProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Supplier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                    Text('No suppliers added', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
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
                        Text(s.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
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
