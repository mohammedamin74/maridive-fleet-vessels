import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/fleet_intelligence.dart';
import '../screens/risk_screen.dart';
import '../services/fleet_intel.dart';
import '../services/vessel_health_service.dart';
import '../state/action_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'risk_presentation.dart';

/// Fleet Command Center: the "what needs my attention now" block at the top
/// of the dashboard. Fleet health counts, vessels ranked worst-first with an
/// explainable score, and the highest-severity risks across the fleet.
///
/// Everything is computed locally from records already loaded, so it is
/// honest about being a snapshot rather than a live server query.
class CommandCenterPanel extends StatelessWidget {
  const CommandCenterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final intel = FleetIntel.build(context);
    final actions = context.watch<ActionProvider>();
    final locale = Localizations.localeOf(context).languageCode;
    final worst = intel.allRisks.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar, size: 18, color: AppColors.teal500),
                Gaps.w8,
                Expanded(
                  child: Text(t.commandCenterTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RiskScreen()),
                  ),
                  child: Text(t.riskTitle),
                ),
              ],
            ),
            Text(
              '${t.calculatedAtLabel(DateFormat.Hm(locale).format(DateTime.now()))} · ${t.computedLocallyNote}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.slate400),
            ),
            Gaps.h12,

            // Fleet health bands.
            Row(
              children: [
                for (final band in HealthBand.values)
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                      child: _BandTile(
                        label: bandLabel(t, band),
                        count: intel.countInBand(band),
                        color: bandColor(band),
                      ),
                    ),
                  ),
              ],
            ),
            Gaps.h16,

            // Vessel ranking, worst health first.
            Text(t.vesselRankingTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Gaps.h8,
            for (final v in intel.vessels)
              _RankingRow(
                intel: v,
                onTap: () => _showBreakdown(context, t, v),
              ),

            if (worst.isNotEmpty) ...[
              Gaps.h16,
              Text(t.priorityAttentionTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Gaps.h8,
              for (final r in worst)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: RiskChip(
                            label: severityLabel(t, r.severity),
                            color: severityColor(r.severity)),
                      ),
                      Gaps.w8,
                      Expanded(
                        child: Text(riskTitle(t, r),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
            ],

            if (actions.openCount > 0) ...[
              Gaps.h8,
              Row(
                children: [
                  const Icon(Icons.task_alt,
                      size: 14, color: AppColors.slate400),
                  Gaps.w4,
                  Text(
                    t.openActionsBadge(actions.openCount),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.slate400),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Why is this score 72?" — the component scores and the individual
  /// deductions that produced the number, each naming its source record.
  void _showBreakdown(
      BuildContext context, AppLocalizations t, VesselIntel v) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (sheetContext, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(v.vessel.name,
                style: Theme.of(sheetContext).textTheme.titleLarge),
            Gaps.h4,
            Text(t.whyThisScore(v.health.score),
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    color: bandColor(v.health.band),
                    fontWeight: FontWeight.w700)),
            Gaps.h16,
            Text(t.componentScoresTitle,
                style: Theme.of(sheetContext).textTheme.titleSmall),
            Gaps.h8,
            for (final entry in VesselHealthService.weights.keys.map(
                (c) => MapEntry(c, v.health.componentScores[c] ?? 100)))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(categoryLabel(t, entry.key),
                          style:
                              Theme.of(sheetContext).textTheme.bodySmall),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.pill,
                        child: LinearProgressIndicator(
                          value: entry.value / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.slate200,
                          color: bandColor(
                              VesselHealthService.bandFor(entry.value)),
                        ),
                      ),
                    ),
                    Gaps.w8,
                    SizedBox(
                      width: 32,
                      child: Text('${entry.value}',
                          textAlign: TextAlign.end,
                          style:
                              Theme.of(sheetContext).textTheme.labelMedium),
                    ),
                  ],
                ),
              ),
            Gaps.h16,
            Text(t.scoreBreakdownTitle,
                style: Theme.of(sheetContext).textTheme.titleSmall),
            Gaps.h8,
            if (v.health.deductions.isEmpty)
              Text(t.noRisksDetected,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.slate400))
            else
              for (final d in v.health.deductions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    t.deductionLine(d.points, riskTitle(t, d.risk)),
                    style: Theme.of(sheetContext).textTheme.bodySmall,
                  ),
                ),
            Gaps.h20,
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RiskScreen(initialVesselId: v.vessel.id),
                ));
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(t.riskTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _BandTile(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $count',
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs, horizontal: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.mdAll,
        ),
        child: Column(
          children: [
            Text('$count',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.w800)),
            Text(label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final VesselIntel intel;
  final VoidCallback onTap;
  const _RankingRow({required this.intel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = bandColor(intel.health.band);
    final name = intel.vessel.name.replaceFirst('Maridive ', '');

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: AppRadius.pill,
                child: LinearProgressIndicator(
                  value: intel.health.score / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.slate200,
                  color: color,
                ),
              ),
            ),
            Gaps.w8,
            SizedBox(
              width: 52,
              child: Text('${intel.health.score}/100',
                  textAlign: TextAlign.end,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w800)),
            ),
            Gaps.w4,
            Semantics(
              label: t.whyThisScore(intel.health.score),
              child: const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.slate400),
            ),
          ],
        ),
      ),
    );
  }
}
