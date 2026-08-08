import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/checklist_run.dart';
import '../models/checklist_template.dart';
import '../models/daily_task.dart';
import '../models/defect.dart';
import '../models/handover_report.dart';
import '../models/tank.dart';
import '../models/vessel.dart';
import '../state/alert_thresholds.dart';
import '../state/tank_data_provider.dart';

/// Column headings and fixed words for a printed checklist form. Passed in
/// by the screen so the PDF follows the reader's language while this service
/// stays free of any dependency on the widget tree.
class ChecklistPdfLabels {
  final String no;
  final String item;
  final String itemAr;
  final String interval;
  final String date;
  final String yes;
  final String no2;
  final String remarks;
  final String chiefEngineer;
  final String vessel;
  final String month;
  final String year;
  final String intervalWeekly;
  final String intervalMonthly;

  const ChecklistPdfLabels({
    required this.no,
    required this.item,
    required this.itemAr,
    required this.interval,
    required this.date,
    required this.yes,
    required this.no2,
    required this.remarks,
    required this.chiefEngineer,
    required this.vessel,
    required this.month,
    required this.year,
    this.intervalWeekly = 'Weekly',
    this.intervalMonthly = 'Monthly',
  });
}

/// One titled table within a unified report (Request 7). Any module maps its
/// records to [headers] + [rows]; the report renders a section per entry.
class ReportSection {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  const ReportSection(this.title, this.headers, this.rows);
}

/// Generates and shares a per-vessel daily tank status PDF report.
/// Report content is always rendered in English regardless of the app's
/// active locale — the `pdf` package doesn't shape Arabic text/ligatures
/// without a dedicated font + RTL layout pass, which is out of scope here.
class ReportService {
  ReportService._();

  static const _categoryLabels = {
    TankCategory.fuelOil: 'Fuel Oil',
    TankCategory.brineMud: 'Brine / Mud',
    TankCategory.lubeHydraulic: 'Lube & Hydraulic Oil',
    TankCategory.other: 'Other',
  };

  // Bundled Arabic font so Arabic vessel names / notes render in exports
  // instead of showing empty boxes. Loaded once and cached.
  static pw.Font? _arabicFont;
  static final RegExp _arabicScript =
      RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');

  /// The pdf package only runs the bidirectional algorithm — which both
  /// reorders right-to-left runs and joins Arabic letters into their cursive
  /// forms — when a text is explicitly marked right-to-left. Left at the
  /// default, Arabic prints in logical order with unjoined letters: the
  /// characters are all there but no Arabic reader would accept it.
  ///
  /// Direction is decided per string so one document can mix English and
  /// Arabic and have each come out correct.
  /// [arabicFont] must be passed as the *primary* font for Arabic strings,
  /// not merely as a fallback: with a Latin base font the package resolves
  /// glyphs character by character, which defeats the cursive joining and
  /// prints every letter in its isolated form.
  static pw.Widget bidiText(String value,
      {pw.TextStyle? style, pw.TextAlign? align, pw.Font? arabicFont}) {
    final rtl = _arabicScript.hasMatch(value);
    final resolved = rtl && arabicFont != null
        ? (style ?? const pw.TextStyle()).copyWith(font: arabicFont)
        : style;
    return pw.Text(
      value,
      style: resolved,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      textAlign: align ?? (rtl ? pw.TextAlign.right : pw.TextAlign.left),
    );
  }

