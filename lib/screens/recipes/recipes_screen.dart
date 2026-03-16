import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/allergen_badge.dart';

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  final response = await SupabaseConfig.client
      .from('recipes')
      .select('*, recipe_ingredients(*, ingredients(*))')
      .eq('business_id', profile.businessId)
      .order('active', ascending: false)
      .order('name');

  return (response as List).map((e) => Recipe.fromJson(e)).toList();
});

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final canManage = profile?.canManageRecipes ?? false;

    return Scaffold(
      body: RefreshIndicator(
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
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No recipes yet', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final activeRecipes = recipes.where((r) => r.active).toList();
          final inactiveRecipes = recipes.where((r) => !r.active).toList();

          // Group active recipes by category
          final grouped = <RecipeCategory, List<Recipe>>{};
          for (final r in activeRecipes) {
            grouped.putIfAbsent(r.category, () => []).add(r);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active recipes grouped by category
              ...grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                    ),
                    ...entry.value.map((recipe) => _buildRecipeCard(context, recipe, isInactive: false)),
                  ],
                );
              }),

              // Inactive recipes section (only for owner/manager/chef)
              if (canManage && inactiveRecipes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Inactive Recipes',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightText,
                    ),
                  ),
                ),
                ...inactiveRecipes.map((recipe) => _buildRecipeCard(context, recipe, isInactive: true)),
              ],
            ],
          );
        },
      ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              backgroundColor: AppColors.gold,
              onPressed: () => context.go('/recipes/new'),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe, {required bool isInactive}) {
    return Opacity(
      opacity: isInactive ? 0.55 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isInactive ? Colors.grey.shade100 : AppColors.orange50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.restaurant, color: isInactive ? Colors.grey : AppColors.orange600),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(recipe.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
              if (isInactive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Inactive',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightText, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          subtitle: recipe.allAllergens.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: recipe.allAllergens.map((a) => AllergenBadge(allergen: a)).toList(),
                  ),
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/recipes/${recipe.id}'),
        ),
      ),
    );
  }
}
