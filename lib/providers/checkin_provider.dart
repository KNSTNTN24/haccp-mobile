import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/supabase.dart';
import '../models/checkin.dart';
import 'auth_provider.dart';

/// All check-ins for today for the current user's business.
final todayCheckinsProvider = FutureProvider<List<StaffCheckin>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final data = await SupabaseConfig.client
      .from('staff_checkins')
      .select('*, profiles:user_id(full_name, avatar_url, role)')
      .eq('business_id', profile.businessId)
      .eq('date', today)
      .order('checked_in_at');

  return (data as List)
      .map((e) => StaffCheckin.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Current user's active check-in (checked in but not out).
final myActiveCheckinProvider = Provider<StaffCheckin?>((ref) {
  final checkins = ref.watch(todayCheckinsProvider).value ?? [];
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    return checkins.firstWhere(
      (c) => c.userId == user.id && c.isCheckedIn,
    );
  } catch (_) {
    return null;
  }
});

/// On-site staff (checked in but not checked out).
final onSiteStaffProvider = Provider<List<StaffCheckin>>((ref) {
  final checkins = ref.watch(todayCheckinsProvider).value ?? [];
  return checkins.where((c) => c.isCheckedIn).toList();
});

/// Check in the current user.
Future<void> checkIn(WidgetRef ref) async {
  final profile = await ref.read(profileProvider.future);
  final user = ref.read(currentUserProvider);
  if (profile == null || user == null) return;

  await SupabaseConfig.client.from('staff_checkins').insert({
    'user_id': user.id,
    'business_id': profile.businessId,
  });

  ref.invalidate(todayCheckinsProvider);
}

/// Check out the current user.
Future<void> checkOut(WidgetRef ref) async {
  final activeCheckin = ref.read(myActiveCheckinProvider);
  if (activeCheckin == null) return;

  await SupabaseConfig.client
      .from('staff_checkins')
      .update({'checked_out_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', activeCheckin.id);

  ref.invalidate(todayCheckinsProvider);
}