  /// Header cells are built individually rather than given one row-wide
  /// direction: a bilingual form has English and Arabic headings side by
  /// side, and forcing the whole row right-to-left mangles the English ones.
  static List<pw.Widget> _headerCells(
          List<String> headers, List<pw.Font> fallback, pw.Font? arabicFont) =>
      [
        for (final h in headers)
          pw.Center(
            child: bidiText(
              h,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white,
                  fontFallback: fallback),
              align: pw.TextAlign.center,
              arabicFont: arabicFont,
            ),
          )
      ];

  /// Cell renderer applying [bidiText] to every table cell, so Arabic record
  /// text (defect titles, checklist items, crew names) prints correctly in
  /// each module's report.
  static pw.Widget? Function(int, dynamic, int) _arabicAwareCell(
          pw.TextStyle style, pw.Font? arabicFont) =>
      (index, data, rowNum) => bidiText(data?.toString() ?? '',
          style: style, arabicFont: arabicFont);

  static Future<pw.Font?> _loadArabic() async {
    if (_arabicFont != null) return _arabicFont;
    try {
      _arabicFont = pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'));
    } catch (_) {
      // Font asset missing — fall back to Latin-only rendering.
    }
    return _arabicFont;
  }

  /// Unified multi-module PDF (Request 7): one section per [sections] entry,
  /// each a titled table, in a single document with one action.
  static Future<void> exportUnifiedPdf({
    required Vessel vessel,
    required List<ReportSection> sections,
  }) async {
    final arabic = await _loadArabic();
    final fallback = arabic != null ? [arabic] : <pw.Font>[];
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Maridive Fleet Vessels - Fleet Report',
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: fallback)),
            pw.SizedBox(height: 2),
            pw.Text('Generated: $generatedAt',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Text(vessel.name,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: fallback)),
          pw.SizedBox(height: 2),
          pw.Text(vessel.type,
              style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                  fontFallback: fallback)),
          pw.SizedBox(height: 16),
          for (final s in sections) ...[
            pw.Text(s.title,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: fallback)),
            pw.SizedBox(height: 6),
            if (s.rows.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('No entries',
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                        fontFallback: fallback)),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: _headerCells(s.headers, fallback, arabic),
                data: s.rows,
                columnWidths: _columnWidths(s.headers, s.rows),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8.5,
                    color: PdfColors.white,
                    fontFallback: fallback),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle:
                    pw.TextStyle(fontSize: 8, fontFallback: fallback),
            cellBuilder: _arabicAwareCell(pw.TextStyle(fontSize: 8, fontFallback: fallback), arabic),
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              ),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    final fileName = '${vessel.name.replaceAll(' ', '_')}_Fleet_Report.pdf';
    await _savePdf(await doc.save(), fileName);
  }

  /// Unified multi-module CSV (Request 7): section blocks separated by a blank
  /// line, saved to the device. A UTF-8 BOM is prepended so Excel renders
  /// Arabic correctly.
  static Future<void> exportUnifiedCsv({
    required Vessel vessel,
    required List<ReportSection> sections,
  }) async {
    final buf = StringBuffer();
    for (final s in sections) {
      buf.writeln(_csvRow([s.title]));
      buf.writeln(_csvRow(s.headers));
      for (final r in s.rows) {
        buf.writeln(_csvRow(r));
      }
      buf.writeln();
    }
    final bytes = Uint8List.fromList(
        [0xEF, 0xBB, 0xBF, ...utf8.encode(buf.toString())]);
    await FileSaver.instance.saveAs(
      name: '${vessel.name.replaceAll(' ', '_')}_Fleet_Report',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  /// Column headings and fixed words for [exportChecklistPdf], passed in so
  /// the printed form follows the reader's language without this service
  /// depending on the widget tree.
  static Future<Uint8List?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/branding/mos-logo.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// A controlled engine-department form, reproduced as the office prints it:
  /// MOS logo and form code in the header, the numbered bilingual item table,
  /// real ticked boxes, and the Chief Engineer signature block.
  ///
  /// The on-screen sheet is a list because 31 day-columns don't fit a phone;
  /// this is where the full printed grid is restored.
  static Future<void> exportChecklistPdf({
    required String vesselName,
    required ChecklistTemplate template,
    required ChecklistRun run,
    required String monthLabel,
    required ChecklistPdfLabels labels,
  }) async {
    final arabic = await _loadArabic();
    final fallback = arabic != null ? [arabic] : <pw.Font>[];
    final logoBytes = await _loadLogo();
    final logo = logoBytes == null ? null : pw.MemoryImage(logoBytes);
    final slots = template.slotCount(run.year, run.month);
    final doc = pw.Document();

    String mark(SlotResult r) => switch (r) {
          SlotResult.done => '[X]',
          SlotResult.notApplicable => 'N/A',
          SlotResult.failed => '[!]',
          SlotResult.pending => '[  ]',
        };

    final isYesNo = template.grid == ChecklistGrid.yesNo;
    // English and Arabic get their own columns, exactly as the paper form
    // does. Besides matching the original, it keeps each cell single-script,
    // which is what makes the bidi pass reliable.
    final headers = <String>[
      labels.no,
      labels.item,
      labels.itemAr,
      if (isYesNo) ...[labels.interval, labels.date, labels.yes, labels.no2]
      else
        for (var s = 1; s <= slots; s++) '$s',
      labels.remarks,
    ];

    final rows = <List<String>>[
      for (final item in template.items)
        [
          '${item.no}',
          item.en,
          item.ar,
          if (isYesNo) ...[
            item.interval == ChecklistInterval.weekly
                ? labels.intervalWeekly
                : labels.intervalMonthly,
            run.dates[item.key] ?? '',
            run.resultFor(item.key, 0) == SlotResult.done ? '[X]' : '[  ]',
            run.resultFor(item.key, 0) == SlotResult.failed ? '[X]' : '[  ]',
          ] else
            for (var s = 0; s < slots; s++) mark(run.resultFor(item.key, s)),
          run.remarks[item.key] ?? '',
        ]
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat:
            isYesNo ? PdfPageFormat.a4 : PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                      width: 46, height: 46, child: pw.Image(logo)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(template.titleEn,
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              fontFallback: fallback)),
                      bidiText(template.titleAr,
                          style: pw.TextStyle(
                              fontSize: 11, font: arabic, fontFallback: fallback),
                          arabicFont: arabic),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (template.revNo.isNotEmpty)
                      pw.Text('Rev. No. ${template.revNo}',
                          style: const pw.TextStyle(fontSize: 8)),
                    if (template.revDate.isNotEmpty)
                      pw.Text('Rev. Date ${template.revDate}',
                          style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(template.code,
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(children: [
              pw.Text('${labels.vessel}: ',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(vesselName,
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 18),
              pw.Text('${labels.month}: $monthLabel   ${labels.year}: ${run.year}',
                  style: const pw.TextStyle(fontSize: 9)),
            ]),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: _headerCells(headers, fallback, arabic),
            data: rows,
            columnWidths: {
              0: const pw.FlexColumnWidth(0.7),
              1: pw.FlexColumnWidth(isYesNo ? 5 : 4),
              2: pw.FlexColumnWidth(isYesNo ? 4 : 3),
            },
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 7.5,
                color: PdfColors.white,
                fontFallback: fallback),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: pw.TextStyle(fontSize: 7, fontFallback: fallback),
            cellBuilder: _arabicAwareCell(pw.TextStyle(fontSize: 7, fontFallback: fallback), arabic),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(vesselName,
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('${labels.chiefEngineer}: ${run.chiefEngineer}',
                  style: pw.TextStyle(fontSize: 9, fontFallback: fallback)),
              pw.Text(
                  'Date: ${run.submittedAt == null ? '' : DateFormat('dd/MM/yyyy').format(run.submittedAt!)}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),
    );

    await _savePdf(await doc.save(),
        '${template.code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}_${run.year}_${run.month}.pdf');
  }

  /// Superintendent Daily Briefing: titled sections of plain bullet lines
  /// rather than tables, because a briefing is read top-to-bottom. An
  /// optional [aiSummary] is printed under an explicit AI heading so a
  /// generated narrative is never mistaken for a recorded fact.
  static Future<void> exportBriefingPdf({
    required String title,
    required String generatedLabel,
    required List<(String, List<String>)> sections,
    String? aiSummary,
    String? aiHeading,
  }) async {
    final arabic = await _loadArabic();
    final fallback = arabic != null ? [arabic] : <pw.Font>[];
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Maridive Fleet Vessels - $title',
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: fallback)),
            pw.SizedBox(height: 2),
            pw.Text('$generatedLabel: $generatedAt',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          for (final section in sections) ...[
            pw.Text(section.$1,
                style: pw.TextStyle(
                    fontSize: 12.5,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: fallback)),
            pw.SizedBox(height: 5),
            for (final line in section.$2)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3, left: 8),
                child: pw.Text('- $line',
                    style: pw.TextStyle(fontSize: 9, fontFallback: fallback)),
              ),
            pw.SizedBox(height: 14),
          ],
          if (aiSummary != null && aiSummary.trim().isNotEmpty) ...[
            pw.Divider(),
            pw.Text(aiHeading ?? 'AI Recommendation - Human Review Required',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800,
                    fontFallback: fallback)),
            pw.SizedBox(height: 5),
            pw.Text(aiSummary,
                style: pw.TextStyle(fontSize: 9, fontFallback: fallback)),
          ],
        ],
      ),
    );

    await _savePdf(await doc.save(), 'Daily_Briefing.pdf');
  }

  /// Fleet-level Cash Meeting Sheet PDF: no vessel header — the sheet spans
  /// all vessels. One titled table per section (not approved / approved /
  /// per-currency totals), matching the in-app report preview exactly.
  static Future<void> exportCashMeetingPdf({
    required List<ReportSection> sections,
  }) async {
    final arabic = await _loadArabic();
    final fallback = arabic != null ? [arabic] : <pw.Font>[];
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Maridive Fleet Vessels - Cash Meeting Sheet',
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: fallback)),
            pw.SizedBox(height: 2),
            pw.Text('Generated: $generatedAt',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          for (final s in sections) ...[
            pw.Text(s.title,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: fallback)),
            pw.SizedBox(height: 6),
            if (s.rows.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('No entries',
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                        fontFallback: fallback)),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: _headerCells(s.headers, fallback, arabic),
                data: s.rows,
                columnWidths: _columnWidths(s.headers, s.rows),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8.5,
                    color: PdfColors.white,
                    fontFallback: fallback),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle:
                    pw.TextStyle(fontSize: 8, fontFallback: fallback),
            cellBuilder: _arabicAwareCell(pw.TextStyle(fontSize: 8, fontFallback: fallback), arabic),
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              ),
            pw.SizedBox(height: 16),
          ],
        ],
      ),
    );

    await _savePdf(await doc.save(), 'Cash_Meeting_Sheet.pdf');
  }

  /// Fleet-level Cash Meeting Sheet CSV, same sections as the PDF.
  static Future<void> exportCashMeetingCsv({
    required List<ReportSection> sections,
  }) async {
    final buf = StringBuffer();
    for (final s in sections) {
      buf.writeln(_csvRow([s.title]));
      buf.writeln(_csvRow(s.headers));
      for (final r in s.rows) {
        buf.writeln(_csvRow(r));
      }
      buf.writeln();
    }
    final bytes = Uint8List.fromList(
        [0xEF, 0xBB, 0xBF, ...utf8.encode(buf.toString())]);
    await FileSaver.instance.saveAs(
      name: 'Cash_Meeting_Sheet',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  // Table.layout() sizes unconstrained (IntrinsicColumnWidth) columns by
  // splitting page width in proportion to each column's longest unwrapped
  // line. One free-text column (a title/description) can be many times
  // wider than a "Status" or date column, which starves the short columns
  // down to a sliver — cellPadding alone can exceed the space left, forcing
  // a character-per-line wrap. Columns whose longest value is short get a
  // fixed width sized to that content instead; only genuinely long-text
  // columns share the remaining space via flex.
  static const _narrowCharLimit = 16;
  static const _narrowCharWidth = 4.6;
  static const _narrowMinWidth = 42.0;
  static const _narrowMaxWidth = 110.0;

  static Map<int, pw.TableColumnWidth> _columnWidths(
      List<String> headers, List<List<String>> rows) {
    final widths = <int, pw.TableColumnWidth>{};
    for (var i = 0; i < headers.length; i++) {
      var maxLen = headers[i].length;
      for (final row in rows) {
        if (i < row.length && row[i].length > maxLen) maxLen = row[i].length;
      }
      widths[i] = maxLen <= _narrowCharLimit
          ? pw.FixedColumnWidth((maxLen * _narrowCharWidth + 14)
              .clamp(_narrowMinWidth, _narrowMaxWidth))
          : pw.FlexColumnWidth(maxLen.toDouble());
    }
    return widths;
  }

  /// Opens the native Save As dialog so the user picks the destination
  /// (Downloads, Desktop, or any other folder) instead of the file always
  /// landing in a fixed location.
  static Future<void> _savePdf(Uint8List bytes, String fileNameWithExt) async {
    final name = fileNameWithExt.endsWith('.pdf')
        ? fileNameWithExt.substring(0, fileNameWithExt.length - 4)
        : fileNameWithExt;
    await FileSaver.instance.saveAs(
      name: name,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static String _csvRow(List<String> fields) => fields.map((f) {
        final needsQuote =
            f.contains(',') || f.contains('"') || f.contains('\n');
        final escaped = f.replaceAll('"', '""');
        return needsQuote ? '"$escaped"' : escaped;
      }).join(',');

  static Future<void> exportVesselReport({
    required Vessel vessel,
    required TankDataProvider data,
  }) async {
    final arabic = await _loadArabic();
    final fallback = arabic != null ? [arabic] : <pw.Font>[];
    final doc = pw.Document();
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    const tankHeaders = [
      'Tank',
      'Category',
      'Current (m³)',
      'Capacity (m³)',
      'Level',
      'Status'
    ];

    final rows = vessel.tanks.map((tank) {
      final current = data.currentLevel(vessel.id, tank.id);
      final percent = data.percentFor(vessel.id, tank);
      final hasReading = data.hasReading(vessel.id, tank.id);
      final status = levelStatusFor(hasReading: hasReading, percent: percent);
      return [
        tank.name,
        _categoryLabels[tank.category] ?? '',
        current.toStringAsFixed(1),
        tank.capacityM3.toStringAsFixed(1),
        '${(percent * 100).round()}%',
        _statusLabel(status),
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Maridive Fleet Vessels - Daily Tank Status Report',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: fallback),
            ),
            pw.SizedBox(height: 2),
            pw.Text('Generated: $generatedAt',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Text(vessel.name,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: fallback)),
          pw.SizedBox(height: 2),
          pw.Text(vessel.type,
              style: pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey700, fontFallback: fallback)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _infoBlock('IMO Number', vessel.imo, fallback),
              _infoBlock('Home Port', vessel.homePort, fallback),
              _infoBlock('Crew', '${vessel.crew}', fallback),
              _infoBlock('Status', vessel.statusKey, fallback),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: _headerCells(tankHeaders, fallback, arabic),
            data: rows,
            columnWidths: _columnWidths(tankHeaders, rows),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
                fontFallback: fallback),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: pw.TextStyle(fontSize: 8.5, fontFallback: fallback),
            cellBuilder: _arabicAwareCell(pw.TextStyle(fontSize: 8.5, fontFallback: fallback), arabic),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerLeft,
            },
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ],
      ),
    );

    final fileName = '${vessel.name.replaceAll(' ', '_')}_Tank_Report.pdf';
    await _savePdf(await doc.save(), fileName);
  }

  static Future<void> exportDailyTasksReport({
    required Vessel vessel,
    required List<DailyTask> tasks,
  }) async {
    final arabic = await _loadArabic();
    final fallback = arabic != null ? [arabic] : <pw.Font>[];
    final doc = pw.Document();
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    const taskHeaders = [
      'Task',
      'Category',
      'Frequency',
      'Scheduled',
      'Status',
      'Checklist',
      'Files'
    ];

    final rows = tasks.map((task) {
      final checkedCount = task.checklistItems.where((c) => c.checked).length;
      final fileNames = task.attachments.isEmpty
          ? '-'
          : task.attachments.map((a) => a.name).join(', ');
      return [
        task.title,
        _taskCategoryLabel(task.category),
        _taskFrequencyLabel(task.frequency),
        dateFmt.format(task.scheduledTime),
        task.isOverdue ? 'Overdue' : _taskStatusLabel(task.status),
        '$checkedCount/${task.checklistItems.length}',
        fileNames,
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Maridive Fleet Vessels - Daily Tasks Report',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: fallback),
            ),
            pw.SizedBox(height: 2),
            pw.Text('Generated: $generatedAt',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Text(vessel.name,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: fallback)),
          pw.SizedBox(height: 2),
          pw.Text(vessel.type,
              style: pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey700, fontFallback: fallback)),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: _headerCells(taskHeaders, fallback, arabic),
            data: rows,
            columnWidths: _columnWidths(taskHeaders, rows),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
                fontFallback: fallback),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: pw.TextStyle(fontSize: 8, fontFallback: fallback),
            cellBuilder: _arabicAwareCell(pw.TextStyle(fontSize: 8, fontFallback: fallback), arabic),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerLeft,
            },
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          ),
        ],
      ),
    );

    final fileName =
        '${vessel.name.replaceAll(' ', '_')}_Daily_Tasks_Report.pdf';
    await _savePdf(await doc.save(), fileName);
  }

  static Future<void> exportDefectsReport({
    required Vessel vessel,
    required List<Defect> defects,
  }) async {
    final arabic = await _loadArabic();
    final fallback = arabic != null ? [arabic] : <pw.Font>[];
    final doc = pw.Document();
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final dateFmt = DateFormat('yyyy-MM-dd');
    const defectHeaders = [
      'Defect',
      'Location',
      'Priority',
      'Status',
      'Reported',
      'Files'
    ];

    final rows = defects.map((defect) {
      final fileNames = defect.attachments.isEmpty
          ? '-'
          : defect.attachments.map((a) => a.name).join(', ');
      return [
        defect.title,
        _defectLocationLabel(defect.location),
        _defectPriorityLabel(defect.priority),
        _defectStatusLabel(defect.status),
        dateFmt.format(defect.reportedAt),
        fileNames,
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Maridive Fleet Vessels - Defects Report',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: fallback),
            ),
            pw.SizedBox(height: 2),
            pw.Text('Generated: $generatedAt',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Text(vessel.name,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: fallback)),
          pw.SizedBox(height: 2),
          pw.Text(vessel.type,
              style: pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey700, fontFallback: fallback)),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: _headerCells(defectHeaders, fallback, arabic),
            data: rows,
            columnWidths: _columnWidths(defectHeaders, rows),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
                fontFallback: fallback),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: pw.TextStyle(fontSize: 8.5, fontFallback: fallback),
            cellBuilder: _arabicAwareCell(pw.TextStyle(fontSize: 8.5, fontFallback: fallback), arabic),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerLeft,
            },
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ],
      ),
    );

    final fileName = '${vessel.name.replaceAll(' ', '_')}_Defects_Report.pdf';
    await _savePdf(await doc.save(), fileName);
  }

  static String _defectLocationLabel(DefectLocation l) {
    switch (l) {
      case DefectLocation.engineRoom:
        return 'Engine Room';
      case DefectLocation.deck:
        return 'Deck';
      case DefectLocation.bridge:
        return 'Bridge';
      case DefectLocation.accommodation:
        return 'Accommodation';
      case DefectLocation.galley:
        return 'Galley';
      case DefectLocation.other:
        return 'Other';
    }
  }

  static String _defectPriorityLabel(DefectPriority p) {
    switch (p) {
      case DefectPriority.low:
        return 'Low';
      case DefectPriority.medium:
        return 'Medium';
      case DefectPriority.high:
        return 'High';
      case DefectPriority.critical:
        return 'Critical';
    }
  }

  static String _defectStatusLabel(DefectStatus s) {
    switch (s) {
      case DefectStatus.open:
        return 'Open';
      case DefectStatus.inProgress:
        return 'In Progress';
      case DefectStatus.closed:
        return 'Closed';
    }
  }

  static String _taskCategoryLabel(TaskCategory c) {
    switch (c) {
      case TaskCategory.engineRoomRounds:
        return 'Engine Room Rounds';
      case TaskCategory.deckRounds:
        return 'Deck Rounds';
      case TaskCategory.safetyEquipmentChecks:
        return 'Safety Equipment Checks';
      case TaskCategory.navigationEquipmentTests:
        return 'Navigation Equipment Tests';
      case TaskCategory.galleyHygieneInspections:
        return 'Galley Hygiene Inspections';
    }
  }

  static String _taskFrequencyLabel(TaskFrequency f) {
    switch (f) {
      case TaskFrequency.daily:
        return 'Daily';
      case TaskFrequency.everyWatch:
        return 'Every Watch';
      case TaskFrequency.weekly:
        return 'Weekly';
    }
  }

  static String _taskStatusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  /// Formal one-document PDF of a crew handover report: header block with the
  /// two officers and date, one titled paragraph per section, and signature
  /// lines for outgoing/incoming officers at the end.
  static Future<void> exportHandoverReport({
    required Vessel vessel,
    required HandoverReport report,
  }) async {
    final arabic = await _loadArabic();
    final fallback = arabic != null ? [arabic] : <pw.Font>[];
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final handoverDate = DateFormat('yyyy-MM-dd').format(report.handoverDate);
    final doc = pw.Document();

    final sections = <(String, String)>[
      ('Safety', report.safety),
      ('Machinery & Equipment', report.machinery),
      ('Pending Defects', report.pendingDefects),
      ('Bunkers & Tanks', report.bunkersAndTanks),
      ('Certificates Expiring', report.certificatesExpiring),
      ('Remarks', report.remarks),
    ];

    pw.Widget signatureLine(String role, String name) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
                width: 180, height: 0.8, color: PdfColors.grey800),
            pw.SizedBox(height: 4),
            pw.Text(name,
                style: pw.TextStyle(fontSize: 10, fontFallback: fallback)),
            pw.Text(role,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Maridive Fleet Vessels - Crew Handover Report',
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: fallback)),
            pw.SizedBox(height: 2),
            pw.Text('Generated: $generatedAt',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Text(vessel.name,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: fallback)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _infoBlock('Outgoing Officer', report.outgoingOfficer, fallback),
              _infoBlock('Incoming Officer', report.incomingOfficer, fallback),
              _infoBlock('Rank', report.rank, fallback),
              _infoBlock('Handover Date', handoverDate, fallback),
              _infoBlock('Status', report.status.name.toUpperCase(), fallback),
            ],
          ),
          pw.SizedBox(height: 16),
          for (final (title, body) in sections) ...[
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: fallback)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.4),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(body.isEmpty ? '-' : body,
                  style: pw.TextStyle(fontSize: 9.5, fontFallback: fallback)),
            ),
            pw.SizedBox(height: 10),
          ],
          pw.SizedBox(height: 22),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              signatureLine('Outgoing Officer', report.outgoingOfficer),
              signatureLine(
                  'Incoming Officer',
                  report.acknowledgedBy.isNotEmpty
                      ? report.acknowledgedBy
                      : report.incomingOfficer),
            ],
          ),
        ],
      ),
    );

    final fileName =
        '${vessel.name.replaceAll(' ', '_')}_Handover_$handoverDate.pdf';
    await _savePdf(await doc.save(), fileName);
  }

  static pw.Widget _infoBlock(
      String label, String value, List<pw.Font> fontFallback) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                fontFallback: fontFallback)),
      ],
    );
  }

  static String _statusLabel(TankLevelStatus status) {
    switch (status) {
      case TankLevelStatus.critical:
        return 'Critical (Low)';
      case TankLevelStatus.warning:
        return 'Warning (Low)';
      case TankLevelStatus.highCritical:
        return 'Critical (Overfill)';
      case TankLevelStatus.highWarning:
        return 'Warning (Overfill)';
      case TankLevelStatus.normal:
        return 'Normal';
      case TankLevelStatus.noData:
        return 'No Data';
    }
  }
}
