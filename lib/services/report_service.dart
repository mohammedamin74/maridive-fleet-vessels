import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/daily_task.dart';
import '../models/defect.dart';
import '../models/handover_report.dart';
import '../models/tank.dart';
import '../models/vessel.dart';
import '../state/alert_thresholds.dart';
import '../state/tank_data_provider.dart';

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
                headers: s.headers,
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
            headers: tankHeaders,
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
            headers: taskHeaders,
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
            headers: defectHeaders,
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
