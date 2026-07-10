import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Vertical liquid-fill gauge used to visualize a tank's current level.
class TankLevelBar extends StatelessWidget {
  final double percent; // 0..1
  final Color color;
  final double width;
  final double height;

  const TankLevelBar({
    super.key,
    required this.percent,
    required this.color,
    this.width = 46,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.brightness == Brightness.dark
        ? AppColors.navy700.withOpacity(0.5)
        : AppColors.slate200;

    return ClipRRect(
      borderRadius: BorderRadius.circular(width / 2),
      child: Container(
        width: width,
        height: height,
        color: track,
        alignment: Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percent.clamp(0, 1)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return FractionallySizedBox(
              heightFactor: value,
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.tankFillGradient(color),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Compact horizontal variant used inside list rows.
class TankLevelBarHorizontal extends StatelessWidget {
  final double percent;
  final Color color;

  const TankLevelBarHorizontal({super.key, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.brightness == Brightness.dark
        ? AppColors.navy700.withOpacity(0.5)
        : AppColors.slate200;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(color: track),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent.clamp(0, 1)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value,
                child: Container(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
