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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.midText,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Incident incident) {
    final isOpen = !incident.isResolved;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.red50 : AppColors.green50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'Open' : 'Resolved',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen ? AppColors.red600 : AppColors.green600,
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Incident incident, bool isManager) {
    final isIncident = incident.type == 'incident';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: !incident.isResolved && isManager ? () => _showResolveDialog(incident) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isIncident ? AppColors.red50 : AppColors.yellow50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isIncident ? 'Incident' : 'Complaint',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isIncident ? AppColors.red600 : AppColors.yellow600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(incident),
                  const Spacer(),
                  if (isManager)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20, color: AppColors.midText),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditDialog(incident);
                            break;
                          case 'delete':
                            _deleteIncident(incident);
                            break;
                          case 'resolve':
                            _showResolveDialog(incident);
                            break;
                          case 'reopen':
                            _reopenIncident(incident);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (!incident.isResolved)
                          const PopupMenuItem(value: 'resolve', child: Text('Resolve')),
                        if (incident.isResolved)
                          const PopupMenuItem(value: 'reopen', child: Text('Reopen')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(incident.description, style: GoogleFonts.inter(fontSize: 14)),
              if (incident.actionTaken != null && incident.actionTaken!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Action: ${incident.actionTaken}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText),
                ),
              ],
              if (incident.followUp != null && incident.followUp!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag_outlined, size: 14, color: AppColors.orange600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Follow-up: ${incident.followUp}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.orange600),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 20),
              // Timestamps and reporter
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: AppColors.lightText),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reported by ${incident.reportedByName ?? 'Unknown'}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.lightText),
                  const SizedBox(width: 4),
                  Text(
                    'Reported: ${_formatDate(incident.date)} at ${DateFormat('h:mm a').format(incident.createdAt)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightText),
                  ),
                ],
              ),
              // Resolution info
              if (incident.isResolved) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: AppColors.green600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Resolved by ${incident.resolvedByName ?? 'Unknown'}${incident.resolvedAt != null ? ' on ${_formatDateTime(incident.resolvedAt!)}' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.green600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (incident.resolvedNotes != null && incident.resolvedNotes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          incident.resolvedNotes!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkText),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
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
                    padding: const EdgeInsets.all(16),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
