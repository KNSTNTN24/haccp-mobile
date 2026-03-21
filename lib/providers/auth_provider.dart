import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase.dart';
import '../models/profile.dart';
import '../models/business.dart';
import '../utils/notification_helper.dart';

// Current auth user
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseConfig.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

// Profile
final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await SupabaseConfig.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return null;
  return Profile.fromJson(response);
});

// Business
final businessProvider = FutureProvider<Business?>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;

  final response = await SupabaseConfig.client
      .from('businesses')
      .select()
      .eq('id', profile.businessId)
      .single();

  return Business.fromJson(response);
});

// Auth actions notifier using Notifier
class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } on AuthException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<void> signOut() async {
    await SupabaseConfig.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<(bool, String?)> setupBusiness({
    required String businessName,
    required String fullName,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Use RPC function (SECURITY DEFINER) to bypass RLS for setup
      await SupabaseConfig.client.rpc('setup_business', params: {
        'business_name': businessName,
        'owner_name': fullName,
        'business_address': address,
      });

      state = const AsyncValue.data(null);
      return (true, null);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return (false, e.toString());
    }
  }

  Future<(bool, String?)> joinWithInvite({
    required String token,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Use RPC function (SECURITY DEFINER) to bypass RLS for join
      await SupabaseConfig.client.rpc('join_with_invite', params: {
        'invite_token': token,
        'member_name': fullName,
      });

      // Notify managers about new member
      // Reload profile to get businessId
      final profileData = await SupabaseConfig.client
          .from('profiles')
          .select('business_id')
          .eq('id', user.id)
          .single();
      final bizId = profileData['business_id'] as String?;
      if (bizId != null) {
        NotificationHelper.onNewMemberJoined(
          businessId: bizId,
          memberName: fullName,
          memberUserId: user.id,
        );
      }

      state = const AsyncValue.data(null);
      return (true, null);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return (false, e.toString());
    }
  }
  Future<(bool, String?)> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await SupabaseConfig.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      state = const AsyncValue.data(null);
      return (true, null);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return (false, e.toString());
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);
