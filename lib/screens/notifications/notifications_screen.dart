import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/notification.dart';
import '../../providers/auth_provider.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final response = await SupabaseConfig.client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(50);

  return (response as List).map((e) => AppNotification.fromJson(e)).toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(notificationsProvider),
      child: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No notifications', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: n.read ? AppColors.white : AppColors.blue50,
                child: ListTile(
                  leading: Icon(
                    _iconForType(n.type),
                    color: n.read ? Colors.grey : AppColors.blue600,
                  ),
                  title: Text(n.title, style: GoogleFonts.outfit(
                    fontWeight: n.read ? FontWeight.normal : FontWeight.w600,
                    fontSize: 14,
                  )),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(n.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (!n.read) {
                      await SupabaseConfig.client
                          .from('notifications')
                          .update({'read': true})
                          .eq('id', n.id);
                      ref.invalidate(notificationsProvider);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'checklist': return Icons.checklist;
      case 'incident': return Icons.warning_amber;
      case 'team': return Icons.people;
      default: return Icons.info;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(date);
  }
}
