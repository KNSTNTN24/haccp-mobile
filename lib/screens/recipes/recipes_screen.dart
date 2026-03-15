import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/allergen_badge.dart';

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

    return RefreshIndicator(
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
                  Text('No recipes yet', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          // Group by category
          final grouped = <RecipeCategory, List<Recipe>>{};
          for (final r in recipes) {
            grouped.putIfAbsent(r.category, () => []).add(r);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ),
                  ...entry.value.map((recipe) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.orange50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.restaurant, color: AppColors.orange600),
                          ),
                          title: Text(recipe.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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
                      )),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
