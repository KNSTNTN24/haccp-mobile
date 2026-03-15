import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/checklist.dart';
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

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(checklistsProvider),
      child: checklistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (checklists) {
          // Filter by role
          final filtered = checklists.where((c) {
            if (c.assignedRoles.isEmpty) return true;
            return c.assignedRoles.contains(profile?.role.name ?? '');
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No checklists available',
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final checklist = filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.checklist, color: AppColors.blue600),
                  ),
                  title: Text(
                    checklist.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (checklist.description != null)
                        Text(checklist.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              checklist.frequency.displayName,
                              style: TextStyle(fontSize: 11, color: AppColors.gold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${checklist.items?.length ?? 0} items',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/checklists/${checklist.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
