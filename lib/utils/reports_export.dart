import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../config/supabase.dart';
import '../models/checklist.dart';

import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_mobile.dart';

class ReportCompletion {
  final ChecklistCompletion completion;
  final List<ReportResponseItem> items;

  ReportCompletion({required this.completion, required this.items});
}

class ReportResponseItem {
  final String itemName;
  final String itemType;
  final String value;
  final String? notes;
  final bool flagged;
  final double? minValue;
  final double? maxValue;
  final String? unit;

  ReportResponseItem({
    required this.itemName,
    required this.itemType,
    required this.value,
    this.notes,
    this.flagged = false,
    this.minValue,
    this.maxValue,
    this.unit,
  });
}

Future<List<ReportCompletion>> loadReportData({
  required String businessId,
  required DateTime fromDate,
  required DateTime toDate,
  required Set<String> templateIds,
}) async {
  final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
  final toNextStr = DateFormat('yyyy-MM-dd').format(toDate.add(const Duration(days: 1)));

  // Load completions with responses
  var query = SupabaseConfig.client
      .from('checklist_completions')
      .select('*, profiles:completed_by(full_name), signer:profiles!signed_off_by(full_name), checklist_templates!template_id(name, supervisor_role), checklist_responses(id, item_id, value, notes, flagged)')
      .eq('business_id', businessId)
      .gte('completed_at', '${fromStr}T00:00:00')
      .lt('completed_at', '${toNextStr}T00:00:00');

  if (templateIds.isNotEmpty) {
    query = query.inFilter('template_id', templateIds.toList());
  }

  final completionsData = await query.order('completed_at');

  // Load template items for all relevant templates
  final allTemplateIds = (completionsData as List)
      .map((c) => c['template_id'] as String)
      .toSet();

  if (allTemplateIds.isEmpty) return [];

  final itemsData = await SupabaseConfig.client
      .from('checklist_template_items')
      .select('id, template_id, name, item_type, min_value, max_value, unit, sort_order')
      .inFilter('template_id', allTemplateIds.toList())
      .order('sort_order');

  // Build item lookup: item_id -> item data
  final itemLookup = <String, Map<String, dynamic>>{};
  for (final item in itemsData as List) {
    itemLookup[item['id'] as String] = item;
  }

  final result = <ReportCompletion>[];
  for (final cData in completionsData) {
    final completion = ChecklistCompletion.fromJson(cData);
    final responses = (cData['checklist_responses'] as List?) ?? [];

    final items = <ReportResponseItem>[];
    for (final r in responses) {
      final itemInfo = itemLookup[r['item_id']];
      items.add(ReportResponseItem(
        itemName: itemInfo?['name'] as String? ?? 'Unknown',
        itemType: itemInfo?['item_type'] as String? ?? 'tick',
        value: r['value'] as String? ?? '',
        notes: r['notes'] as String?,
        flagged: r['flagged'] as bool? ?? false,
        minValue: (itemInfo?['min_value'] as num?)?.toDouble(),
        maxValue: (itemInfo?['max_value'] as num?)?.toDouble(),
        unit: itemInfo?['unit'] as String?,
      ));
    }

    // Sort by template item sort_order
    items.sort((a, b) => a.itemName.compareTo(b.itemName));

    result.add(ReportCompletion(completion: completion, items: items));
  }

  return result;
}

Future<Uint8List> generateReportPdf({
  required String businessName,
  required DateTime fromDate,
  required DateTime toDate,
  required List<ReportCompletion> completions,
}) async {
  final pdf = pw.Document();
  final dateFormat = DateFormat('dd MMM yyyy');
  final timeFormat = DateFormat('HH:mm');

  // Calculate summary
  final totalCompletions = completions.length;
  final totalItems = completions.fold<int>(0, (sum, c) => sum + c.items.length);
  final flaggedItems = completions.fold<int>(0, (sum, c) => sum + c.items.where((i) => i.flagged).length);
  final complianceRate = totalItems == 0 ? 100.0 : ((totalItems - flaggedItems) / totalItems * 100);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Compliance Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            businessName,
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '${dateFormat.format(fromDate)} — ${dateFormat.format(toDate)}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
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
            'Generated ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
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

        // Summary box
        widgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStat('Completions', '$totalCompletions'),
                _pdfStat('Total Items', '$totalItems'),
                _pdfStat('Flagged', '$flaggedItems', flaggedItems > 0 ? PdfColors.red : null),
                _pdfStat('Compliance', '${complianceRate.toStringAsFixed(1)}%',
                    complianceRate < 90 ? PdfColors.red : PdfColors.green800),
              ],
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 20));

        // Per-completion breakdown
        for (final rc in completions) {
          final c = rc.completion;

          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      c.templateName ?? 'Checklist',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Text(
                    '${dateFormat.format(c.completedAt)} ${timeFormat.format(c.completedAt)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    c.completedByName ?? '—',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );

          if (rc.items.isNotEmpty) {
            widgets.add(
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellPadding: const pw.EdgeInsets.all(4),
                headers: ['Item', 'Type', 'Value', 'Notes', 'Status'],
                data: rc.items.map((item) {
                  String valueDisplay = item.value;
                  if (item.itemType == 'temperature' && item.unit != null) {
                    valueDisplay = '${item.value} ${item.unit}';
                  }
                  return [
                    item.itemName,
                    _itemTypeLabel(item.itemType),
                    valueDisplay,
                    item.notes ?? '',
                    item.flagged ? 'FLAGGED' : 'OK',
                  ];
                }).toList(),
                cellAlignments: {4: pw.Alignment.center},
              ),
            );
          } else {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('No item responses recorded', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
              ),
            );
          }

          widgets.add(pw.SizedBox(height: 16));
        }

        if (completions.isEmpty) {
          widgets.add(
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text('No completions found for the selected period and checklists.',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ),
            ),
          );
        }

        return widgets;
      },
    ),
  );

  return pdf.save();
}

pw.Widget _pdfStat(String label, String value, [PdfColor? color]) {
  return pw.Column(
    children: [
      pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
      pw.SizedBox(height: 2),
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
    ],
  );
}

String _itemTypeLabel(String type) {
  switch (type) {
    case 'tick':
      return 'Tick';
    case 'temperature':
      return 'Temp';
    case 'text':
      return 'Text';
    case 'yes_no':
      return 'Y/N';
    case 'photo':
      return 'Photo';
    default:
      return type;
  }
}

Future<void> downloadReportFile(Uint8List bytes, String filename) async {
  await saveAndShareFile(bytes, filename);
}
