import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/supabase.dart';
import '../../config/theme.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import 'recipes_screen.dart';

const _allAllergens = [
  'gluten', 'crustaceans', 'eggs', 'fish', 'peanuts', 'soybeans',
  'milk', 'nuts', 'celery', 'mustard', 'sesame', 'sulphites', 'lupin', 'molluscs',
];

class _IngredientEntry {
  String id; // ingredient ID (empty for new)
  String recipeIngredientId; // recipe_ingredients row ID (empty for new)
  String name;
  String quantity;
  String unit;
  List<String> allergens;
  bool isNew;

  _IngredientEntry({
    this.id = '',
    this.recipeIngredientId = '',
    this.name = '',
    this.quantity = '',
    this.unit = '',
    List<String>? allergens,
    this.isNew = true,
  }) : allergens = allergens ?? [];
}

class RecipeEditScreen extends ConsumerStatefulWidget {
  final String recipeId;
  const RecipeEditScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends ConsumerState<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _cookingMethodCtrl = TextEditingController();
  final _cookingTempCtrl = TextEditingController();
  final _cookingTimeCtrl = TextEditingController();
  final _reheatingCtrl = TextEditingController();
  final _chillingCtrl = TextEditingController();

  RecipeCategory _category = RecipeCategory.main;
  String _cookingTimeUnit = 'minutes';
  bool _hotHolding = false;
  bool _saving = false;
  bool _isLoading = true;
  final List<_IngredientEntry> _ingredients = [];
  final Set<String> _deletedRecipeIngredientIds = {};

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _instructionsCtrl.dispose();
    _cookingMethodCtrl.dispose();
    _cookingTempCtrl.dispose();
    _cookingTimeCtrl.dispose();
    _reheatingCtrl.dispose();
    _chillingCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    final response = await SupabaseConfig.client
        .from('recipes')
        .select('*, recipe_ingredients(*, ingredients(*))')
        .eq('id', widget.recipeId)
        .single();

    final recipe = Recipe.fromJson(response);

    _nameCtrl.text = recipe.name;
    _descCtrl.text = recipe.description ?? '';
    _instructionsCtrl.text = recipe.instructions;
    _cookingMethodCtrl.text = recipe.cookingMethod ?? '';
    _cookingTempCtrl.text = recipe.cookingTemp?.toStringAsFixed(0) ?? '';
    _cookingTimeCtrl.text = recipe.cookingTime?.toStringAsFixed(0) ?? '';
    _reheatingCtrl.text = recipe.reheatingInstructions ?? '';
    _chillingCtrl.text = recipe.chillingMethod ?? '';
    _category = recipe.category;
    _cookingTimeUnit = recipe.cookingTimeUnit ?? 'minutes';
    _hotHolding = recipe.hotHoldingRequired;

    if (recipe.ingredients != null) {
      for (final ri in recipe.ingredients!) {
        _ingredients.add(_IngredientEntry(
          id: ri.ingredient?.id ?? '',
          recipeIngredientId: ri.id,
          name: ri.ingredient?.name ?? '',
          quantity: ri.quantity ?? '',
          unit: ri.unit ?? '',
          allergens: ri.ingredient?.allergens.toList() ?? [],
          isNew: false,
        ));
      }
    }

