import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/fleet_intelligence.dart';
import '../services/assistant_service.dart';
import '../services/briefing_service.dart';
import '../services/fleet_ai_service.dart';
import '../services/fleet_intel.dart';
import '../services/report_service.dart';
import '../state/action_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/risk_presentation.dart';

/// Superintendent Daily Briefing — "what needs my attention today".
///
/// The briefing itself is built from the fleet's own records, so it is
/// available offline and every line traces to a source. The AI summary is
/// optional, clearly labelled, and additive: it rephrases what is already on
/// screen and never introduces a fact of its own.
class DailyBriefingScreen extends StatefulWidget {
  const DailyBriefingScreen({super.key});

  @override
  State<DailyBriefingScreen> createState() => _DailyBriefingScreenState();
}

class _DailyBriefingScreenState extends State<DailyBriefingScreen> {
  bool _busy = false;
  bool _aiBusy = false;
  String? _aiSummary;
  String? _aiErrorCode;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final intel = FleetIntel.build(context);
    final actions = context.watch<ActionProvider>();
    final briefing =
        BriefingService.build(intel: intel, openActions: actions.open);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.dailyBriefingTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: t.copySummary,
            onPressed: () => _copy(t, briefing),
          ),
          IconButton(
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: t.exportFormatPdf,
            onPressed: _busy ? null : () => _exportPdf(t, briefing),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              DateFormat.yMMMMEEEEd(locale).format(briefing.generatedAt),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.h4,
            Text(
              '${t.calculatedAtLabel(DateFormat.Hm(locale).format(briefing.generatedAt))} · ${t.computedLocallyNote}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.slate400),
            ),
            Gaps.h16,
            _Headline(briefing: briefing),
            Gaps.h20,

            _Section(
              title: t.briefingCritical,
              color: AppColors.statusExpired,
              items: briefing.critical,
              emptyText: t.briefingNoneInSection,
            ),
            _Section(
              title: t.briefingHighPriority,
              color: AppColors.statusMaintenance,
              items: briefing.highPriority,
              emptyText: t.briefingNoneInSection,
            ),
            _Section(
              title: t.briefingUpcoming,
              color: AppColors.amber400,
              items: briefing.upcoming,
              emptyText: t.briefingNoneInSection,
            ),
            if (briefing.openActions.isNotEmpty)
              _Section(
                title: t.briefingOpenActions,
                color: AppColors.teal500,
                items: briefing.openActions,
                emptyText: t.briefingNoneInSection,
              ),
            _PositiveSection(names: briefing.positive),

            Gaps.h20,
            const Divider(),
            Gaps.h12,
            // AI narrative: opt-in, labelled, and never the source of a fact.
            Row(
              children: [
                Expanded(
                  child: Text(t.aiSummaryTitle,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                FilledButton.tonalIcon(
                  onPressed: _aiBusy ? null : () => _generateAi(t, briefing),
                  icon: _aiBusy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(t.generateAiSummary),
                ),
              ],
            ),
            if (_aiErrorCode != null) ...[
              Gaps.h8,
              Text(_aiError(t, _aiErrorCode!),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.statusMaintenance)),
            ],
            if (_aiSummary != null) ...[
              Gaps.h8,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.amber400.withValues(alpha: 0.10),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 13, color: AppColors.amber400),
                        Gaps.w4,
                        Flexible(
                          child: Text(t.aiRecommendationLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: AppColors.amber400,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    Gaps.h8,
                    Text(_aiSummary!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            Gaps.h24,
          ],
        ),
      ),
    );
  }

  // --- Plain-text rendering, shared by copy and PDF ------------------------

  String _line(AppLocalizations t, BriefingItem item) {
    final risk = item.risk;
    if (risk != null) {
      return '${item.vesselName}: ${riskTitle(t, risk)}';
    }
    final action = item.action!;
    final overdue = action.isOverdue ? ' (${t.actionOverdueBadge})' : '';
    return '${item.vesselName}: ${action.title}$overdue';
  }

  List<(String, List<String>)> _sections(
      AppLocalizations t, DailyBriefing b) {
    List<String> lines(List<BriefingItem> items) => items.isEmpty
        ? [t.briefingNoneInSection]
        : [for (final i in items) _line(t, i)];

    return [
      (
        t.fleetHealthTitle,
        [
          '${t.bandGood}: ${b.healthyCount}',
          '${t.bandAttention}: ${b.attentionCount}',
          '${t.bandHighRisk}: ${b.highRiskCount}',
          '${t.bandCritical}: ${b.criticalCount}',
        ]
      ),
      (t.briefingCritical, lines(b.critical)),
      (t.briefingHighPriority, lines(b.highPriority)),
      (t.briefingUpcoming, lines(b.upcoming)),
      if (b.openActions.isNotEmpty)
        (t.briefingOpenActions, lines(b.openActions)),
      (
        t.briefingPositive,
        b.positive.isEmpty ? [t.briefingNoneInSection] : b.positive
      ),
    ];
  }

  Future<void> _copy(AppLocalizations t, DailyBriefing b) async {
    final buffer = StringBuffer()
      ..writeln(t.dailyBriefingTitle)
      ..writeln(DateFormat('yyyy-MM-dd HH:mm').format(b.generatedAt))
      ..writeln();
    for (final section in _sections(t, b)) {
      buffer.writeln(section.$1);
      for (final line in section.$2) {
        buffer.writeln('- $line');
      }
      buffer.writeln();
    }
    if (_aiSummary != null) {
      buffer
        ..writeln(t.aiRecommendationLabel)
        ..writeln(_aiSummary);
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.summaryCopied)));
  }

  Future<void> _exportPdf(AppLocalizations t, DailyBriefing b) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ReportService.exportBriefingPdf(
        title: t.dailyBriefingTitle,
        generatedLabel: t.generatedAtLabel,
        sections: _sections(t, b),
        aiSummary: _aiSummary,
        aiHeading: t.aiRecommendationLabel,
      );
      messenger.showSnackBar(SnackBar(content: Text(t.fileSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.downloadFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateAi(AppLocalizations t, DailyBriefing b) async {
    setState(() {
      _aiBusy = true;
      _aiErrorCode = null;
    });
    final aiContext = BriefingService.aiContext(
      intel: FleetIntel.build(context),
      openActions: context.read<ActionProvider>().open,
    );
    try {
      final text = await FleetAiService.ask(
        history: [
          ChatMessage(role: 'user', content: t.briefingAiPrompt),
        ],
        context: aiContext,
      );
      if (!mounted) return;
      setState(() => _aiSummary = text);
    } on AssistantException catch (e) {
      if (!mounted) return;
      setState(() => _aiErrorCode = e.code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _aiErrorCode = 'unexpected');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  String _aiError(AppLocalizations t, String code) => switch (code) {
        'not_configured' => t.aiUnavailable,
        'rate_limited' => t.aiBusy,
        _ => t.aiError,
      };
}

class _Headline extends StatelessWidget {
  final DailyBriefing briefing;
  const _Headline({required this.briefing});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final needsAttention = briefing.criticalCount + briefing.highRiskCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.teal500.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            briefing.isAllClear
                ? t.briefingAllClear
                : t.briefingHeadline(needsAttention, briefing.vesselCount),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Gaps.h8,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final band in HealthBand.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: bandColor(band), shape: BoxShape.circle),
                    ),
                    Gaps.w4,
                    Text(
                      '${bandLabel(t, band)}: ${switch (band) {
                        HealthBand.good => briefing.healthyCount,
                        HealthBand.attention => briefing.attentionCount,
                        HealthBand.highRisk => briefing.highRiskCount,
                        HealthBand.critical => briefing.criticalCount,
                      }}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              if (briefing.overdueActionCount > 0)
                Text(
                  '${t.actionsOverdue}: ${briefing.overdueActionCount}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.statusExpired),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final List<BriefingItem> items;
  final String emptyText;

  const _Section({
    required this.title,
    required this.color,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, color: color),
            Gaps.w8,
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Gaps.w8,
            Text('${items.length}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
        Gaps.h8,
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
            child: Text(emptyText,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.slate400)),
          )
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.sm, bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.vesselName} · ',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(
                      item.risk != null
                          ? riskTitle(t, item.risk!)
                          : item.action!.title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        Gaps.h16,
      ],
    );
  }
}

class _PositiveSection extends StatelessWidget {
  final List<String> names;
  const _PositiveSection({required this.names});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, color: AppColors.statusActive),
            Gaps.w8,
            Text(t.briefingPositive,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        Gaps.h8,
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
          child: Text(
            names.isEmpty ? t.briefingNoneInSection : names.join(' · '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: names.isEmpty ? AppColors.slate400 : null),
          ),
        ),
      ],
    );
  }
}
