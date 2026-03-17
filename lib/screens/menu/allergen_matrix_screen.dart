import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../utils/menu_export.dart';
import '../../utils/diary_export.dart' show downloadFile;

// ─── Allergen data ───────────────────────────────────────────────────────────

const _allergenList = [
  'gluten', 'crustaceans', 'eggs', 'fish', 'peanuts', 'soybeans', 'milk',
  'nuts', 'celery', 'mustard', 'sesame', 'sulphites', 'lupin', 'molluscs',
];

class _A {
  final String code, label;
  final IconData icon;
  final Color color;
  const _A(this.code, this.label, this.icon, this.color);
}

final _info = <String, _A>{
  'gluten':      _A('GL', 'Gluten',      Icons.grass_rounded,           Color(0xFFD97706)),
  'crustaceans': _A('CR', 'Crustaceans', Icons.set_meal_rounded,        Color(0xFFDC2626)),
  'eggs':        _A('EG', 'Eggs',        Icons.egg_rounded,             Color(0xFFEA580C)),
  'fish':        _A('FI', 'Fish',        Icons.water_rounded,           Color(0xFF2563EB)),
  'peanuts':     _A('PN', 'Peanuts',     Icons.spa_rounded,             Color(0xFF92400E)),
  'soybeans':    _A('SO', 'Soybeans',    Icons.eco_rounded,             Color(0xFF16A34A)),
  'milk':        _A('MI', 'Milk',        Icons.local_drink_rounded,     Color(0xFF7C3AED)),
  'nuts':        _A('NU', 'Nuts',        Icons.forest_rounded,          Color(0xFFB45309)),
  'celery':      _A('CE', 'Celery',      Icons.yard_rounded,            Color(0xFF059669)),
  'mustard':     _A('MU', 'Mustard',     Icons.local_florist_rounded,   Color(0xFFCA8A04)),
  'sesame':      _A('SE', 'Sesame',      Icons.grain_rounded,           Color(0xFF57534E)),
  'sulphites':   _A('SU', 'Sulphites',   Icons.science_rounded,         Color(0xFF7C3AED)),
  'lupin':       _A('LU', 'Lupin',       Icons.filter_vintage_rounded,  Color(0xFFDB2777)),
  'molluscs':    _A('MO', 'Molluscs',    Icons.water_drop_rounded,      Color(0xFF0E7490)),
};

const _catIcon = <RecipeCategory, IconData>{
  RecipeCategory.starter: Icons.restaurant_rounded,
  RecipeCategory.main: Icons.dinner_dining_rounded,
  RecipeCategory.dessert: Icons.cake_rounded,
  RecipeCategory.side: Icons.rice_bowl_rounded,
  RecipeCategory.sauce: Icons.local_fire_department_rounded,
  RecipeCategory.drink: Icons.local_cafe_rounded,
  RecipeCategory.other: Icons.menu_book_rounded,
};

// ─── Provider ────────────────────────────────────────────────────────────────

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

// ─── Screen ──────────────────────────────────────────────────────────────────

class AllergenMatrixScreen extends ConsumerStatefulWidget {
  const AllergenMatrixScreen({super.key});
  @override
  ConsumerState<AllergenMatrixScreen> createState() => _State();
}

class _State extends ConsumerState<AllergenMatrixScreen> {
  bool _matrix = false;

