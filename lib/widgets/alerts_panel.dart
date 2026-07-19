import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/tank.dart';
import '../screens/tank_calculator_screen.dart';
import '../state/alert_thresholds.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';

class AlertsPanel extends StatelessWidget {
  final List<TankAlert> alerts;
  const AlertsPanel({super.key, required this.alerts});

  Color _categoryColorFor(TankAlert alert) {
    switch (alert.tank.category) {
      case TankCategory.fuelOil:
        return AppColors.amber400;
      case TankCategory.brineMud:
        return AppColors.navy500;
      case TankCategory.lubeHydraulic:
        return AppColors.teal500;
      case TankCategory.other:
        return AppColors.statusPort;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.statusMaintenance.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.statusMaintenance.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: const Icon(Icons.warning_amber_rounded,
              color: AppColors.statusMaintenance),
          title: Text(
            t.alertsTitle(alerts.length),
            style: const TextStyle(
              color: AppColors.statusMaintenance,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          iconColor: AppColors.statusMaintenance,
          collapsedIconColor: AppColors.statusMaintenance,
          children: alerts.map((alert) {
            final color = (alert.status == TankLevelStatus.critical ||
                    alert.status == TankLevelStatus.highCritical)
                ? AppColors.statusMaintenance
                : AppColors.amber400;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              title: Text(
                '${alert.tank.name} · ${alert.vessel.name}',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '${(alert.percent * 100).round()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TankCalculatorScreen(
                    vesselId: alert.vessel.id,
                    tank: alert.tank,
                    accent: _categoryColorFor(alert),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
