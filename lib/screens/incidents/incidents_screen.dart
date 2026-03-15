import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';

final incidentsProvider = FutureProvider<List<Incident>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('incidents')
      .select('*, profiles:reported_by(full_name)')
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
  void _showAddDialog() {
    final typeController = TextEditingController(text: 'incident');
    final descController = TextEditingController();
    final actionController = TextEditingController();

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
                Text('Report Incident', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: typeController.text,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'incident', child: Text('Incident')),
                    DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                  ],
                  onChanged: (v) => typeController.text = v ?? 'incident',
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final profile = ref.read(profileProvider).value;
                      if (profile == null || descController.text.isEmpty) return;

                      await SupabaseConfig.client.from('incidents').insert({
                        'type': typeController.text,
                        'description': descController.text,
                        'action_taken': actionController.text.isNotEmpty ? actionController.text : null,
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
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(incidentsProvider),
        child: incidentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (incidents) {
            if (incidents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No incidents reported', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                final isIncident = incident.type == 'incident';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
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
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isIncident ? AppColors.red600 : AppColors.yellow600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(incident.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(incident.description, style: const TextStyle(fontSize: 14)),
                        if (incident.actionTaken != null) ...[
                          const SizedBox(height: 6),
                          Text('Action: ${incident.actionTaken}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                        if (incident.reportedByName != null) ...[
                          const SizedBox(height: 6),
                          Text('by ${incident.reportedByName}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
