import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';

final teamProvider = FutureProvider<List<Profile>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('profiles')
      .select()
      .eq('business_id', profile.businessId)
      .order('full_name');

  return (response as List).map((e) => Profile.fromJson(e)).toList();
});

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(teamProvider),
      child: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No team members'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final m = members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.darkBlue,
                    child: Text(
                      (m.fullName ?? m.email).substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  title: Text(m.fullName ?? m.email, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  subtitle: Text(m.email, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      m.role.displayName,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
