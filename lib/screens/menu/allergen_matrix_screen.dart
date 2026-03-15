import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';

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

    return RefreshIndicator(
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
                  Text('No recipes to show', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
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
                    label: Text('Dish', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
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
    );
  }
}
