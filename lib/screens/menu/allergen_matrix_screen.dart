import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../utils/menu_export.dart';
import '../../utils/diary_export.dart' show downloadFile;

const _allergenList = [
  'gluten', 'crustaceans', 'eggs', 'fish', 'peanuts', 'soybeans', 'milk',
  'nuts', 'celery', 'mustard', 'sesame', 'sulphites', 'lupin', 'molluscs',
];

const _allergenShort = {
  'gluten': 'GL', 'crustaceans': 'CR', 'eggs': 'EG', 'fish': 'FI',
  'peanuts': 'PN', 'soybeans': 'SO', 'milk': 'MI', 'nuts': 'NU',
  'celery': 'CE', 'mustard': 'MU', 'sesame': 'SE', 'sulphites': 'SU',
  'lupin': 'LU', 'molluscs': 'MO',
};

final menuRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('recipes')
      .select('*, recipe_ingredients(*, ingredients(*))')
      .eq('business_id', profile.businessId)
      .eq('active', true)
      .order('name');

  return (response as List).map((e) => Recipe.fromJson(e)).toList();
});

class AllergenMatrixScreen extends ConsumerWidget {
  const AllergenMatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(menuRecipesProvider);
    final business = ref.watch(businessProvider).value;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(menuRecipesProvider),
        child: recipesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (recipes) {
            if (recipes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No recipes to show', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 8,
                  headingRowHeight: 60,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 48,
                  columns: [
                    DataColumn(
                      label: Text('Dish', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    ..._allergenList.map((a) => DataColumn(
                          label: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              _allergenShort[a] ?? a,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )),
                  ],
                  rows: recipes.map((recipe) {
                    final allergens = recipe.allAllergens.map((a) => a.toLowerCase()).toSet();
                    return DataRow(cells: [
                      DataCell(SizedBox(
                        width: 120,
                        child: Text(recipe.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      )),
                      ..._allergenList.map((a) => DataCell(
                            Center(
                              child: allergens.contains(a)
                                  ? Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.red600,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          )),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: recipesAsync.whenOrNull(
        data: (recipes) => recipes.isNotEmpty
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                onPressed: () => _showExportSheet(context, recipes, business?.name ?? 'Menu'),
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: Text('Export', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              )
            : null,
      ),
    );
  }

  void _showExportSheet(BuildContext context, List<Recipe> recipes, String businessName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ExportSheet(recipes: recipes, businessName: businessName);
      },
    );
  }
}

class _ExportSheet extends StatefulWidget {
  final List<Recipe> recipes;
  final String businessName;
  const _ExportSheet({required this.recipes, required this.businessName});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _isPdf = true;
  bool _includeAllergens = true;
  bool _isExporting = false;

  Future<void> _export() async {
    setState(() => _isExporting = true);

    try {
      if (_isPdf) {
        final bytes = await generateMenuPdf(
          businessName: widget.businessName,
          recipes: widget.recipes,
          includeAllergens: _includeAllergens,
        );
        await downloadFile(bytes, 'menu_${DateTime.now().millisecondsSinceEpoch}.pdf');
      } else {
        final csv = generateMenuCsv(recipes: widget.recipes, includeAllergens: _includeAllergens);
        final bytes = Uint8List.fromList(utf8.encode(csv));
        await downloadFile(bytes, 'menu_${DateTime.now().millisecondsSinceEpoch}.csv');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu exported as ${_isPdf ? 'PDF' : 'CSV'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Export Menu',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.recipes.length} active dishes',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Format toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPdf = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isPdf ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded,
                                size: 20, color: _isPdf ? Colors.white : Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'PDF',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _isPdf ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPdf = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isPdf ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_chart_rounded,
                                size: 20, color: !_isPdf ? Colors.white : Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'CSV',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: !_isPdf ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Include allergens toggle
              GestureDetector(
                onTap: () => setState(() => _includeAllergens = !_includeAllergens),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _includeAllergens ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: _includeAllergens ? AppColors.primary : Colors.grey.shade400,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Include allergens',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Generate button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isExporting ? null : _export,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          'Generate ${_isPdf ? 'PDF' : 'CSV'}',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
