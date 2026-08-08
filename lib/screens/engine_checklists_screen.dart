import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/checklist_templates.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/checklist_run.dart';
import '../models/checklist_template.dart';
import '../models/vessel.dart';
import '../state/checklist_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'checklist_run_screen.dart';

/// Entry point for the engine department's controlled forms: pick a month,
/// see each form's completion at a glance, open one to tick it through.
///
/// The forms themselves are fixed office documents (see
/// data/checklist_templates.dart) — the vessel fills them in, it does not
/// author them.
class EngineChecklistsScreen extends StatefulWidget {
  final Vessel vessel;
  const EngineChecklistsScreen({super.key, required this.vessel});

  @override
  State<EngineChecklistsScreen> createState() => _EngineChecklistsScreenState();
}

class _EngineChecklistsScreenState extends State<EngineChecklistsScreen> {
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;

  void _shiftMonth(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      if (m < 1) {
        m = 12;
        y--;
      } else if (m > 12) {
        m = 1;
        y++;
      }
      _month = m;
      _year = y;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final provider = context.watch<ChecklistProvider>();
    final monthLabel =
        DateFormat.yMMMM(locale).format(DateTime(_year, _month));

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.engineChecklists} — ${widget.vessel.name}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftMonth(-1),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            Gaps.h16,
            for (final template in ChecklistTemplates.all)
              _TemplateCard(
                template: template,
                run: provider.find(
                  vesselId: widget.vessel.id,
                  templateCode: template.code,
                  year: _year,
                  month: _month,
                ),
                year: _year,
                month: _month,
                onOpen: () => _open(template),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(ChecklistTemplate template) async {
    final provider = context.read<ChecklistProvider>();
    final navigator = Navigator.of(context);
    final run = await provider.ensureRun(
      vesselId: widget.vessel.id,
      templateCode: template.code,
      year: _year,
      month: _month,
    );
    navigator.push(MaterialPageRoute(
      builder: (_) => ChecklistRunScreen(
          vessel: widget.vessel, template: template, runId: run.id),
    ));
  }
}

class _TemplateCard extends StatelessWidget {
  final ChecklistTemplate template;
  final ChecklistRun? run;
  final int year;
  final int month;
  final VoidCallback onOpen;

  const _TemplateCard({
    required this.template,
    required this.run,
    required this.year,
    required this.month,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final slots = template.slotCount(year, month);
    final (done, total) =
        run?.progress(template.items.length, slots) ?? (0, template.items.length * slots);
    final ratio = total == 0 ? 0.0 : done / total;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? template.titleAr
                          : template.titleEn,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Gaps.w8,
                  Text(template.code,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.slate400)),
                ],
              ),
              Gaps.h8,
              ClipRRect(
                borderRadius: AppRadius.pill,
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.slate200,
                  color: ratio >= 1
                      ? AppColors.statusActive
                      : ratio > 0
                          ? AppColors.amber400
                          : AppColors.slate400,
                ),
              ),
              Gaps.h8,
              Row(
                children: [
                  Expanded(
                    child: Text(t.checklistProgress(done, total),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.slate400)),
                  ),
                  if (run?.isSubmitted == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 13, color: AppColors.statusActive),
                        Gaps.w4,
                        Text(
                          DateFormat.yMMMd(locale).format(run!.submittedAt!),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.statusActive),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