  Map<RecipeCategory, List<Recipe>> _group(List<Recipe> r) {
    final m = <RecipeCategory, List<Recipe>>{};
    for (final x in r) m.putIfAbsent(x.category, () => []).add(x);
    return Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.index.compareTo(b.key.index)));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(menuRecipesProvider);
    final business = ref.watch(businessProvider).value;

    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (recipes) {
        if (recipes.isEmpty) return _empty();
        return Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(menuRecipesProvider),
              child: _matrix ? _buildMatrix(recipes) : _buildCards(recipes),
            ),
            // Bottom buttons row
            Positioned(
              right: 16,
              bottom: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Export button
                  GestureDetector(
                    onTap: () => _showExportSheet(context, recipes, business?.name ?? 'Menu'),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // View toggle
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _matrix = !_matrix);
                    },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Icon(_matrix ? Icons.style_rounded : Icons.grid_view_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.restaurant_menu_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text('No dishes yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText)),
          const SizedBox(height: 8),
          Text('Add recipes to see allergens here', style: GoogleFonts.inter(fontSize: 15, color: AppColors.midText)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARDS VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCards(List<Recipe> recipes) {
    final grouped = _group(recipes);
    final sections = grouped.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final cat = sections[i].key;
        final items = sections[i].value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (i > 0) const SizedBox(height: 28),
            _sectionHeader(cat, items.length),
            const SizedBox(height: 12),
            ...items.map(_dishCard),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(RecipeCategory cat, int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(_catIcon[cat] ?? Icons.menu_book_rounded, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(cat.displayName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Text('$count', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _dishCard(Recipe recipe) {
    final allergens = recipe.allAllergens.map((a) => a.toLowerCase()).toList()..sort();
    final none = allergens.isEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recipe.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          if (none)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 18, color: const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Text('No allergens', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF059669))),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: allergens.map((a) {
                final m = _info[a];
                if (m == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: m.color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.icon, size: 16, color: m.color),
                      const SizedBox(width: 6),
                      Text(m.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: m.color)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATRIX VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMatrix(List<Recipe> recipes) {
    final present = <String>{};
    for (final r in recipes) for (final a in r.allAllergens) present.add(a.toLowerCase());
    final cols = _allergenList.where((a) => present.contains(a)).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 2))),
              child: Row(
                children: [
                  SizedBox(width: 170, child: Text('Dish', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.midText))),
                  ...cols.map((a) {
                    final m = _info[a]!;
                    return SizedBox(
                      width: 48,
                      child: Column(children: [
                        Container(width: 32, height: 32, decoration: BoxDecoration(color: m.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(m.icon, size: 16, color: m.color)),
                        const SizedBox(height: 4),
                        Text(m.code, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: m.color)),
                      ]),
                    );
                  }),
                ],
              ),
            ),
            ...recipes.asMap().entries.map((e) {
              final recipe = e.value;
              final isEven = e.key.isEven;
              final set = recipe.allAllergens.map((a) => a.toLowerCase()).toSet();
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isEven ? const Color(0xFFF8FAFC) : Colors.transparent,
                  border: Border(bottom: BorderSide(color: const Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 170, child: Text(recipe.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A2E)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ...cols.map((a) {
                      final m = _info[a]!;
                      final has = set.contains(a);
                      return SizedBox(
                        width: 48,
                        child: Center(
                          child: has
                              ? Container(width: 28, height: 28, decoration: BoxDecoration(color: m.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.check_rounded, size: 16, color: m.color))
                              : const SizedBox.shrink(),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  void _showExportSheet(BuildContext context, List<Recipe> recipes, String businessName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExportSheet(recipes: recipes, businessName: businessName),
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
        final bytes = await generateMenuPdf(businessName: widget.businessName, recipes: widget.recipes, includeAllergens: _includeAllergens);
        await downloadFile(bytes, 'menu_${DateTime.now().millisecondsSinceEpoch}.pdf');
      } else {
        final csv = generateMenuCsv(recipes: widget.recipes, includeAllergens: _includeAllergens);
        final bytes = Uint8List.fromList(utf8.encode(csv));
        await downloadFile(bytes, 'menu_${DateTime.now().millisecondsSinceEpoch}.csv');
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Menu exported as ${_isPdf ? 'PDF' : 'CSV'}'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.red600));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Export Menu', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${widget.recipes.length} active dishes', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: GestureDetector(onTap: () => setState(() => _isPdf = true),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _isPdf ? AppColors.primary : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.picture_as_pdf_rounded, size: 20, color: _isPdf ? Colors.white : Colors.grey.shade600), const SizedBox(width: 8), Text('PDF', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: _isPdf ? Colors.white : Colors.grey.shade600))])))),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(onTap: () => setState(() => _isPdf = false),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: !_isPdf ? AppColors.primary : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.table_chart_rounded, size: 20, color: !_isPdf ? Colors.white : Colors.grey.shade600), const SizedBox(width: 8), Text('CSV', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: !_isPdf ? Colors.white : Colors.grey.shade600))])))),
              ]),
              const SizedBox(height: 16),
              GestureDetector(onTap: () => setState(() => _includeAllergens = !_includeAllergens),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(children: [Icon(_includeAllergens ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: _includeAllergens ? AppColors.primary : Colors.grey.shade400, size: 22), const SizedBox(width: 12), Expanded(child: Text('Include allergens', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)))]))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(onPressed: _isExporting ? null : _export, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: _isExporting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text('Generate ${_isPdf ? 'PDF' : 'CSV'}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)))),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
