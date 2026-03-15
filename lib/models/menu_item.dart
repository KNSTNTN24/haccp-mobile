class MenuItem {
  final String id;
  final String recipeId;
  final String category;
  final bool active;
  final int displayOrder;
  final String businessId;

  MenuItem({
    required this.id,
    required this.recipeId,
    required this.category,
    this.active = true,
    this.displayOrder = 0,
    required this.businessId,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      category: json['category'] as String,
      active: json['active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      businessId: json['business_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'recipe_id': recipeId,
        'category': category,
        'active': active,
        'display_order': displayOrder,
        'business_id': businessId,
      };
}
