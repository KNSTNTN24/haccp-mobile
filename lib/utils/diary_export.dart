import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../config/supabase.dart';
import '../models/checklist.dart';
import '../models/incident.dart';

import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_mobile.dart';

class DiaryReportData {
  final List<ChecklistCompletion> checklists;
  final List<Incident> incidents;
  DiaryReportData({required this.checklists, required this.incidents});
}

Future<DiaryReportData> loadDiaryReportData({
  required String businessId,
  required DateTime fromDate,
  required DateTime toDate,
  required bool includeChecklists,
  required bool includeIncidents,
}) async {
  List<ChecklistCompletion> checklists = [];
  List<Incident> incidents = [];

  final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
  final toNextStr = DateFormat('yyyy-MM-dd').format(toDate.add(const Duration(days: 1)));

  if (includeChecklists) {
    final response = await SupabaseConfig.client
        .from('checklist_completions')
        .select('*, profiles:completed_by(full_name), signer:profiles!signed_off_by(full_name), checklist_templates!template_id(name, supervisor_role)')
        .eq('business_id', businessId)
        .gte('completed_at', '${fromStr}T00:00:00')
        .lt('completed_at', '${toNextStr}T00:00:00')
        .order('completed_at');

    checklists = (response as List)
        .map((e) => ChecklistCompletion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  if (includeIncidents) {
    final response = await SupabaseConfig.client
        .from('incidents')
        .select('*, profiles:reported_by(full_name)')
        .eq('business_id', businessId)
        .gte('date', fromStr)
        .lte('date', DateFormat('yyyy-MM-dd').format(toDate))
        .order('date');

    incidents = (response as List)
        .map((e) => Incident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  return DiaryReportData(checklists: checklists, incidents: incidents);
}

Future<Uint8List> generateDiaryPdf({
  required String businessName,
  required DateTime fromDate,
  required DateTime toDate,
  required List<ChecklistCompletion> checklists,
  required List<Incident> incidents,
}) async {
  final pdf = pw.Document();
  final dateFormat = DateFormat('dd MMM yyyy');
  final timeFormat = DateFormat('HH:mm');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Daily Diary Report',
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

        if (checklists.isNotEmpty) {
          widgets.add(
            pw.Text(
              'Checklists (${checklists.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(5),
              headers: ['Date', 'Checklist', 'Completed By', 'Time', 'Status'],
              data: checklists.map((c) => [
                dateFormat.format(c.completedAt),
                c.templateName ?? '—',
                c.completedByName ?? '—',
                timeFormat.format(c.completedAt),
                c.displayStatus,
              ]).toList(),
            ),
          );
          widgets.add(pw.SizedBox(height: 20));
        }

        if (incidents.isNotEmpty) {
          widgets.add(
            pw.Text(
              'Incidents (${incidents.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(5),
              headers: ['Date', 'Type', 'Description', 'Reported By', 'Status', 'Action Taken'],
              data: incidents.map((i) => [
                i.date,
                i.type == 'complaint' ? 'Complaint' : 'Incident',
                i.description.length > 60 ? '${i.description.substring(0, 60)}...' : i.description,
                i.reportedByName ?? '—',
                i.isResolved ? 'Resolved' : 'Open',
                i.actionTaken ?? '—',
              ]).toList(),
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
        widgets.add(pw.Text('Total checklists completed: ${checklists.length}', style: const pw.TextStyle(fontSize: 11)));
        widgets.add(pw.Text('Total incidents reported: ${incidents.length}', style: const pw.TextStyle(fontSize: 11)));

        final openIncidents = incidents.where((i) => !i.isResolved).length;
        if (openIncidents > 0) {
          widgets.add(pw.Text('Open incidents: $openIncidents', style: pw.TextStyle(fontSize: 11, color: PdfColors.red)));
        }

        return widgets;
      },
    ),
  );

  return pdf.save();
}

String generateDiaryCsv({
  required DateTime fromDate,
  required DateTime toDate,
  required List<ChecklistCompletion> checklists,
  required List<Incident> incidents,
}) {
  final rows = <List<String>>[];
  final dateFormat = DateFormat('dd MMM yyyy');
  final timeFormat = DateFormat('HH:mm');

  rows.add(['Daily Diary Report']);
  rows.add(['Period: ${dateFormat.format(fromDate)} — ${dateFormat.format(toDate)}']);
  rows.add([]);

  if (checklists.isNotEmpty) {
    rows.add(['CHECKLISTS']);
    rows.add(['Date', 'Checklist', 'Completed By', 'Time', 'Sign-off Status']);
    for (final c in checklists) {
      rows.add([
        dateFormat.format(c.completedAt),
        c.templateName ?? '',
        c.completedByName ?? '',
        timeFormat.format(c.completedAt),
        c.displayStatus,
      ]);
    }
    rows.add([]);
  }

  if (incidents.isNotEmpty) {
    rows.add(['INCIDENTS']);
    rows.add(['Date', 'Type', 'Description', 'Reported By', 'Status', 'Action Taken']);
    for (final i in incidents) {
      rows.add([
        i.date,
        i.type == 'complaint' ? 'Complaint' : 'Incident',
        i.description,
        i.reportedByName ?? '',
        i.isResolved ? 'Resolved' : 'Open',
        i.actionTaken ?? '',
      ]);
    }
  }

  return const ListToCsvConverter().convert(rows);
}

Future<void> downloadFile(Uint8List bytes, String filename) async {
  await saveAndShareFile(bytes, filename);
}
