import 'package:intl/intl.dart';
import '../config/supabase.dart';
import 'notification_helper.dart';

/// Runs on app open to check for overdue checklists and expiring documents.
/// Uses a simple local-time-based flag to avoid duplicate notifications in the same day.
class StartupChecks {
  static String? _lastCheckDate;

  static Future<void> run({
    required String businessId,
    required String userId,
    required String userRole,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_lastCheckDate == today) return; // Already checked today
    _lastCheckDate = today;

    await Future.wait([
      _checkOverdueChecklists(businessId: businessId),
      _checkExpiringDocuments(businessId: businessId),
    ]);
  }

  /// Check for checklists that have a deadline_time in the past today and are not yet completed.
  static Future<void> _checkOverdueChecklists({
    required String businessId,
  }) async {
    try {
      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Get templates with deadline_time set
      final templates = await SupabaseConfig.client
          .from('checklist_templates')
          .select('id, name, deadline_time, assigned_roles, frequency')
          .eq('business_id', businessId)
          .eq('active', true)
          .not('deadline_time', 'is', null);

      for (final t in templates as List) {
        final deadline = t['deadline_time'] as String?;
        if (deadline == null || deadline.compareTo(currentTime) > 0) continue;

        // Check if completed today
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        final completions = await SupabaseConfig.client
            .from('checklist_completions')
            .select('id')
            .eq('template_id', t['id'])
            .gte('completed_at', '${todayStr}T00:00:00')
            .limit(1);

        if ((completions as List).isEmpty) {
          final roles = List<String>.from(t['assigned_roles'] ?? []);
          await NotificationHelper.onOverdueChecklist(
            businessId: businessId,
            checklistName: t['name'] as String,
            assignedRoles: roles,
          );
        }
      }
    } catch (_) {
      // Silently fail — startup checks should not block the app
    }
  }

  /// Check for documents expiring within 30, 7, or 1 day(s).
  static Future<void> _checkExpiringDocuments({
    required String businessId,
  }) async {
    try {
      final now = DateTime.now();
      final in30days = now.add(const Duration(days: 30));
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final in30Str = DateFormat('yyyy-MM-dd').format(in30days);

      final docs = await SupabaseConfig.client
          .from('documents')
          .select('id, title, expires_at')
          .eq('business_id', businessId)
          .not('expires_at', 'is', null)
          .gte('expires_at', todayStr)
          .lte('expires_at', in30Str);

      for (final doc in docs as List) {
        final expiryStr = doc['expires_at'] as String;
        final expiry = DateTime.parse(expiryStr);
        final daysLeft = expiry.difference(now).inDays;

        // Only notify at 30, 7, and 1 day thresholds
        if (daysLeft == 30 || daysLeft == 7 || daysLeft <= 1) {
          await NotificationHelper.onExpiringDocument(
            businessId: businessId,
            documentName: doc['title'] as String,
            daysLeft: daysLeft,
          );
        }
      }
    } catch (_) {
      // Silently fail
    }
  }
}
