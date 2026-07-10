import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vessel.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';
import 'tank_level_bar.dart';

class VesselCard extends StatelessWidget {
  final Vessel vessel;
  final VoidCallback onTap;

  const VesselCard({super.key, required this.vessel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fuelPercent = context.watch<TankDataProvider>().avgFuelPercent(vessel);
    final fuelColor = fuelPercent < 0.25
        ? AppColors.statusMaintenance
        : (fuelPercent < 0.5 ? AppColors.amber400 : AppColors.teal400);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const FaIcon(FontAwesomeIcons.ship, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vessel.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: vessel.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vessel.type} · ${vessel.homePort}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(FontAwesomeIcons.gasPump, size: 13, color: scheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Expanded(child: TankLevelBarHorizontal(percent: fuelPercent, color: fuelColor)),
                        const SizedBox(width: 8),
                        Text(
                          '${(fuelPercent * 100).round()}%',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fuelColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
