import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase.dart';
import '../models/delivery.dart';
import 'auth_provider.dart';

final deliveriesProvider = FutureProvider<List<Delivery>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('deliveries')
      .select('*, suppliers(name), profiles(full_name), delivery_photos(*)')
      .eq('business_id', profile.businessId)
      .order('received_at', ascending: false);

  return (response as List)
      .map((e) => Delivery.fromJson(e as Map<String, dynamic>))
      .toList();
});
