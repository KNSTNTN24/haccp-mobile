import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';

// Shared allergen info — same as menu screen
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

const _catIcon = <RecipeCategory, IconData>{
  RecipeCategory.starter: Icons.restaurant_rounded,
  RecipeCategory.main: Icons.dinner_dining_rounded,
  RecipeCategory.dessert: Icons.cake_rounded,
  RecipeCategory.side: Icons.rice_bowl_rounded,
  RecipeCategory.sauce: Icons.local_fire_department_rounded,
  RecipeCategory.drink: Icons.local_cafe_rounded,
  RecipeCategory.other: Icons.menu_book_rounded,
};

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
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

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(recipesProvider),
        child: recipesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (recipes) {
            if (recipes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('No recipes yet',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText)),
                    const SizedBox(height: 8),
                    Text('Tap + to add your first recipe',
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.midText)),
                  ],
                ),
              );
            }

            final grouped = <RecipeCategory, List<Recipe>>{};
            for (final r in recipes) {
              grouped.putIfAbsent(r.category, () => []).add(r);
            }
            final sections = grouped.entries.toList()
              ..sort((a, b) => a.key.index.compareTo(b.key.index));

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
                    // Section header — same as menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_catIcon[cat] ?? Icons.menu_book_rounded, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(cat.displayName,
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${items.length}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...items.map((recipe) => _DishCard(recipe: recipe)),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => context.go('/recipes/new'),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final Recipe recipe;
  const _DishCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final allergens = recipe.allAllergens.map((a) => a.toLowerCase()).toList()..sort();
    final none = allergens.isEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/recipes/${recipe.id}');
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(recipe.name,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.lightText),
              ],
            ),
            const SizedBox(height: 12),
            if (none)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 18, color: const Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text('No allergens',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                        Text(m.label,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: m.color),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
