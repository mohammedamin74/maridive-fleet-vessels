import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/fleet_data.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/cash_item.dart';
import '../services/report_service.dart';
import '../state/cash_meeting_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/file_viewer.dart' show GridTableView;

/// In-app review of the full cash meeting sheet — every purchase line across
/// all vessels, grouped into not-approved / approved plus per-currency
/// totals — with PDF and CSV download of exactly what is shown. This is the
/// document the office brings to (or files after) the cash meeting.
class CashMeetingReportScreen extends StatefulWidget {
  const CashMeetingReportScreen({super.key});

  @override
  State<CashMeetingReportScreen> createState() =>
      _CashMeetingReportScreenState();
}

class _CashMeetingReportScreenState extends State<CashMeetingReportScreen> {
  bool _busy = false;
  static final _money = NumberFormat('#,##0.00');

  List<ReportSection> _buildSections(
      AppLocalizations t, CashMeetingProvider provider) {
    final vesselNames = {
      for (final v in FleetData.vessels)
        v.id: v.name.replaceFirst('Maridive ', '')
    };
    final headers = [
      t.vesselLabel,
      t.requestDescriptionLabel,
      t.prNumberLabel,
      t.costLabel,
      t.currencyLabel,
      t.supplierLabel,
      t.poNumberLabel,
    ];

    List<List<String>> rowsFor(CashItemStatus status) => [
          for (final v in FleetData.vessels)
            for (final c in provider.byStatus(status, vesselId: v.id))
              [
                vesselNames[c.vesselId] ?? c.vesselId,
                c.description,
                c.prNumber,
                _money.format(c.cost),
                c.currency.label,
                c.supplier,
                c.poNumber,
              ]
        ];

    List<List<String>> totalsRows() {
      final rows = <List<String>>[];
      for (final status in CashItemStatus.values) {
        final items = provider.byStatus(status);
        final label = status == CashItemStatus.pending
            ? t.cashPendingTab
            : t.cashApprovedTab;
        for (final e in provider.subtotals(items).entries) {
          rows.add([label, e.key.label, _money.format(e.value)]);
        }
      }
      return rows;
    }

    return [
      ReportSection(t.cashPendingTab, headers, rowsFor(CashItemStatus.pending)),
      ReportSection(
          t.cashApprovedTab, headers, rowsFor(CashItemStatus.approved)),
      ReportSection(
          t.totalsLabel, [t.status, t.currencyLabel, t.costLabel], totalsRows()),
    ];
  }

  Future<void> _download(AppLocalizations t, List<ReportSection> sections,
      {required bool pdf}) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (pdf) {
        await ReportService.exportCashMeetingPdf(sections: sections);
      } else {
        await ReportService.exportCashMeetingCsv(sections: sections);
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
    final provider = context.watch<CashMeetingProvider>();
    final sections = _buildSections(t, provider);
    final locale = Localizations.localeOf(context).languageCode;
    final generatedAt =
        DateFormat.yMMMd(locale).add_Hm().format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text('${t.reviewReport} — ${t.cashMeetingTitle}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(t.cashMeetingTitle,
                    style: Theme.of(context).textTheme.headlineSmall),
                Gaps.h4,
                Text('${t.generatedAtLabel}: $generatedAt',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.slate400)),
                Gaps.h20,
                for (final section in sections) ...[
                  Text(section.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  Gaps.h8,
                  if (section.rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(t.reportNoEntries,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.slate400)),
                    )
                  else
                    GridTableView(rows: [section.headers, ...section.rows]),
                  Gaps.h24,
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _download(t, sections, pdf: false),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: Text(t.exportFormatCsv),
                    ),
                  ),
                  Gaps.w12,
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _download(t, sections, pdf: true),
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
