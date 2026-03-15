import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _showInviteSheet(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    var selectedRole = UserRole.kitchen_staff;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Invite Team Member', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address *', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: UserRole.values
                    .where((r) => r != UserRole.owner)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName)))
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedRole = v!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.white),
                onPressed: () async {
                  if (emailCtrl.text.trim().isEmpty) return;
                  final profile = ref.read(profileProvider).value;
                  if (profile == null) return;

                  try {
                    final token = DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
                        UniqueKey().toString().substring(2, 8);

                    await SupabaseConfig.client.from('invites').insert({
                      'business_id': profile.businessId,
                      'email': emailCtrl.text.trim().toLowerCase(),
                      'role': selectedRole.name,
                      'token': token,
                      'invited_by': SupabaseConfig.auth.currentUser!.id,
                    });

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Invite Created!'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Send this to ${emailCtrl.text.trim()}:', style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SelectableText(token, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Instructions for the new member:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    SizedBox(height: 6),
                                    Text('1. Open the app or website', style: TextStyle(fontSize: 12)),
                                    Text('2. Tap "Create Account" and register', style: TextStyle(fontSize: 12)),
                                    Text('3. On setup screen choose "Join Team"', style: TextStyle(fontSize: 12)),
                                    Text('4. Paste the invite token above', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: token));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Token copied!'), backgroundColor: Colors.green),
                                );
                                Navigator.pop(dCtx);
                              },
                              child: const Text('Copy Token'),
                            ),
                            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Create Invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);
    final currentProfile = ref.watch(profileProvider).value;
    final isManager = currentProfile?.role == UserRole.owner || currentProfile?.role == UserRole.manager;

    return Scaffold(
      floatingActionButton: isManager
          ? FloatingActionButton(
              backgroundColor: AppColors.gold,
              onPressed: () => _showInviteSheet(context, ref),
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
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
      ),
    );
  }
}
