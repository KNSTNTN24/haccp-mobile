import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/supabase.dart';
import '../../models/document.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/documents_provider.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _downloading = false;

  Future<void> _openDocument(Document doc) async {
    setState(() => _downloading = true);
    final url = await ref.read(documentsNotifierProvider.notifier).getSignedUrl(doc.fileUrl);
    setState(() => _downloading = false);

    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteDocument(Document doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(documentsNotifierProvider.notifier).deleteDocument(doc.id);
      if (success && mounted) {
        ref.invalidate(documentsProvider(null));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Document deleted'), backgroundColor: AppColors.primary),
        );
        context.go('/documents');
      }
    }
  }

  Future<void> _showAccessDialog(Document doc) async {
    final profile = ref.read(profileProvider).value;
    if (profile == null || profile.role != UserRole.owner) return;

    AccessLevel newLevel = doc.accessLevel;
    Set<String> selectedIds = {};

    // Load current access list
    final accessList = await ref.read(documentAccessListProvider(doc.id).future);
    selectedIds = accessList.map((a) => a.profileId).toSet();

    // Load team members
    final teamData = await SupabaseConfig.client
        .from('profiles')
        .select('id, full_name, email, role')
        .eq('business_id', profile.businessId)
        .neq('id', SupabaseConfig.auth.currentUser!.id)
        .order('full_name');
    final teamMembers = List<Map<String, dynamic>>.from(teamData);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Manage Access', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...AccessLevel.values.map((level) => RadioListTile<AccessLevel>(
                  value: level,
                  groupValue: newLevel,
                  onChanged: (v) => setDialogState(() => newLevel = v!),
                  title: Text(level.label, style: GoogleFonts.inter(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
                if (newLevel == AccessLevel.custom) ...[
                  const Divider(),
                  Text('Select members:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  ...teamMembers.map((m) => CheckboxListTile(
                    value: selectedIds.contains(m['id']),
                    onChanged: (v) {
                      setDialogState(() {
                        if (v == true) {
                          selectedIds.add(m['id']);
                        } else {
                          selectedIds.remove(m['id']);
                        }
                      });
                    },
                    title: Text(m['full_name'] ?? m['email'] ?? '', style: GoogleFonts.inter(fontSize: 14)),
                    subtitle: Text(m['role'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.midText)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref.read(documentsNotifierProvider.notifier).updateAccessLevel(
                  documentId: doc.id,
                  accessLevel: newLevel.toDbValue(),
                  allowedProfileIds: newLevel == AccessLevel.custom ? selectedIds.toList() : null,
                );
                if (success) {
                  ref.invalidate(documentDetailProvider(doc.id));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Access updated'), backgroundColor: AppColors.primary),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(documentDetailProvider(widget.documentId));
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final isOwner = profile?.role == UserRole.owner;
    final dateFormat = DateFormat('d MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Document', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/documents'),
        ),
        actions: docAsync.when(
          data: (doc) => [
            if (isOwner)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'access') _showAccessDialog(doc);
                  if (v == 'delete') _deleteDocument(doc);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'access', child: ListTile(leading: Icon(Icons.security), title: Text('Manage Access'), dense: true, contentPadding: EdgeInsets.zero)),
                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppColors.error), title: Text('Delete', style: TextStyle(color: AppColors.error)), dense: true, contentPadding: EdgeInsets.zero)),
                ],
              ),
          ],
          loading: () => [],
          error: (_, __) => [],
        ),
      ),
      body: docAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (doc) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // File preview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(doc.fileIcon, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    doc.fileName,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText),
                    textAlign: TextAlign.center,
                  ),
                  if (doc.fileSizeFormatted.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(doc.fileSizeFormatted, style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightText)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: _downloading ? null : () => _openDocument(doc),
                      icon: _downloading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.open_in_new, size: 18),
                      label: Text(_downloading ? 'Loading...' : 'Open File'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              doc.title,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkText),
            ),
            const SizedBox(height: 8),

            // Category badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${doc.category.icon} ${doc.category.label}',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAccessColor(doc.accessLevel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getAccessIcon(doc.accessLevel), size: 14, color: _getAccessColor(doc.accessLevel)),
                      const SizedBox(width: 4),
                      Text(
                        doc.accessLevel.label,
                        style: GoogleFonts.inter(fontSize: 13, color: _getAccessColor(doc.accessLevel), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (doc.description != null && doc.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(doc.description!, style: GoogleFonts.inter(fontSize: 15, color: AppColors.midText, height: 1.5)),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Metadata
            _buildInfoRow(Icons.person_outline, 'Uploaded by', doc.uploaderName ?? 'Unknown'),
            _buildInfoRow(Icons.calendar_today, 'Uploaded', dateFormat.format(doc.createdAt)),
            if (doc.expiresAt != null) ...[
              _buildInfoRow(
                doc.isExpired ? Icons.error : (doc.isExpiringSoon ? Icons.warning : Icons.event),
                'Expires',
                dateFormat.format(doc.expiresAt!),
                valueColor: doc.isExpired ? AppColors.error : (doc.isExpiringSoon ? AppColors.warning : null),
              ),
            ],

            // Access list for custom
            if (doc.accessLevel == AccessLevel.custom && isOwner) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text('Access List', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText)),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final accessAsync = ref.watch(documentAccessListProvider(doc.id));
                  return accessAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (list) {
                      if (list.isEmpty) {
                        return Text('No custom access granted', style: GoogleFonts.inter(color: AppColors.midText));
                      }
                      return Column(
                        children: list.map((a) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryPale,
                            child: Icon(Icons.person, color: AppColors.primary, size: 20),
                          ),
                          title: Text(a.profileName ?? a.profileEmail ?? 'Unknown'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        )).toList(),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.midText),
          const SizedBox(width: 10),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? AppColors.darkText),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccessIcon(AccessLevel level) {
    switch (level) {
      case AccessLevel.all: return Icons.public;
      case AccessLevel.managersOnly: return Icons.admin_panel_settings;
      case AccessLevel.ownerOnly: return Icons.lock;
      case AccessLevel.custom: return Icons.people;
    }
  }

  Color _getAccessColor(AccessLevel level) {
    switch (level) {
      case AccessLevel.all: return AppColors.primary;
      case AccessLevel.managersOnly: return AppColors.blue600;
      case AccessLevel.ownerOnly: return AppColors.orange600;
      case AccessLevel.custom: return AppColors.purple600;
    }
  }
}
