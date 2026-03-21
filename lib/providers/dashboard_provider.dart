import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase.dart';
import '../models/incident.dart';
import '../models/notification.dart';
import 'auth_provider.dart';

class TaskItem {
  final String templateId;
  final String templateName;
  final String frequency;
  final bool isCompleted;
  TaskItem({required this.templateId, required this.templateName, required this.frequency, required this.isCompleted});
}

class TeamMemberTasks {
  final String userId;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final int completed;
  final int total;
  TeamMemberTasks({required this.userId, required this.fullName, required this.role, this.avatarUrl, required this.completed, required this.total});
}

class DashboardData {
  final List<TaskItem> myTasks;
  final List<TeamMemberTasks> teamTasks;
  final List<Incident> openIncidents;
  final List<AppNotification> recentNotifications;

  DashboardData({
    this.myTasks = const [],
    this.teamTasks = const [],
    this.openIncidents = const [],
    this.recentNotifications = const [],
  });

  int get completedCount => myTasks.where((t) => t.isCompleted).length;
  int get totalCount => myTasks.length;
  double get progress => totalCount == 0 ? 1.0 : completedCount / totalCount;
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final user = ref.watch(currentUserProvider);
  if (profile == null || user == null) return DashboardData();

  final businessId = profile.businessId;
  final today = DateTime.now().toIso8601String().split('T')[0];
  final db = SupabaseConfig.client;

  final templatesFuture = db.from('checklist_templates')
      .select('id, name, frequency, assigned_roles')
      .eq('business_id', businessId)
      .eq('active', true);

  final completionsFuture = db.from('checklist_completions')
      .select('template_id, completed_by')
      .eq('business_id', businessId)
      .gte('completed_at', today);

  final incidentsFuture = db.from('incidents')
      .select('*, profiles:reported_by(full_name)')
      .eq('business_id', businessId)
      .eq('status', 'open')
      .order('created_at', ascending: false)
      .limit(5);

  final notifFuture = db.from('notifications')
      .select()
      .eq('user_id', user.id)
      .eq('read', false)
      .order('created_at', ascending: false)
      .limit(5);

  final isManager = profile.isManager;
  final teamFuture = isManager
      ? db.from('profiles').select('id, full_name, role, avatar_url').eq('business_id', businessId)
      : Future.value(<dynamic>[]);

  final results = await Future.wait<dynamic>([
    templatesFuture,
    completionsFuture,
    incidentsFuture,
    notifFuture,
    teamFuture,
  ]);

  final templates = results[0] as List;
  final completions = results[1] as List;
  final completedTemplateIds = completions.map((c) => c['template_id']).toSet();

  final myRole = profile.role.name;
  final myTasks = templates
      .where((t) {
        final roles = (t['assigned_roles'] as List?)?.cast<String>() ?? [];
        return roles.isEmpty || roles.contains(myRole);
      })
      .map((t) => TaskItem(
            templateId: t['id'] as String,
            templateName: t['name'] as String,
            frequency: t['frequency'] as String? ?? 'daily',
            isCompleted: completedTemplateIds.contains(t['id']),
          ))
      .toList();

  final openIncidents = (results[2] as List)
      .map((e) => Incident.fromJson(e as Map<String, dynamic>))
      .toList();

  final notifications = (results[3] as List)
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
      .toList();

  List<TeamMemberTasks> teamTasks = [];
  if (isManager) {
    final teamMembers = results[4] as List;
    for (final member in teamMembers) {
      final memberId = member['id'] as String;
      final memberRole = member['role'] as String;
      final assignedTemplates = templates.where((t) {
        final roles = (t['assigned_roles'] as List?)?.cast<String>() ?? [];
        return roles.isEmpty || roles.contains(memberRole);
      }).toList();
      final memberCompletedIds = completions
          .where((c) => c['completed_by'] == memberId)
          .map((c) => c['template_id'])
          .toSet();
      final assignedIds = assignedTemplates.map((t) => t['id']).toSet();
      teamTasks.add(TeamMemberTasks(
        userId: memberId,
        fullName: member['full_name'] as String? ?? 'Unknown',
        role: memberRole,
        avatarUrl: member['avatar_url'] as String?,
        completed: memberCompletedIds.intersection(assignedIds).length,
        total: assignedTemplates.length,
      ));
    }
  }

  return DashboardData(
    myTasks: myTasks,
    teamTasks: teamTasks,
    openIncidents: openIncidents,
    recentNotifications: notifications,
  );
});
