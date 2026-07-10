import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tank.dart';
import '../models/vessel.dart';
import '../state/alert_thresholds.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/tank_status_chip.dart';
import 'tank_calculator_screen.dart';

class TankCategoryScreen extends StatelessWidget {
  final Vessel vessel;
  final TankCategory category;
  final String title;

  const TankCategoryScreen({
    super.key,
    required this.vessel,
    required this.category,
    required this.title,
  });

  Color _categoryColor() {
    switch (category) {
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
    final tanks = vessel.tanksOf(category);
    final color = _categoryColor();
    final data = context.watch<TankDataProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: tanks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tank = tanks[index];
          final percent = data.percentFor(vessel.id, tank);
          final currentM3 = data.currentLevel(vessel.id, tank.id);
          final status = data.statusFor(vessel.id, tank);

          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TankCalculatorScreen(vesselId: vessel.id, tank: tank, accent: color),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tank.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (status == TankLevelStatus.critical || status == TankLevelStatus.warning) ...[
                                const SizedBox(width: 8),
                                TankStatusChip(status: status),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentM3.toStringAsFixed(0)} / ${tank.capacityM3.toStringAsFixed(0)} m³',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(percent * 100).round()}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
