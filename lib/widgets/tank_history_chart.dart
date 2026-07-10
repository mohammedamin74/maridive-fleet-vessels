import 'package:flutter/material.dart';
import '../models/tank_reading.dart';
import '../theme/app_colors.dart';

/// Lightweight sounding-history line chart. Plots readings from the last
/// 24 hours (falling back to whatever history exists if the tank hasn't
/// been sounded in the last day) as percent-of-capacity over time — no
/// charting package dependency, just a CustomPainter.
class TankHistoryChart extends StatelessWidget {
  final List<TankReading> readings;
  final Color color;
  final double capacityM3;

  const TankHistoryChart({
    super.key,
    required this.readings,
    required this.color,
    required this.capacityM3,
  });

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    var points = readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
    if (points.length < 2) points = readings.take(20).toList();
    points = points.reversed.toList();
    if (points.length < 2) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? AppColors.navy800
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.brightness == Brightness.dark
              ? AppColors.navy700
              : AppColors.slate200,
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(
          values: points
              .map((r) => capacityM3 <= 0
                  ? 0.0
                  : (r.levelM3 / capacityM3).clamp(0.0, 1.0))
              .toList(),
          color: color,
          gridColor: scheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color gridColor;

  _LineChartPainter(
      {required this.values, required this.color, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = size.height * (1 - frac);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dx = values.length > 1 ? size.width / (values.length - 1) : 0.0;
    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height * (1 - values[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(dx * (values.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height * (1 - values[i]);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
