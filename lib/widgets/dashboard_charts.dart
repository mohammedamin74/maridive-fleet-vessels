import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// One labelled, colored value plotted by [CategoryBarChart] or
/// [CategoryDonutChart].
class ChartEntry {
  final String label;
  final int value;
  final Color color;

  const ChartEntry(
      {required this.label, required this.value, required this.color});
}

Widget _cardShell(BuildContext context, {required Widget child}) {
  final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: dark ? AppColors.navy800 : Colors.white,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: dark ? AppColors.navy700 : AppColors.slate200),
    ),
    child: child,
  );
}

/// One coherent screen-reader description for a whole chart card — the
/// painted bars/arcs themselves are invisible to the accessibility tree.
Widget _chartSemantics(BuildContext context,
    {required String title,
    required List<ChartEntry> entries,
    required Widget child}) {
  final t = AppLocalizations.of(context)!;
  final joined = entries
      .where((e) => e.value > 0)
      .map((e) => '${e.label}: ${e.value}')
      .join(', ');
  return Semantics(
    label: '$title. ${t.chartEntriesSemantics(joined)}',
    child: ExcludeSemantics(child: child),
  );
}

Widget _emptyState(BuildContext context, String label) => SizedBox(
      height: 90,
      child: Center(
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      ),
    );

/// Horizontal bar chart — a row per [ChartEntry], bar width proportional to
/// its share of the largest value. No charting package, just [Container]s,
/// matching the zero-dependency convention set by tank_history_chart.dart.
class CategoryBarChart extends StatelessWidget {
  final String title;
  final List<ChartEntry> entries;
  final String emptyLabel;

  const CategoryBarChart({
    super.key,
    required this.title,
    required this.entries,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.fold<int>(1, (m, e) => e.value > m ? e.value : m);
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return _chartSemantics(
      context,
      title: title,
      entries: entries,
      child: _cardShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          if (total == 0)
            _emptyState(context, emptyLabel)
          else
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          e.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: e.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (e.value / maxValue).clamp(0.0, 1.0),
                              child: Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  color: e.color,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${e.value}',
                          textAlign: TextAlign.end,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
      ),
    );
  }
}

/// Donut chart — proportional arc per [ChartEntry] around a hollow center,
/// with a color-coded legend. Drawn with a plain [CustomPainter], no
/// charting package dependency.
class CategoryDonutChart extends StatelessWidget {
  final String title;
  final List<ChartEntry> entries;
  final String emptyLabel;

  const CategoryDonutChart({
    super.key,
    required this.title,
    required this.entries,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return _chartSemantics(
      context,
      title: title,
      entries: entries,
      child: _cardShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          if (total == 0)
            _emptyState(context, emptyLabel)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      entries: entries,
                      total: total,
                      trackColor: dark ? AppColors.navy700 : AppColors.slate100,
                    ),
                    child: Center(
                      child: Text(
                        '$total',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: entries
                        .where((e) => e.value > 0)
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                        color: e.color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    '${e.value}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<ChartEntry> entries;
  final int total;
  final Color trackColor;

  _DonutPainter(
      {required this.entries, required this.total, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 13.0;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, 6.2832, false, trackPaint);

    if (total == 0) return;
    var start = -1.5708; // -90deg, start at top
    for (final e in entries) {
      if (e.value <= 0) continue;
      final sweep = (e.value / total) * 6.28319;
      final paint = Paint()
        ..color = e.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
          rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.total != total;
}
