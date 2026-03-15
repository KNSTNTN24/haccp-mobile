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
  String name = '';
  String quantity = '';
  String unit = '';
  List<String> allergens = [];
}

class RecipeNewScreen extends ConsumerStatefulWidget {
  const RecipeNewScreen({super.key});

  @override
  ConsumerState<RecipeNewScreen> createState() => _RecipeNewScreenState();
}

class _RecipeNewScreenState extends ConsumerState<RecipeNewScreen> {
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
  final List<_IngredientEntry> _ingredients = [];

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

  void _addIngredient() => setState(() => _ingredients.add(_IngredientEntry()));
  void _removeIngredient(int i) => setState(() => _ingredients.removeAt(i));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final profile = ref.read(profileProvider).value;
      final user = ref.read(currentUserProvider);
      if (profile == null || user == null) return;
      final db = SupabaseConfig.client;

      final recipeResult = await db.from('recipes').insert({
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
        'business_id': profile.businessId,
        'created_by': user.id,
        'active': true,
      }).select('id').single();
      final recipeId = recipeResult['id'] as String;

      for (final ing in _ingredients) {
        if (ing.name.trim().isEmpty) continue;
        final existing = await db.from('ingredients').select('id')
            .eq('name', ing.name.trim()).eq('business_id', profile.businessId).maybeSingle();
        String ingredientId;
        if (existing != null) {
          ingredientId = existing['id'] as String;
        } else {
          final newIng = await db.from('ingredients').insert({
            'name': ing.name.trim(), 'allergens': ing.allergens, 'business_id': profile.businessId,
          }).select('id').single();
          ingredientId = newIng['id'] as String;
        }
        await db.from('recipe_ingredients').insert({
          'recipe_id': recipeId, 'ingredient_id': ingredientId,
          'quantity': ing.quantity.trim().isEmpty ? null : ing.quantity.trim(),
          'unit': ing.unit.trim().isEmpty ? null : ing.unit.trim(),
        });
      }

      ref.invalidate(recipesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe created!'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Recipe', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)), backgroundColor: AppColors.darkBlue, foregroundColor: AppColors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Recipe Name *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<RecipeCategory>(value: _category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: RecipeCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(), onChanged: (v) => setState(() => _category = v!)),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _instructionsCtrl, decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder()), maxLines: 4),
            const SizedBox(height: 16),
            Text('Cooking Info', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBlue)),
            const SizedBox(height: 8),
            TextFormField(controller: _cookingMethodCtrl, decoration: const InputDecoration(labelText: 'Cooking Method', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _cookingTempCtrl, decoration: const InputDecoration(labelText: 'Temp (°C)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _cookingTimeCtrl, decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              SizedBox(width: 110, child: DropdownButtonFormField<String>(value: _cookingTimeUnit, decoration: const InputDecoration(border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'minutes', child: Text('min')), DropdownMenuItem(value: 'hours', child: Text('hrs'))], onChanged: (v) => setState(() => _cookingTimeUnit = v!))),
            ]),
            const SizedBox(height: 12),
            SwitchListTile(title: const Text('Hot Holding Required'), value: _hotHolding, activeColor: AppColors.gold, onChanged: (v) => setState(() => _hotHolding = v)),
            TextFormField(controller: _reheatingCtrl, decoration: const InputDecoration(labelText: 'Reheating Instructions', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _chillingCtrl, decoration: const InputDecoration(labelText: 'Chilling Method', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Ingredients', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBlue)),
              TextButton.icon(onPressed: _addIngredient, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
            ]),
            ..._ingredients.asMap().entries.map((entry) {
              final idx = entry.key; final ing = entry.value;
              return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(flex: 3, child: TextFormField(decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder(), isDense: true), onChanged: (v) => ing.name = v)),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: TextFormField(decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true), onChanged: (v) => ing.quantity = v)),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: TextFormField(decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder(), isDense: true), onChanged: (v) => ing.unit = v)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _removeIngredient(idx)),
                ]),
                const SizedBox(height: 8),
                const Text('Allergens:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Wrap(spacing: 4, runSpacing: 4, children: _allAllergens.map((a) {
                  final selected = ing.allergens.contains(a);
                  return FilterChip(label: Text(a, style: TextStyle(fontSize: 10, color: selected ? Colors.white : null)), selected: selected, selectedColor: AppColors.gold, onSelected: (sel) => setState(() => sel ? ing.allergens.add(a) : ing.allergens.remove(a)), padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap);
                }).toList()),
              ])));
            }),
            const SizedBox(height: 24),
            SizedBox(height: 48, child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Save Recipe', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
