import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../state/alert_thresholds.dart';
import '../theme/app_colors.dart';

class TankStatusChip extends StatelessWidget {
  final TankLevelStatus status;
  const TankStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final Color color;
    final String label;
    switch (status) {
      case TankLevelStatus.critical:
        color = AppColors.statusMaintenance;
        label = t.criticalLevel;
        break;
      case TankLevelStatus.warning:
        color = AppColors.amber400;
        label = t.warningLevel;
        break;
      case TankLevelStatus.noData:
      case TankLevelStatus.normal:
        color = AppColors.slate400;
        label = t.noData;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
