import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/checklist_run.dart';
import '../models/checklist_template.dart';
import '../models/vessel.dart';
import '../services/report_service.dart';
import '../state/checklist_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/file_viewer.dart' show GridTableView;

/// In-app review of a completed form — the same grid that gets printed,
/// readable on screen before anyone downloads or signs it. English and
/// Arabic keep their own columns exactly as the paper form has them.
class ChecklistReportScreen extends StatefulWidget {
  final Vessel vessel;
  final ChecklistTemplate template;
  final String runId;

  const ChecklistReportScreen({
    super.key,
    required this.vessel,
    required this.template,
    required this.runId,
  });

  @override
  State<ChecklistReportScreen> createState() => _ChecklistReportScreenState();
}

class _ChecklistReportScreenState extends State<ChecklistReportScreen> {
  bool _busy = false;

  String _mark(SlotResult r) => switch (r) {
        SlotResult.done => '✓',
        SlotResult.notApplicable => 'N/A',
        SlotResult.failed => '✗',
        SlotResult.pending => '—',
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final runs =
        context.watch<ChecklistProvider>().forVessel(widget.vessel.id);
    final match = runs.where((r) => r.id == widget.runId);
    if (match.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final sheet = match.first;
    final template = widget.template;
    final slots = template.slotCount(sheet.year, sheet.month);
    final isYesNo = template.grid == ChecklistGrid.yesNo;

    final headers = <String>[
      t.checklistColNo,
      t.checklistColItem,
      'البند',
      if (isYesNo) ...[t.checklistScheduledDates, t.checklistColDate]
      else
        for (var s = 1; s <= slots; s++)
          template.grid == ChecklistGrid.weeksOfMonth
              ? t.checklistWeekShort(s)
              : '$s',
      if (isYesNo) t.checklistColYes,
      t.checklistRemarks,
    ];

    final rows = <List<String>>[
      for (final item in template.items)
        [
          '${item.no}',
          item.en,
          item.ar,
          if (isYesNo) ...[
            item.interval == ChecklistInterval.weekly
                ? t.checklistIntervalWeekly
                : t.checklistIntervalMonthly,
            sheet.dates[item.key] ?? '',
            _mark(sheet.resultFor(item.key, 0)),
          ] else
            for (var s = 0; s < slots; s++)
              _mark(sheet.resultFor(item.key, s)),
          sheet.remarks[item.key] ?? '',
        ]
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.reviewReport} — ${template.code}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  locale == 'ar' ? template.titleAr : template.titleEn,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Gaps.h4,
                Text(
                  '${widget.vessel.name} · '
                  '${DateFormat.yMMMM(locale).format(DateTime(sheet.year, sheet.month))}'
                  '${template.revNo.isEmpty ? '' : ' · Rev. ${template.revNo} (${template.revDate})'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.slate400),
                ),
                Gaps.h16,
                GridTableView(rows: [headers, ...rows]),
                Gaps.h16,
                if (sheet.isSubmitted)
                  Text(
                    t.checklistSubmittedOn(
                      DateFormat.yMMMd(locale).format(sheet.submittedAt!),
                      sheet.chiefEngineer,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.statusActive),
                  ),
                Gaps.h24,
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _download(t, sheet),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(t.exportFormatPdf),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(AppLocalizations t, ChecklistRun sheet) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ReportService.exportChecklistPdf(
        vesselName: widget.vessel.name,
        template: widget.template,
        run: sheet,
        monthLabel:
            DateFormat.MMMM(locale).format(DateTime(sheet.year, sheet.month)),
        labels: ChecklistPdfLabels(
          no: t.checklistColNo,
          item: t.checklistColItem,
          itemAr: 'البند',
          interval: t.checklistScheduledDates,
          date: t.checklistColDate,
          yes: t.checklistColYes,
          no2: t.checklistColNoMark,
          remarks: t.checklistRemarks,
          chiefEngineer: t.checklistChiefEngineer,
          vessel: t.vesselLabel,
          month: t.checklistMonthLabel,
          year: t.checklistYearLabel,
          intervalWeekly: t.checklistIntervalWeekly,
          intervalMonthly: t.checklistIntervalMonthly,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(t.fileSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.downloadFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
