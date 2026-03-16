enum RecipeCategory {
  starter,
  main,
  dessert,
  side,
  sauce,
  drink,
  other;

  String get displayName {
    switch (this) {
      case RecipeCategory.starter:
        return 'Starter';
      case RecipeCategory.main:
        return 'Main';
      case RecipeCategory.dessert:
        return 'Dessert';
      case RecipeCategory.side:
        return 'Side';
      case RecipeCategory.sauce:
        return 'Sauce';
      case RecipeCategory.drink:
        return 'Drink';
      case RecipeCategory.other:
        return 'Other';
    }
  }

  static RecipeCategory fromString(String value) {
    return RecipeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RecipeCategory.other,
    );
  }
}

class Recipe {
  final String id;
  final String name;
  final String? description;
  final RecipeCategory category;
  final String instructions;
  final String? cookingMethod;
  final double? cookingTemp;
  final double? cookingTime;
  final String? cookingTimeUnit;
  final String? sfbbCheckMethod;
  final List<String> extraCareFlags;
  final String? reheatingInstructions;
  final bool hotHoldingRequired;
  final String? chillingMethod;
  final String? photoUrl;
  final String? sourceVideoUrl;
  final String businessId;
  final String createdBy;
  final bool active;
  final DateTime createdAt;
  final List<RecipeIngredient>? ingredients;

  Recipe({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.instructions = '',
    this.cookingMethod,
    this.cookingTemp,
    this.cookingTime,
    this.cookingTimeUnit,
    this.sfbbCheckMethod,
    this.extraCareFlags = const [],
    this.reheatingInstructions,
    this.hotHoldingRequired = false,
    this.chillingMethod,
    this.photoUrl,
    this.sourceVideoUrl,
    required this.businessId,
    required this.createdBy,
    this.active = true,
    required this.createdAt,
    this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: RecipeCategory.fromString(json['category'] as String),
      instructions: json['instructions'] as String? ?? '',
      cookingMethod: json['cooking_method'] as String?,
      cookingTemp: (json['cooking_temp'] as num?)?.toDouble(),
      cookingTime: (json['cooking_time'] as num?)?.toDouble(),
      cookingTimeUnit: json['cooking_time_unit'] as String?,
      sfbbCheckMethod: json['sfbb_check_method'] as String?,
      extraCareFlags: List<String>.from(json['extra_care_flags'] ?? []),
      reheatingInstructions: json['reheating_instructions'] as String?,
      hotHoldingRequired: json['hot_holding_required'] as bool? ?? false,
      chillingMethod: json['chilling_method'] as String?,
      photoUrl: json['photo_url'] as String?,
      sourceVideoUrl: json['source_video_url'] as String?,
      businessId: json['business_id'] as String,
      createdBy: json['created_by'] as String,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      ingredients: json['recipe_ingredients'] != null
          ? (json['recipe_ingredients'] as List)
              .map((e) => RecipeIngredient.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category.name,
        'instructions': instructions,
        'cooking_method': cookingMethod,
        'cooking_temp': cookingTemp,
        'cooking_time': cookingTime,
        'cooking_time_unit': cookingTimeUnit,
        'sfbb_check_method': sfbbCheckMethod,
        'extra_care_flags': extraCareFlags,
        'reheating_instructions': reheatingInstructions,
        'hot_holding_required': hotHoldingRequired,
        'chilling_method': chillingMethod,
        'photo_url': photoUrl,
        'source_video_url': sourceVideoUrl,
        'business_id': businessId,
        'created_by': createdBy,
        'active': active,
      };

  List<String> get allAllergens {
    if (ingredients == null) return [];
    final allergens = <String>{};
    for (final ri in ingredients!) {
      if (ri.ingredient != null) {
        allergens.addAll(ri.ingredient!.allergens);
      }
    }
    return allergens.toList()..sort();
  }

  /// Dietary classification based on allergens from ingredients.
  /// Note: meat (beef, pork, chicken) is not among the 14 allergens,
  /// so isVegetarian is approximate — only fish/crustaceans/molluscs are excluded.
  bool get isVegetarian {
    final a = allAllergens;
    return !a.contains('fish') && !a.contains('crustaceans') && !a.contains('molluscs');
  }

  bool get isVegan {
    return isVegetarian && !allAllergens.contains('milk') && !allAllergens.contains('eggs');
  }

  bool get isGlutenFree => !allAllergens.contains('gluten');
  bool get isDairyFree => !allAllergens.contains('milk');

  List<String> get dietaryLabels {
    final labels = <String>[];
    if (isVegan) {
      labels.add('Vegan');
    } else if (isVegetarian) {
      labels.add('Vegetarian');
    }
    if (isGlutenFree) labels.add('GF');
    if (isDairyFree) labels.add('DF');
    return labels;
  }
}

class Ingredient {
  final String id;
  final String name;
  final List<String> allergens;
  final String? businessId;

  Ingredient({
    required this.id,
    required this.name,
    this.allergens = const [],
    this.businessId,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      allergens: List<String>.from(json['allergens'] ?? []),
      businessId: json['business_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'allergens': allergens,
        'business_id': businessId,
      };
}

class RecipeIngredient {
  final String id;
  final String recipeId;
  final String ingredientId;
  final String? quantity;
  final String? unit;
  final String? notes;
  final Ingredient? ingredient;

  RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientId,
    this.quantity,
    this.unit,
    this.notes,
    this.ingredient,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      ingredientId: json['ingredient_id'] as String,
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      ingredient: json['ingredients'] != null
          ? Ingredient.fromJson(json['ingredients'] as Map<String, dynamic>)
          : null,
    );
  }
}
