import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase.dart';
import '../models/profile.dart';
import '../models/business.dart';

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

  Future<bool> setupBusiness({
    required String businessName,
    required String fullName,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Create business
      final businessResponse = await SupabaseConfig.client
          .from('businesses')
          .insert({
            'name': businessName,
            'address': address,
          })
          .select()
          .single();

      final businessId = businessResponse['id'] as String;

      // Create profile
      await SupabaseConfig.client.from('profiles').insert({
        'id': user.id,
        'email': user.email!,
        'full_name': fullName,
        'role': 'owner',
        'business_id': businessId,
      });

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> joinWithInvite({
    required String token,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Get invite
      final invite = await SupabaseConfig.client
          .from('invites')
          .select()
          .eq('token', token)
          .isFilter('used_at', null)
          .single();

      // Create profile
      await SupabaseConfig.client.from('profiles').insert({
        'id': user.id,
        'email': user.email!,
        'full_name': fullName,
        'role': invite['role'],
        'business_id': invite['business_id'],
      });

      // Mark invite as used
      await SupabaseConfig.client
          .from('invites')
          .update({'used_at': DateTime.now().toIso8601String()})
          .eq('id', invite['id']);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);
