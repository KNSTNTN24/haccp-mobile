import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/allergen_badge.dart';
import 'recipes_screen.dart';

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
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    final response = await SupabaseConfig.client
        .from('recipes')
        .select('*, recipe_ingredients(*, ingredients(*))')
        .eq('id', widget.recipeId)
        .single();

    setState(() {
      _recipe = Recipe.fromJson(response);
      _isLoading = false;
    });
  }

  Future<void> _toggleActive() async {
    final recipe = _recipe!;
    final newActive = !recipe.active;

    await SupabaseConfig.client
        .from('recipes')
        .update({'active': newActive})
        .eq('id', recipe.id);

    ref.invalidate(recipesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newActive ? 'Recipe activated' : 'Recipe deactivated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadRecipe();
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Recipe', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${_recipe!.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await SupabaseConfig.client.from('recipes').delete().eq('id', _recipe!.id);

    ref.invalidate(recipesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/recipes');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final recipe = _recipe!;
    final profile = ref.watch(profileProvider).value;
    final canManage = profile?.canManageRecipes ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/recipes'),
        ),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.go('/recipes/edit/${recipe.id}');
                    break;
                  case 'toggle_active':
                    _toggleActive();
                    break;
                  case 'delete':
                    _deleteRecipe();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_active',
                  child: ListTile(
                    leading: Icon(recipe.active ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    title: Text(recipe.active ? 'Deactivate' : 'Activate'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppColors.error),
                    title: Text('Delete', style: TextStyle(color: AppColors.error)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inactive banner
            if (!recipe.active)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, size: 18, color: AppColors.lightText),
                    const SizedBox(width: 8),
                    Text(
                      'This recipe is inactive',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            // Category & cooking info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(recipe.category.displayName,
                              style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        if (recipe.hotHoldingRequired) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.red50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Hot Holding',
                                style: TextStyle(color: AppColors.red600, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    if (recipe.description != null) ...[
                      const SizedBox(height: 12),
                      Text(recipe.description!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    ],
                    if (recipe.cookingTemp != null || recipe.cookingTime != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (recipe.cookingTemp != null) ...[
                            const Icon(Icons.thermostat, size: 18, color: AppColors.orange600),
                            const SizedBox(width: 4),
                            Text('${recipe.cookingTemp!.toStringAsFixed(0)}°C'),
                            const SizedBox(width: 16),
                          ],
                          if (recipe.cookingTime != null) ...[
                            const Icon(Icons.timer, size: 18, color: AppColors.blue600),
                            const SizedBox(width: 4),
                            Text('${recipe.cookingTime!.toStringAsFixed(0)} ${recipe.cookingTimeUnit ?? 'min'}'),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Allergens
            if (recipe.allAllergens.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allergens', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: recipe.allAllergens.map((a) => AllergenBadge(allergen: a)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Ingredients
            if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ingredients', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...recipe.ingredients!.map((ri) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: AppColors.gold),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${ri.ingredient?.name ?? 'Unknown'}${ri.quantity != null ? ' - ${ri.quantity}${ri.unit != null ? ' ${ri.unit}' : ''}' : ''}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                if (ri.ingredient != null && ri.ingredient!.allergens.isNotEmpty)
                                  Icon(Icons.warning_amber, size: 16, color: AppColors.orange600),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],

            // Instructions
            if (recipe.instructions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instructions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(recipe.instructions, style: const TextStyle(fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
