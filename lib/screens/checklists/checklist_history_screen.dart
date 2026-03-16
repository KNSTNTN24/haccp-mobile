import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/checklist.dart';

class CompletionHistoryData {
  final List<ChecklistCompletion> completions;
  final Map<String, ChecklistTemplateItem> itemMap;
  CompletionHistoryData({required this.completions, required this.itemMap});
}

final completionHistoryProvider =
    FutureProvider.family<CompletionHistoryData, String>((ref, templateId) async {
  final response = await SupabaseConfig.client
      .from('checklist_completions')
      .select('*, profiles:completed_by(full_name), checklist_responses(*)')
      .eq('template_id', templateId)
      .order('completed_at', ascending: false);

  final completions = (response as List)
      .map((e) => ChecklistCompletion.fromJson(e as Map<String, dynamic>))
      .toList();

  final itemsResponse = await SupabaseConfig.client
      .from('checklist_template_items')
      .select()
      .eq('template_id', templateId)
      .order('sort_order');

  final items = (itemsResponse as List)
      .map((e) => ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
      .toList();

  final itemMap = {for (final item in items) item.id: item};

  return CompletionHistoryData(completions: completions, itemMap: itemMap);
});

class ChecklistHistoryScreen extends ConsumerStatefulWidget {
  final String templateId;

  const ChecklistHistoryScreen({super.key, required this.templateId});

  @override
  ConsumerState<ChecklistHistoryScreen> createState() =>
      _ChecklistHistoryScreenState();
}

class _ChecklistHistoryScreenState
    extends ConsumerState<ChecklistHistoryScreen> {
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final historyAsync =
        ref.watch(completionHistoryProvider(widget.templateId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => context.go('/checklists/${widget.templateId}'),
        ),
        title: Text(
          'Completion History',
          style: GoogleFonts.inter(
            color: AppColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load history',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.midText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          if (data.completions.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.completions.length,
            itemBuilder: (context, index) => _buildCompletionCard(
              data.completions[index],
              data.itemMap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.lightText),
          const SizedBox(height: 16),
          Text(
            'No completions yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.midText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(
    ChecklistCompletion completion,
    Map<String, ChecklistTemplateItem> itemMap,
  ) {
    final isExpanded = _expandedIds.contains(completion.id);
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm').format(completion.completedAt);
    final completedBy = completion.completedByName ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(completion.id);
                } else {
                  _expandedIds.add(completion.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryPale,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          completedBy,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.midText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.midText,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: AppColors.divider),
            _buildResponseList(completion.responses ?? [], itemMap),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseList(
    List<ChecklistResponse> responses,
    Map<String, ChecklistTemplateItem> itemMap,
  ) {
    if (responses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No responses recorded',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.midText),
        ),
      );
    }

    final sorted = List<ChecklistResponse>.from(responses);
    sorted.sort((a, b) {
      final aOrder = itemMap[a.itemId]?.sortOrder ?? 0;
      final bOrder = itemMap[b.itemId]?.sortOrder ?? 0;
      return aOrder.compareTo(bOrder);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: sorted.map((r) => _buildResponseRow(r, itemMap)).toList(),
      ),
    );
  }

  Widget _buildResponseRow(
    ChecklistResponse response,
    Map<String, ChecklistTemplateItem> itemMap,
  ) {
    final item = itemMap[response.itemId];
    final itemName = item?.name ?? 'Unknown Item';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              itemName,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.midText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            response.value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: response.flagged ? AppColors.error : AppColors.darkText,
            ),
          ),
          if (response.flagged) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Flagged',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
