import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/daily_task.dart';
import '../models/defect.dart';
import '../models/tank.dart';
import '../models/vessel.dart';
import '../state/alert_thresholds.dart';
import '../state/tank_data_provider.dart';

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

  static Future<void> exportVesselReport({
    required Vessel vessel,
    required TankDataProvider data,
  }) async {
    final doc = pw.Document();
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

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
              'Maridive Fleet Vessels — Daily Tank Status Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
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
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(vessel.type,
              style:
                  const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _infoBlock('IMO Number', vessel.imo),
              _infoBlock('Home Port', vessel.homePort),
              _infoBlock('Crew', '${vessel.crew}'),
              _infoBlock('Status', vessel.statusKey),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: [
              'Tank',
              'Category',
              'Current (m³)',
              'Capacity (m³)',
              'Level',
              'Status'
            ],
            data: rows,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
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
    await Printing.sharePdf(bytes: await doc.save(), filename: fileName);
  }

  static Future<void> exportDailyTasksReport({
    required Vessel vessel,
    required List<DailyTask> tasks,
  }) async {
    final doc = pw.Document();
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    final rows = tasks.map((task) {
      final checkedCount = task.checklistItems.where((c) => c.checked).length;
      final photoNames = task.photosBase64.isEmpty
          ? '—'
          : List.generate(task.photosBase64.length, (i) => 'Photo_${i + 1}.jpg')
              .join(', ');
      return [
        task.title,
        _taskCategoryLabel(task.category),
        _taskFrequencyLabel(task.frequency),
        dateFmt.format(task.scheduledTime),
        task.isOverdue ? 'Overdue' : _taskStatusLabel(task.status),
        '$checkedCount/${task.checklistItems.length}',
        photoNames,
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
              'Maridive Fleet Vessels — Daily Tasks Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
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
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(vessel.type,
              style:
                  const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: [
              'Task',
              'Category',
              'Frequency',
              'Scheduled',
              'Status',
              'Checklist',
              'Photos'
            ],
            data: rows,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
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
    await Printing.sharePdf(bytes: await doc.save(), filename: fileName);
  }

  static Future<void> exportDefectsReport({
    required Vessel vessel,
    required List<Defect> defects,
  }) async {
    final doc = pw.Document();
    final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final dateFmt = DateFormat('yyyy-MM-dd');

    final rows = defects.map((defect) {
      final photoNames = defect.photosBase64.isEmpty
          ? '—'
          : List.generate(
                  defect.photosBase64.length, (i) => 'Photo_${i + 1}.jpg')
              .join(', ');
      return [
        defect.title,
        _defectLocationLabel(defect.location),
        _defectPriorityLabel(defect.priority),
        _defectStatusLabel(defect.status),
        dateFmt.format(defect.reportedAt),
        photoNames,
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
              'Maridive Fleet Vessels — Defects Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
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
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(vessel.type,
              style:
                  const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: [
              'Defect',
              'Location',
              'Priority',
              'Status',
              'Reported',
              'Photos'
            ],
            data: rows,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
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
    await Printing.sharePdf(bytes: await doc.save(), filename: fileName);
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

  static pw.Widget _infoBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
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
