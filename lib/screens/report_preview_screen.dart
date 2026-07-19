import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/vessel.dart';
import '../services/report_service.dart';
import '../theme/app_colors.dart';
import '../widgets/file_viewer.dart' show GridTableView;
import 'export_report_screen.dart' show ExportFormat;

/// In-app review of a unified export before it leaves the app: the exact
/// section titles/headers/rows that would go into the PDF or CSV, rendered
/// as native tables — no file has to be generated just to see what's in it.
/// A download bar at the bottom still offers both formats directly from here.
class ReportPreviewScreen extends StatefulWidget {
  final Vessel vessel;
  final List<ReportSection> sections;
  const ReportPreviewScreen({
    super.key,
    required this.vessel,
    required this.sections,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  bool _busy = false;

  Future<void> _download(AppLocalizations t, ExportFormat format) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (format == ExportFormat.pdf) {
        await ReportService.exportUnifiedPdf(
            vessel: widget.vessel, sections: widget.sections);
      } else {
        await ReportService.exportUnifiedCsv(
            vessel: widget.vessel, sections: widget.sections);
      }
      messenger.showSnackBar(SnackBar(content: Text(t.fileSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.downloadFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final generatedAt = DateFormat.yMMMd(locale).add_Hm().format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text('${t.reviewReport} — ${widget.vessel.name}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(widget.vessel.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(widget.vessel.type,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('${t.generatedAtLabel}: $generatedAt',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.slate400)),
                const SizedBox(height: 20),
                for (final section in widget.sections) ...[
                  Text(section.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (section.rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(t.reportNoEntries,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.slate400)),
                    )
                  else
                    GridTableView(rows: [section.headers, ...section.rows]),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _download(t, ExportFormat.csv),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: Text(t.exportFormatCsv),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _download(t, ExportFormat.pdf),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(t.exportFormatPdf),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
