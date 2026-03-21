import '../config/supabase.dart';

/// Centralized notification helper.
/// Inserts into the `notifications` table for target users.
class NotificationHelper {
  static final _db = SupabaseConfig.client;

  /// Send a notification to a specific user.
  static Future<void> notify({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? link,
  }) async {
    await _db.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'link': link,
    });
  }

  /// Send a notification to all managers/owners of a business.
  static Future<void> notifyManagers({
    required String businessId,
    required String type,
    required String title,
    required String message,
    String? link,
    String? excludeUserId,
  }) async {
    final managers = await _db
        .from('profiles')
        .select('id')
        .eq('business_id', businessId)
        .inFilter('role', ['owner', 'manager']);

    for (final m in managers as List) {
      final id = m['id'] as String;
      if (id == excludeUserId) continue;
      await notify(
        userId: id,
        type: type,
        title: title,
        message: message,
        link: link,
      );
    }
  }

  /// Send a notification to all users with a specific role in a business.
  static Future<void> notifyRole({
    required String businessId,
    required String role,
    required String type,
    required String title,
    required String message,
    String? link,
    String? excludeUserId,
  }) async {
    final users = await _db
        .from('profiles')
        .select('id')
        .eq('business_id', businessId)
        .eq('role', role);

    for (final u in users as List) {
      final id = u['id'] as String;
      if (id == excludeUserId) continue;
      await notify(
        userId: id,
        type: type,
        title: title,
        message: message,
        link: link,
      );
    }
  }

  /// Send notification to multiple roles.
  static Future<void> notifyRoles({
    required String businessId,
    required List<String> roles,
    required String type,
    required String title,
    required String message,
    String? link,
    String? excludeUserId,
  }) async {
    final users = await _db
        .from('profiles')
        .select('id')
        .eq('business_id', businessId)
        .inFilter('role', roles);

    final seen = <String>{};
    for (final u in users as List) {
      final id = u['id'] as String;
      if (id == excludeUserId || seen.contains(id)) continue;
      seen.add(id);
      await notify(
        userId: id,
        type: type,
        title: title,
        message: message,
        link: link,
      );
    }
  }

  // ─── Event-specific helpers ────────────────────────

  /// 1. Staff checked in → notify managers
  static Future<void> onCheckIn({
    required String businessId,
    required String staffName,
    required String staffUserId,
  }) async {
    await notifyManagers(
      businessId: businessId,
      type: 'checkin',
      title: 'Staff Checked In',
      message: '$staffName has checked in',
      excludeUserId: staffUserId,
    );
  }

  /// 2. Staff checked out → notify managers
  static Future<void> onCheckOut({
    required String businessId,
    required String staffName,
    required String staffUserId,
  }) async {
    await notifyManagers(
      businessId: businessId,
      type: 'checkin',
      title: 'Staff Checked Out',
      message: '$staffName has checked out',
      excludeUserId: staffUserId,
    );
  }

  /// 3. New incident → notify managers/owner
  static Future<void> onNewIncident({
    required String businessId,
    required String description,
    required String reporterUserId,
  }) async {
    final short = description.length > 60
        ? '${description.substring(0, 60)}...'
        : description;
    await notifyManagers(
      businessId: businessId,
      type: 'incident',
      title: 'New Incident Reported',
      message: short,
      link: '/incidents',
      excludeUserId: reporterUserId,
    );
  }

  /// 4. Incident resolved → notify the original author
  static Future<void> onIncidentResolved({
    required String authorUserId,
    required String description,
  }) async {
    final short = description.length > 60
        ? '${description.substring(0, 60)}...'
        : description;
    await notify(
      userId: authorUserId,
      type: 'incident',
      title: 'Incident Resolved',
      message: short,
      link: '/incidents',
    );
  }

  /// 5. Overdue checklist → notify assigned roles + managers
  static Future<void> onOverdueChecklist({
    required String businessId,
    required String checklistName,
    required List<String> assignedRoles,
  }) async {
    final roles = {...assignedRoles, 'owner', 'manager'}.toList();
    await notifyRoles(
      businessId: businessId,
      roles: roles,
      type: 'checklist',
      title: 'Overdue Checklist',
      message: '$checklistName is past its deadline',
      link: '/checklists',
    );
  }

  /// 6. Flagged item → notify managers
  static Future<void> onFlaggedItem({
    required String businessId,
    required String checklistName,
    required String itemName,
    required String reporterUserId,
  }) async {
    await notifyManagers(
      businessId: businessId,
      type: 'checklist',
      title: 'Flagged Item',
      message: '$itemName in $checklistName is out of range',
      link: '/checklists',
      excludeUserId: reporterUserId,
    );
  }

  /// 7. Sign-off required → notify supervisor role
  static Future<void> onSignOffRequired({
    required String businessId,
    required String supervisorRole,
    required String checklistName,
    required String completedByName,
  }) async {
    await notifyRole(
      businessId: businessId,
      role: supervisorRole,
      type: 'checklist',
      title: 'Sign-off Required',
      message: '$completedByName completed $checklistName',
      link: '/checklists',
    );
  }

  /// 8. Expiring document → notify owner/manager
  static Future<void> onExpiringDocument({
    required String businessId,
    required String documentName,
    required int daysLeft,
  }) async {
    final urgency = daysLeft <= 1
        ? 'expires tomorrow'
        : daysLeft <= 7
            ? 'expires in $daysLeft days'
            : 'expires in $daysLeft days';
    await notifyManagers(
      businessId: businessId,
      type: 'document',
      title: 'Expiring Document',
      message: '$documentName $urgency',
      link: '/documents',
    );
  }

  /// 9. New member joined → notify owner/manager
  static Future<void> onNewMemberJoined({
    required String businessId,
    required String memberName,
    required String memberUserId,
  }) async {
    await notifyManagers(
      businessId: businessId,
      type: 'team',
      title: 'New Team Member',
      message: '$memberName has joined the team',
      link: '/team',
      excludeUserId: memberUserId,
    );
  }
}
