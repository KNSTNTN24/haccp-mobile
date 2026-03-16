import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../models/recipe.dart';
import 'diary_export.dart' show downloadFile;

Future<Uint8List> generateMenuPdf({
  required String businessName,
  required List<Recipe> recipes,
  bool includeAllergens = true,
}) async {
  final pdf = pw.Document();

  // Group by category
  final grouped = <RecipeCategory, List<Recipe>>{};
  for (final r in recipes) {
    grouped.putIfAbsent(r.category, () => []).add(r);
  }

  final categoryOrder = [
    RecipeCategory.starter,
    RecipeCategory.main,
    RecipeCategory.dessert,
    RecipeCategory.side,
    RecipeCategory.sauce,
    RecipeCategory.drink,
    RecipeCategory.other,
  ];

  final sortedEntries = categoryOrder
      .where((c) => grouped.containsKey(c))
      .map((c) => MapEntry(c, grouped[c]!))
      .toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Menu',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            businessName,
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Generated ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey500),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 8),
        ],
      ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            businessName,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
      build: (context) {
        final widgets = <pw.Widget>[];

        for (final entry in sortedEntries) {
          widgets.add(
            pw.Text(
              '${entry.key.displayName} (${entry.value.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));

          final headers = includeAllergens
              ? ['Dish', 'Dietary', 'Allergens']
              : ['Dish', 'Dietary'];

          final data = entry.value.map((r) {
            final row = [
              r.name,
              r.dietaryLabels.join(', '),
            ];
            if (includeAllergens) {
              row.add(r.allAllergens
                  .map((a) => a[0].toUpperCase() + a.substring(1))
                  .join(', '));
            }
            return row;
          }).toList();

          widgets.add(
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(5),
              headers: headers,
              data: data,
            ),
          );
          widgets.add(pw.SizedBox(height: 20));
        }

        // Summary
        widgets.add(pw.Divider());
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('Total dishes: ${recipes.length}', style: const pw.TextStyle(fontSize: 11)));

        final veganCount = recipes.where((r) => r.isVegan).length;
        final vegetarianCount = recipes.where((r) => r.isVegetarian && !r.isVegan).length;
        final gfCount = recipes.where((r) => r.isGlutenFree).length;
        final dfCount = recipes.where((r) => r.isDairyFree).length;

        widgets.add(pw.Text('Vegan: $veganCount', style: const pw.TextStyle(fontSize: 11)));
        widgets.add(pw.Text('Vegetarian: $vegetarianCount', style: const pw.TextStyle(fontSize: 11)));
        widgets.add(pw.Text('Gluten-Free: $gfCount', style: const pw.TextStyle(fontSize: 11)));
        widgets.add(pw.Text('Dairy-Free: $dfCount', style: const pw.TextStyle(fontSize: 11)));

        return widgets;
      },
    ),
  );

  return pdf.save();
}

String generateMenuCsv({
  required List<Recipe> recipes,
  bool includeAllergens = true,
}) {
  final rows = <List<String>>[];

  rows.add(['Menu Export']);
  rows.add(['Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}']);
  rows.add([]);

  if (includeAllergens) {
    rows.add(['Category', 'Name', 'Dietary', 'Allergens', 'Description']);
  } else {
    rows.add(['Category', 'Name', 'Dietary', 'Description']);
  }

  final categoryOrder = [
    RecipeCategory.starter,
    RecipeCategory.main,
    RecipeCategory.dessert,
    RecipeCategory.side,
    RecipeCategory.sauce,
    RecipeCategory.drink,
    RecipeCategory.other,
  ];

  for (final cat in categoryOrder) {
    final catRecipes = recipes.where((r) => r.category == cat).toList();
    for (final r in catRecipes) {
      if (includeAllergens) {
        rows.add([
          cat.displayName,
          r.name,
          r.dietaryLabels.join(', '),
          r.allAllergens.map((a) => a[0].toUpperCase() + a.substring(1)).join(', '),
          r.description ?? '',
        ]);
      } else {
        rows.add([
          cat.displayName,
          r.name,
          r.dietaryLabels.join(', '),
          r.description ?? '',
        ]);
      }
    }
  }

  return const ListToCsvConverter().convert(rows);
}
