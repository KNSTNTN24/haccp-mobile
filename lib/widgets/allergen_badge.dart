import 'package:flutter/material.dart';

const _allergenColors = {
  'gluten': Color(0xFFF59E0B),
  'crustaceans': Color(0xFFEF4444),
  'eggs': Color(0xFFFBBF24),
  'fish': Color(0xFF3B82F6),
  'peanuts': Color(0xFF92400E),
  'soybeans': Color(0xFF84CC16),
  'milk': Color(0xFFE5E7EB),
  'nuts': Color(0xFFD97706),
  'celery': Color(0xFF22C55E),
  'mustard': Color(0xFFEAB308),
  'sesame': Color(0xFFA3A3A3),
  'sulphites': Color(0xFF8B5CF6),
  'lupin': Color(0xFFA855F7),
  'molluscs': Color(0xFF06B6D4),
};

const _allergenEmojis = {
  'gluten': '🌾',
  'crustaceans': '🦐',
  'eggs': '🥚',
  'fish': '🐟',
  'peanuts': '🥜',
  'soybeans': '🫘',
  'milk': '🥛',
  'nuts': '🌰',
  'celery': '🥬',
  'mustard': '🟡',
  'sesame': '⚪',
  'sulphites': '🟣',
  'lupin': '🌸',
  'molluscs': '🦑',
};

class AllergenBadge extends StatelessWidget {
  final String allergen;

  const AllergenBadge({super.key, required this.allergen});

  @override
  Widget build(BuildContext context) {
    final key = allergen.toLowerCase();
    final color = _allergenColors[key] ?? Colors.grey;
    final emoji = _allergenEmojis[key] ?? '⚠️';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$emoji ${allergen[0].toUpperCase()}${allergen.substring(1)}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withValues(alpha: 1.0)),
      ),
    );
  }
}
