import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import 'recipes_screen.dart';

class _A {
  final String label;
  final IconData icon;
  final Color color;
  const _A(this.label, this.icon, this.color);
}

final _info = <String, _A>{
  'gluten':      _A('Gluten',      Icons.grass_rounded,           Color(0xFFD97706)),
  'crustaceans': _A('Crustaceans', Icons.set_meal_rounded,        Color(0xFFDC2626)),
  'eggs':        _A('Eggs',        Icons.egg_rounded,             Color(0xFFEA580C)),
  'fish':        _A('Fish',        Icons.water_rounded,           Color(0xFF2563EB)),
  'peanuts':     _A('Peanuts',     Icons.spa_rounded,             Color(0xFF92400E)),
  'soybeans':    _A('Soybeans',    Icons.eco_rounded,             Color(0xFF16A34A)),
  'milk':        _A('Milk',        Icons.local_drink_rounded,     Color(0xFF7C3AED)),
  'nuts':        _A('Nuts',        Icons.forest_rounded,          Color(0xFFB45309)),
  'celery':      _A('Celery',      Icons.yard_rounded,            Color(0xFF059669)),
  'mustard':     _A('Mustard',     Icons.local_florist_rounded,   Color(0xFFCA8A04)),
  'sesame':      _A('Sesame',      Icons.grain_rounded,           Color(0xFF57534E)),
  'sulphites':   _A('Sulphites',   Icons.science_rounded,         Color(0xFF7C3AED)),
  'lupin':       _A('Lupin',       Icons.filter_vintage_rounded,  Color(0xFFDB2777)),
  'molluscs':    _A('Molluscs',    Icons.water_drop_rounded,      Color(0xFF0E7490)),
};

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});
  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadRecipe(); }

  Future<void> _loadRecipe() async {
    final response = await SupabaseConfig.client
        .from('recipes').select('*, recipe_ingredients(*, ingredients(*))').eq('id', widget.recipeId).single();
    setState(() { _recipe = Recipe.fromJson(response); _isLoading = false; });
  }

  Future<void> _toggleActive() async {
    final recipe = _recipe!;
    await SupabaseConfig.client.from('recipes').update({'active': !recipe.active}).eq('id', recipe.id);
    ref.invalidate(recipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(!recipe.active ? 'Recipe activated' : 'Recipe deactivated'), behavior: SnackBarBehavior.floating));
      await _loadRecipe();
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Delete Recipe', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: Text('Are you sure you want to delete "${_recipe!.name}"? This cannot be undone.', style: GoogleFonts.inter()),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: GoogleFonts.inter())),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
      ],
    ));
    if (confirmed != true) return;
    await SupabaseConfig.client.from('recipes').delete().eq('id', _recipe!.id);
    ref.invalidate(recipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe deleted'), behavior: SnackBarBehavior.floating));
      context.go('/recipes');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.canPop() ? context.pop() : context.go('/recipes'))),
        body: const Center(child: CircularProgressIndicator()));
    }

    final recipe = _recipe!;
    final profile = ref.watch(profileProvider).value;
    final canManage = profile?.canManageRecipes ?? false;
    final allergens = recipe.allAllergens.map((a) => a.toLowerCase()).toList()..sort();
    final hasAllergens = allergens.isNotEmpty;
    final hasDietary = recipe.dietaryLabels.isNotEmpty;
    final hasIngredients = recipe.ingredients != null && recipe.ingredients!.isNotEmpty;
    final hasInstructions = recipe.instructions.isNotEmpty;
    final hasCooking = recipe.cookingTemp != null || recipe.cookingTime != null || recipe.cookingMethod != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface, elevation: 0, scrolledUnderElevation: 0.5,
        title: Text(recipe.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText)),
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.canPop() ? context.pop() : context.go('/recipes')),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') context.go('/recipes/edit/${recipe.id}');
                else if (value == 'toggle_active') _toggleActive();
                else if (value == 'delete') _deleteRecipe();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'), dense: true, contentPadding: EdgeInsets.zero)),
                PopupMenuItem(value: 'toggle_active', child: ListTile(leading: Icon(recipe.active ? Icons.visibility_off_outlined : Icons.visibility_outlined), title: Text(recipe.active ? 'Deactivate' : 'Activate'), dense: true, contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: AppColors.error), title: Text('Delete', style: TextStyle(color: AppColors.error)), dense: true, contentPadding: EdgeInsets.zero)),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inactive banner
            if (!recipe.active) Container(
              width: double.infinity, margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [
                Icon(Icons.visibility_off, size: 18, color: AppColors.lightText), const SizedBox(width: 8),
                Text('This recipe is inactive', style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightText, fontWeight: FontWeight.w500)),
              ]),
            ),

            // Hero card
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill(recipe.category.displayName, AppColors.primary, Icons.restaurant_rounded),
                if (recipe.hotHoldingRequired) _pill('Hot Holding', const Color(0xFFDC2626), Icons.local_fire_department_rounded),
                ...recipe.extraCareFlags.map((f) => _pill(f, const Color(0xFFD97706), Icons.warning_amber_rounded)),
              ]),
              if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(recipe.description!, style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: AppColors.midText)),
              ],
              if (hasCooking) ...[
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      if (recipe.cookingTemp != null) _statChip(Icons.thermostat_rounded, '${recipe.cookingTemp!.toStringAsFixed(0)}°C', const Color(0xFFEA580C)),
                      if (recipe.cookingTime != null) _statChip(Icons.timer_rounded, '${recipe.cookingTime!.toStringAsFixed(0)} ${recipe.cookingTimeUnit ?? 'min'}', const Color(0xFF2563EB)),
                      if (recipe.cookingMethod != null) _statChip(Icons.outdoor_grill_rounded, recipe.cookingMethod!, const Color(0xFF059669)),
                    ],
                  )),
              ],
            ])),

            // Dietary & Allergens
            if (hasAllergens || hasDietary) ...[
              const SizedBox(height: 12),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle('Dietary & Allergens', Icons.warning_rounded, const Color(0xFFDC2626)),
                const SizedBox(height: 14),
                if (hasDietary) ...[
                  Wrap(spacing: 8, runSpacing: 8, children: recipe.dietaryLabels.map((label) {
                    Color color;
                    switch (label) {
                      case 'Vegan': color = const Color(0xFF16A34A); break;
                      case 'Vegetarian': color = const Color(0xFF059669); break;
                      case 'GF': color = const Color(0xFF2563EB); break;
                      case 'DF': color = const Color(0xFFD97706); break;
                      default: color = Colors.grey.shade600;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                    );
                  }).toList()),
                  if (hasAllergens) const SizedBox(height: 10),
                ],
                if (hasAllergens) Wrap(spacing: 8, runSpacing: 8, children: allergens.map((a) {
                  final m = _info[a]; if (m == null) return const SizedBox.shrink();
                  return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: m.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: m.color.withValues(alpha: 0.2))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(m.icon, size: 16, color: m.color), const SizedBox(width: 6), Text(m.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: m.color))]));
                }).toList()),
              ])),
            ],

            // Ingredients
            if (hasIngredients) ...[
              const SizedBox(height: 12),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle('Ingredients', Icons.shopping_basket_rounded, const Color(0xFF059669)),
                const SizedBox(height: 14),
                ...recipe.ingredients!.asMap().entries.map((entry) {
                  final ri = entry.value;
                  final name = ri.ingredient?.name ?? 'Unknown';
                  final hasQty = ri.quantity != null && ri.quantity!.isNotEmpty;
                  final hasAllergen = ri.ingredient != null && ri.ingredient!.allergens.isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: entry.key.isEven ? const Color(0xFFF8FAFC) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Container(width: 26, height: 26, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text('${entry.key + 1}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.darkText)),
                        if (hasQty) Text('${ri.quantity}${ri.unit != null ? ' ${ri.unit}' : ''}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.midText)),
                      ])),
                      if (hasAllergen) Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                        child: Icon(Icons.warning_rounded, size: 16, color: const Color(0xFFDC2626))),
                    ]),
                  );
                }),
              ])),
            ],

            // Instructions
            if (hasInstructions) ...[
              const SizedBox(height: 12),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle('Instructions', Icons.menu_book_rounded, const Color(0xFF2563EB)),
                const SizedBox(height: 14),
                Text(recipe.instructions, style: GoogleFonts.inter(fontSize: 15, height: 1.7, color: AppColors.darkText)),
              ])),
            ],

            // Food Safety
            if (recipe.sfbbCheckMethod != null || recipe.reheatingInstructions != null || recipe.chillingMethod != null) ...[
              const SizedBox(height: 12),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle('Food Safety', Icons.health_and_safety_rounded, const Color(0xFF7C3AED)),
                const SizedBox(height: 14),
                if (recipe.sfbbCheckMethod != null) _safetyRow('Check Method', recipe.sfbbCheckMethod!),
                if (recipe.reheatingInstructions != null) _safetyRow('Reheating', recipe.reheatingInstructions!),
                if (recipe.chillingMethod != null) _safetyRow('Chilling', recipe.chillingMethod!),
              ])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEDE9E3))),
    child: child);

  Widget _sectionTitle(String title, IconData icon, Color color) => Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: color)),
    const SizedBox(width: 10),
    Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText)),
  ]);

  Widget _pill(String label, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 5), Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color))]));

  Widget _statChip(IconData icon, String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 20, color: color), const SizedBox(width: 6),
    Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText))]);

  Widget _safetyRow(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightText, letterSpacing: 0.3)),
    const SizedBox(height: 4),
    Text(value, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.darkText)),
  ]));
}
