import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/fleet_intelligence.dart';
import '../models/superintendent_action.dart';
import '../services/fleet_intel.dart';
import '../state/action_provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/risk_presentation.dart';
import 'actions_screen.dart';

/// Risk Intelligence: every deterministic risk detected across the fleet,
/// worst first, each showing the record it came from and a recommended next
/// step. Nothing here is AI-generated — the rules run on the vessel records
/// already loaded on this device, so it works offline and is fully
/// explainable.
class RiskScreen extends StatefulWidget {
  /// When set, the screen opens filtered to one vessel (used from the
  /// Command Center's vessel ranking).
  final String? initialVesselId;

  const RiskScreen({super.key, this.initialVesselId});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  String? _vesselFilter;
  RiskSeverity? _severityFilter;
  bool _filterInitialized = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (!_filterInitialized) {
      _vesselFilter = widget.initialVesselId;
      _filterInitialized = true;
    }

    final intel = FleetIntel.build(context);
    final vessels = intel.vessels;

    final visible = <({VesselIntel vessel, RiskEvent risk})>[];
    for (final v in vessels) {
      if (_vesselFilter != null && v.vessel.id != _vesselFilter) continue;
      for (final r in v.risks) {
        if (_severityFilter != null && r.severity != _severityFilter) continue;
        visible.add((vessel: v, risk: r));
      }
    }
    visible.sort((a, b) => a.risk.severity.index.compareTo(b.risk.severity.index));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.riskTitle),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _SeveritySummary(
              intel: intel,
              selected: _severityFilter,
              onSelect: (s) => setState(
                  () => _severityFilter = _severityFilter == s ? null : s),
            ),
            _VesselFilterRow(
              vessels: vessels,
              selected: _vesselFilter,
              onSelect: (id) => setState(() => _vesselFilter = id),
            ),
            const Divider(height: 1),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          t.noRisksFleet,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.slate400),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: visible.length,
                      itemBuilder: (context, i) => _RiskCard(
                        risk: visible[i].risk,
                        vesselName: visible[i].vessel.vessel.name,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeveritySummary extends StatelessWidget {
  final FleetIntel intel;
  final RiskSeverity? selected;
  final ValueChanged<RiskSeverity> onSelect;

  const _SeveritySummary(
      {required this.intel, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          for (final s in RiskSeverity.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: _SeverityTile(
                  label: severityLabel(t, s),
                  count: intel.countBySeverity(s),
                  color: severityColor(s),
                  selected: selected == s,
                  onTap: () => onSelect(s),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeverityTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SeverityTile({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label: $count',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs, horizontal: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.22 : 0.10),
            borderRadius: AppRadius.mdAll,
            border: Border.all(
                color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Text('$count',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.w800)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _VesselFilterRow extends StatelessWidget {
  final List<VesselIntel> vessels;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _VesselFilterRow(
      {required this.vessels, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(t.allVesselsFilter),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          for (final v in vessels)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(v.vessel.name.replaceFirst('Maridive ', '')),
                selected: selected == v.vessel.id,
                onSelected: (_) => onSelect(v.vessel.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final RiskEvent risk;
  final String vesselName;

  const _RiskCard({required this.risk, required this.vesselName});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final actions = context.watch<ActionProvider>();
    final color = severityColor(risk.severity);
    final hasAction = actions.hasActionFor(risk);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RiskChip(
                    label: severityLabel(t, risk.severity), color: color),
                Gaps.w8,
                Flexible(
                  child: Text(vesselName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                Gaps.w8,
                Flexible(
                  child: Text(categoryLabel(t, risk.category),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.slate400)),
                ),
              ],
            ),
            Gaps.h8,
            Text(riskTitle(t, risk),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Gaps.h8,
            // Evidence: which record this came from, so the conclusion can
            // always be checked against the source.
            Row(
              children: [
                const Icon(Icons.link, size: 13, color: AppColors.slate400),
                Gaps.w4,
                Flexible(
                  child: Text(
                    '${t.evidenceLabel}: ${sourceModuleLabel(t, risk.sourceType)} — ${risk.subject}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.slate400),
                  ),
                ),
              ],
            ),
            Gaps.h8,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.teal500.withValues(alpha: 0.08),
                borderRadius: AppRadius.smAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.recommendedActionLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.teal600,
                          fontWeight: FontWeight.w700)),
                  Gaps.h4,
                  Text(riskRecommendation(t, risk),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Gaps.h8,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: hasAction
                  ? TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ActionsScreen()),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(t.actionAlreadyExists),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: () => _createAction(context, t),
                      icon: const Icon(Icons.playlist_add, size: 16),
                      label: Text(t.createActionFromRisk),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static const _priorityForSeverity = {
    RiskSeverity.critical: ActionPriority.critical,
    RiskSeverity.high: ActionPriority.high,
    RiskSeverity.medium: ActionPriority.medium,
    RiskSeverity.low: ActionPriority.low,
    RiskSeverity.info: ActionPriority.low,
  };

  Future<void> _createAction(BuildContext context, AppLocalizations t) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = context.read<ActionProvider>();
    final user = context.read<AuthProvider>().currentUser;
    await actions.add(
      vesselId: risk.vesselId,
      title: riskTitle(t, risk),
      description: '${t.evidenceLabel}: '
          '${sourceModuleLabel(t, risk.sourceType)} — ${risk.subject}',
      recommendation: riskRecommendation(t, risk),
      priority: _priorityForSeverity[risk.severity] ?? ActionPriority.medium,
      sourceType: risk.sourceType,
      sourceId: risk.sourceId,
      dueDate: risk.dueDate,
      createdBy: user?.username ?? '',
    );
    messenger.showSnackBar(SnackBar(content: Text(t.actionCreatedFromRisk)));
  }
}
