import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase.dart';
import 'auth_provider.dart';

class DashboardStats {
  final int totalChecklists;
  final int todayCompletions;
  final int totalRecipes;
  final int openIncidents;
  final int teamMembers;
  final int unreadNotifications;
  final bool openingDone;
  final bool closingDone;
  final bool diarySigned;

  DashboardStats({
    this.totalChecklists = 0,
    this.todayCompletions = 0,
    this.totalRecipes = 0,
    this.openIncidents = 0,
    this.teamMembers = 0,
    this.unreadNotifications = 0,
    this.openingDone = false,
    this.closingDone = false,
    this.diarySigned = false,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final user = ref.watch(currentUserProvider);
  if (profile == null || user == null) return DashboardStats();

  final businessId = profile.businessId;
  final today = DateTime.now().toIso8601String().split('T')[0];
  final db = SupabaseConfig.client;

  // Run queries in parallel
  final checklistsFuture = db.from('checklist_templates').select('id').eq('business_id', businessId).eq('active', true);
  final completionsFuture = db.from('checklist_completions').select('id').eq('business_id', businessId).gte('completed_at', today);
  final recipesFuture = db.from('recipes').select('id').eq('business_id', businessId).eq('active', true);
  final incidentsFuture = db.from('incidents').select('id').eq('business_id', businessId);
  final teamFuture = db.from('profiles').select('id').eq('business_id', businessId);
  final notifFuture = db.from('notifications').select('id').eq('user_id', user.id).eq('read', false);
  final diaryFuture = db.from('diary_entries').select('opening_done, closing_done').eq('business_id', businessId).eq('date', today).maybeSingle();

  final results = await Future.wait<dynamic>([
    checklistsFuture,
    completionsFuture,
    recipesFuture,
    incidentsFuture,
    teamFuture,
    notifFuture,
    diaryFuture,
  ]);

  final diary = results[6] as Map<String, dynamic>?;

  return DashboardStats(
    totalChecklists: (results[0] as List).length,
    todayCompletions: (results[1] as List).length,
    totalRecipes: (results[2] as List).length,
    openIncidents: (results[3] as List).length,
    teamMembers: (results[4] as List).length,
    unreadNotifications: (results[5] as List).length,
    openingDone: diary?['opening_done'] == true,
    closingDone: diary?['closing_done'] == true,
    diarySigned: diary != null,
  );
});
