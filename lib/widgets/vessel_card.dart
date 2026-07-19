import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/vessel.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'status_badge.dart';
import 'tank_level_bar.dart';

class VesselCard extends StatelessWidget {
  final Vessel vessel;
  final VoidCallback onTap;

  const VesselCard({super.key, required this.vessel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final fuelPercent =
        context.watch<TankDataProvider>().avgFuelPercent(vessel);
    final muted = scheme.onSurface.withValues(alpha: 0.4);
    final fuelColor = fuelPercent == null
        ? muted
        : fuelPercent < 0.25
            ? AppColors.statusMaintenance
            : (fuelPercent < 0.5 ? AppColors.amber400 : AppColors.teal400);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadius.lgAll,
                child: vessel.photoAsset.isEmpty
                    ? _iconAvatar()
                    : Image.asset(
                        vessel.photoAsset,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _iconAvatar(),
                      ),
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
                      vessel.workingPort.isEmpty
                          ? '${vessel.type} · ${vessel.homePort}'
                          : '${vessel.type} · ${vessel.workingPort}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (vessel.imo.isNotEmpty &&
                            vessel.imo.toUpperCase() != 'N/A') ...[
                          _MetaChip(
                              icon: Icons.tag, label: 'IMO ${vessel.imo}'),
                          const SizedBox(width: 8),
                        ],
                        _MetaChip(
                            icon: Icons.people_alt_outlined,
                            label: '${vessel.crew}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.local_gas_station,
                            size: 13,
                            color: scheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: TankLevelBarHorizontal(
                                percent: fuelPercent ?? 0, color: fuelColor)),
                        const SizedBox(width: 8),
                        Text(
                          fuelPercent == null
                              ? t.noData
                              : '${(fuelPercent * 100).round()}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: fuelColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: scheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _iconAvatar() => Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(gradient: AppColors.heroGradient),
      alignment: Alignment.center,
      child: const Icon(Icons.directions_boat_filled,
          color: Colors.white, size: 22),
    );

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: muted),
        const SizedBox(width: 3),
        Text(
          label,
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