    setState(() => _isLoading = false);
  }

  void _addIngredient() => setState(() => _ingredients.add(_IngredientEntry()));

  void _removeIngredient(int i) {
    final entry = _ingredients[i];
    if (!entry.isNew && entry.recipeIngredientId.isNotEmpty) {
      _deletedRecipeIngredientIds.add(entry.recipeIngredientId);
    }
    setState(() => _ingredients.removeAt(i));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final profile = ref.read(profileProvider).value;
      if (profile == null) return;
      final db = SupabaseConfig.client;

      // Update recipe fields
      await db.from('recipes').update({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'category': _category.name,
        'instructions': _instructionsCtrl.text.trim(),
        'cooking_method': _cookingMethodCtrl.text.trim().isEmpty ? null : _cookingMethodCtrl.text.trim(),
        'cooking_temp': _cookingTempCtrl.text.trim().isEmpty ? null : double.tryParse(_cookingTempCtrl.text.trim()),
        'cooking_time': _cookingTimeCtrl.text.trim().isEmpty ? null : double.tryParse(_cookingTimeCtrl.text.trim()),
        'cooking_time_unit': _cookingTimeUnit,
        'reheating_instructions': _reheatingCtrl.text.trim().isEmpty ? null : _reheatingCtrl.text.trim(),
        'hot_holding_required': _hotHolding,
        'chilling_method': _chillingCtrl.text.trim().isEmpty ? null : _chillingCtrl.text.trim(),
      }).eq('id', widget.recipeId);

      // Delete removed ingredients
      for (final riId in _deletedRecipeIngredientIds) {
        await db.from('recipe_ingredients').delete().eq('id', riId);
      }

      // Update existing and add new ingredients
      for (final ing in _ingredients) {
        if (ing.name.trim().isEmpty) continue;

        // Find or create ingredient
        String ingredientId;
        if (!ing.isNew && ing.id.isNotEmpty) {
          // Update existing ingredient allergens
          await db.from('ingredients').update({
            'allergens': ing.allergens,
          }).eq('id', ing.id);
          ingredientId = ing.id;
        } else {
          final existing = await db.from('ingredients').select('id')
              .eq('name', ing.name.trim())
              .eq('business_id', profile.businessId)
              .maybeSingle();
          if (existing != null) {
            ingredientId = existing['id'] as String;
          } else {
            final newIng = await db.from('ingredients').insert({
              'name': ing.name.trim(),
              'allergens': ing.allergens,
              'business_id': profile.businessId,
            }).select('id').single();
            ingredientId = newIng['id'] as String;
          }
        }

        if (ing.isNew) {
          // Insert new recipe_ingredient
          await db.from('recipe_ingredients').insert({
            'recipe_id': widget.recipeId,
            'ingredient_id': ingredientId,
            'quantity': ing.quantity.trim().isEmpty ? null : ing.quantity.trim(),
            'unit': ing.unit.trim().isEmpty ? null : ing.unit.trim(),
          });
        } else if (ing.recipeIngredientId.isNotEmpty) {
          // Update existing recipe_ingredient
          await db.from('recipe_ingredients').update({
            'ingredient_id': ingredientId,
            'quantity': ing.quantity.trim().isEmpty ? null : ing.quantity.trim(),
            'unit': ing.unit.trim().isEmpty ? null : ing.unit.trim(),
          }).eq('id', ing.recipeIngredientId);
        }
      }

      ref.invalidate(recipesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe updated!'), backgroundColor: Colors.green),
        );
        context.go('/recipes/${widget.recipeId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Recipe', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/recipes/${widget.recipeId}'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Recipe Name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RecipeCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: RecipeCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsCtrl,
              decoration: const InputDecoration(labelText: 'Instructions'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Text('Cooking Info',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cookingMethodCtrl,
              decoration: const InputDecoration(labelText: 'Cooking Method'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _cookingTempCtrl,
                  decoration: const InputDecoration(labelText: 'Temp (°C)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cookingTimeCtrl,
                  decoration: const InputDecoration(labelText: 'Time'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<String>(
                  value: _cookingTimeUnit,
                  items: const [
                    DropdownMenuItem(value: 'minutes', child: Text('min')),
                    DropdownMenuItem(value: 'hours', child: Text('hrs')),
                  ],
                  onChanged: (v) => setState(() => _cookingTimeUnit = v!),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Hot Holding Required'),
              value: _hotHolding,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _hotHolding = v),
            ),
            TextFormField(
              controller: _reheatingCtrl,
              decoration: const InputDecoration(labelText: 'Reheating Instructions'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _chillingCtrl,
              decoration: const InputDecoration(labelText: 'Chilling Method'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ingredients',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            ..._ingredients.asMap().entries.map((entry) {
              final idx = entry.key;
              final ing = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: ing.name,
                            decoration: const InputDecoration(labelText: 'Name *', isDense: true),
                            onChanged: (v) => ing.name = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: ing.quantity,
                            decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                            onChanged: (v) => ing.quantity = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: ing.unit,
                            decoration: const InputDecoration(labelText: 'Unit', isDense: true),
                            onChanged: (v) => ing.unit = v,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                          onPressed: () => _removeIngredient(idx),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      const Text('Allergens:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _allAllergens.map((a) {
                          final selected = ing.allergens.contains(a);
                          return FilterChip(
                            label: Text(a, style: TextStyle(fontSize: 10, color: selected ? Colors.white : null)),
                            selected: selected,
                            selectedColor: AppColors.primary,
                            onSelected: (sel) => setState(() => sel ? ing.allergens.add(a) : ing.allergens.remove(a)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Save Changes', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
