import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/diary_entry.dart';
import '../../providers/auth_provider.dart';

final diaryProvider = FutureProvider.family<DiaryEntry?, String>((ref, date) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;

  final response = await SupabaseConfig.client
      .from('diary_entries')
      .select('*, profiles:signed_by(full_name)')
      .eq('business_id', profile.businessId)
      .eq('date', date)
      .maybeSingle();

  if (response == null) return null;
  return DiaryEntry.fromJson(response);
});

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late String _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _toggleCheck(String field, bool currentValue) async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    setState(() => _isSaving = true);

    try {
      final existing = ref.read(diaryProvider(_selectedDate)).value;

      if (existing == null) {
        await SupabaseConfig.client.from('diary_entries').insert({
          'date': _selectedDate,
          'business_id': profile.businessId,
          field: !currentValue,
        });
      } else {
        await SupabaseConfig.client
            .from('diary_entries')
            .update({field: !currentValue})
            .eq('id', existing.id);
      }

      ref.invalidate(diaryProvider(_selectedDate));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signDiary() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    setState(() => _isSaving = true);

    try {
      final existing = ref.read(diaryProvider(_selectedDate)).value;

      if (existing == null) {
        await SupabaseConfig.client.from('diary_entries').insert({
          'date': _selectedDate,
          'business_id': profile.businessId,
          'signed_by': profile.id,
        });
      } else {
        await SupabaseConfig.client
            .from('diary_entries')
            .update({'signed_by': profile.id})
            .eq('id', existing.id);
      }

      ref.invalidate(diaryProvider(_selectedDate));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary signed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaryAsync = ref.watch(diaryProvider(_selectedDate));
    final dateObj = DateTime.parse(_selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateFormat('yyyy-MM-dd')
                            .format(dateObj.subtract(const Duration(days: 1)));
                      });
                    },
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(dateObj),
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: dateObj.isBefore(DateTime.now())
                        ? () {
                            setState(() {
                              _selectedDate = DateFormat('yyyy-MM-dd')
                                  .format(dateObj.add(const Duration(days: 1)));
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          diaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (diary) {
              final openingDone = diary?.openingDone ?? false;
              final closingDone = diary?.closingDone ?? false;
              final isSigned = diary?.signedBy != null;

              return Column(
                children: [
                  // Opening checks
                  Card(
                    child: ListTile(
                      leading: Icon(
                        openingDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: openingDone ? AppColors.green600 : Colors.grey,
                        size: 28,
                      ),
                      title: Text('Opening Checks', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      subtitle: Text(openingDone ? 'Completed' : 'Not done'),
                      trailing: Switch(
                        value: openingDone,
                        onChanged: _isSaving ? null : (_) => _toggleCheck('opening_done', openingDone),
                        activeThumbColor: AppColors.green600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Closing checks
                  Card(
                    child: ListTile(
                      leading: Icon(
                        closingDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: closingDone ? AppColors.green600 : Colors.grey,
                        size: 28,
                      ),
                      title: Text('Closing Checks', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      subtitle: Text(closingDone ? 'Completed' : 'Not done'),
                      trailing: Switch(
                        value: closingDone,
                        onChanged: _isSaving ? null : (_) => _toggleCheck('closing_done', closingDone),
                        activeThumbColor: AppColors.green600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign diary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            isSigned ? Icons.verified : Icons.draw,
                            size: 48,
                            color: isSigned ? AppColors.green600 : AppColors.gold,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSigned ? 'Diary Signed' : 'Sign Diary',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          if (diary?.signedByName != null) ...[
                            const SizedBox(height: 4),
                            Text('by ${diary!.signedByName}', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                          const SizedBox(height: 12),
                          if (!isSigned)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _signDiary,
                                child: const Text('Sign Now'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
