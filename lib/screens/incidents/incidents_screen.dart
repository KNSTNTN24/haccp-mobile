import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';

final incidentsProvider = FutureProvider<List<Incident>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('incidents')
      .select('*, profiles:reported_by(full_name), resolver:profiles!resolved_by(full_name)')
      .eq('business_id', profile.businessId)
      .order('created_at', ascending: false);

  return (response as List).map((e) => Incident.fromJson(e)).toList();
});

class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  String _filter = 'all'; // 'all', 'open', 'resolved'

  List<Incident> _applyFilter(List<Incident> incidents) {
    if (_filter == 'open') return incidents.where((i) => !i.isResolved).toList();
    if (_filter == 'resolved') return incidents.where((i) => i.isResolved).toList();
    return incidents;
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy h:mm a').format(dt);
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  void _showAddDialog() {
    String selectedType = 'incident';
    final descController = TextEditingController();
    final actionController = TextEditingController();
    final followUpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Report Incident', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'incident', child: Text('Incident')),
                        DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                      ],
                      onChanged: (v) {
                        setSheetState(() => selectedType = v ?? 'incident');
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: actionController,
                      decoration: const InputDecoration(labelText: 'Action Taken'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: followUpController,
                      decoration: const InputDecoration(labelText: 'Follow-up Required (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final profile = ref.read(profileProvider).value;
                          if (profile == null || descController.text.isEmpty) return;

                          await SupabaseConfig.client.from('incidents').insert({
                            'type': selectedType,
                            'description': descController.text,
                            'action_taken': actionController.text.isNotEmpty ? actionController.text : null,
                            'follow_up': followUpController.text.isNotEmpty ? followUpController.text : null,
                            'reported_by': profile.id,
                            'business_id': profile.businessId,
                          });

                          ref.invalidate(incidentsProvider);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(Incident incident) {
    String selectedType = incident.type;
    final descController = TextEditingController(text: incident.description);
    final actionController = TextEditingController(text: incident.actionTaken ?? '');
    final followUpController = TextEditingController(text: incident.followUp ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Incident', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'incident', child: Text('Incident')),
                        DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                      ],
                      onChanged: (v) {
                        setSheetState(() => selectedType = v ?? 'incident');
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: actionController,
                      decoration: const InputDecoration(labelText: 'Action Taken'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: followUpController,
                      decoration: const InputDecoration(labelText: 'Follow-up Required (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (descController.text.isEmpty) return;

                          await SupabaseConfig.client
                              .from('incidents')
                              .update({
                                'type': selectedType,
                                'description': descController.text,
                                'action_taken': actionController.text.isNotEmpty ? actionController.text : null,
                                'follow_up': followUpController.text.isNotEmpty ? followUpController.text : null,
                                'updated_at': DateTime.now().toUtc().toIso8601String(),
                              })
                              .eq('id', incident.id);

                          ref.invalidate(incidentsProvider);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResolveDialog(Incident incident) {
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resolve Incident', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  incident.description,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Resolution Notes',
                    hintText: 'Describe how this was resolved...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (notesController.text.isEmpty) return;

                      final profile = ref.read(profileProvider).value;
                      if (profile == null) return;

                      await SupabaseConfig.client
                          .from('incidents')
                          .update({
                            'status': 'resolved',
                            'resolved_by': profile.id,
                            'resolved_at': DateTime.now().toUtc().toIso8601String(),
                            'resolved_notes': notesController.text,
                            'updated_at': DateTime.now().toUtc().toIso8601String(),
                          })
                          .eq('id', incident.id);

                      ref.invalidate(incidentsProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Resolve'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reopenIncident(Incident incident) async {
    await SupabaseConfig.client
        .from('incidents')
        .update({
          'status': 'open',
          'resolved_by': null,
          'resolved_at': null,
          'resolved_notes': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', incident.id);

    ref.invalidate(incidentsProvider);
  }

  Future<void> _deleteIncident(Incident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Incident', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to delete this incident? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseConfig.client.from('incidents').delete().eq('id', incident.id);
      ref.invalidate(incidentsProvider);
    }
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Open', 'open'),
          const SizedBox(width: 8),
          _buildFilterChip('Resolved', 'resolved'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.midText)),
      ),
    );
  }

  Widget _buildIncidentCard(Incident incident, bool isManager) {
    final isIncident = incident.type == 'incident';
    final isOpen = !incident.isResolved;
    final statusColor = isOpen ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final statusLabel = isOpen ? 'Open' : 'Resolved';
    final statusIcon = isOpen ? Icons.error_rounded : Icons.check_circle_rounded;

    return GestureDetector(
      onTap: isManager ? () {
        if (isOpen) _showResolveDialog(incident);
        else _showEditDialog(incident);
      } : null,
      onLongPress: isManager ? () => _showActionsSheet(incident) : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE9E3)),
          // no shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Status badge + type + date + chevron
            Row(
              children: [
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 15, color: statusColor),
                    const SizedBox(width: 5),
                    Text(statusLabel, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor)),
                  ]),
                ),
                const SizedBox(width: 10),
                // Type pill
                Text(
                  isIncident ? 'Incident' : 'Complaint',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midText),
                ),
                const Spacer(),
                Text(_formatDate(incident.date), style: GoogleFonts.inter(fontSize: 14, color: AppColors.lightText)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.lightText),
              ],
            ),
            // Row 2: Description
            const SizedBox(height: 14),
            Text(incident.description,
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E), height: 1.3),
              maxLines: 3, overflow: TextOverflow.ellipsis,
            ),
            // Action taken
            if (incident.actionTaken != null && incident.actionTaken!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Action: ${incident.actionTaken!}',
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.midText, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            // Follow-up
            if (incident.followUp != null && incident.followUp!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.flag_rounded, size: 18, color: const Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(incident.followUp!,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFFEA580C), height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],
            // Resolution block
            if (incident.isResolved) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.verified_rounded, size: 18, color: const Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Resolved by ${incident.resolvedByName ?? 'Unknown'}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF059669)))),
                  ]),
                  if (incident.resolvedNotes != null && incident.resolvedNotes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(incident.resolvedNotes!, style: GoogleFonts.inter(fontSize: 15, color: AppColors.darkText, height: 1.3)),
                  ],
                ]),
              ),
            ],
            // Footer: reporter
            const SizedBox(height: 12),
            Text('Reported by ${incident.reportedByName ?? 'Unknown'}',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.lightText)),
          ],
        ),
      ),
    );
  }

  void _showActionsSheet(Incident incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _actionItem(Icons.edit_rounded, 'Edit', AppColors.midText, () { Navigator.pop(ctx); _showEditDialog(incident); }),
            if (!incident.isResolved)
              _actionItem(Icons.check_circle_rounded, 'Resolve', const Color(0xFF059669), () { Navigator.pop(ctx); _showResolveDialog(incident); }),
            if (incident.isResolved)
              _actionItem(Icons.refresh_rounded, 'Reopen', const Color(0xFF2563EB), () { Navigator.pop(ctx); _reopenIncident(incident); }),
            _actionItem(Icons.delete_rounded, 'Delete', const Color(0xFFDC2626), () { Navigator.pop(ctx); _deleteIncident(incident); }),
            const SizedBox(height: 8),
          ]),
        )),
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: color == AppColors.midText ? AppColors.darkText : color)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsProvider);
    final profile = ref.watch(profileProvider).value;
    final isManager = profile?.isManager ?? false;

    return Scaffold(
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(incidentsProvider),
              child: incidentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (incidents) {
                  final filtered = _applyFilter(incidents);

                  if (filtered.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _filter == 'all'
                                    ? 'No incidents reported'
                                    : _filter == 'open'
                                        ? 'No open incidents'
                                        : 'No resolved incidents',
                                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildIncidentCard(filtered[index], isManager);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF065F46), Color(0xFF047857)]),
          boxShadow: [BoxShadow(color: const Color(0xFF047857).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: _showAddDialog,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
