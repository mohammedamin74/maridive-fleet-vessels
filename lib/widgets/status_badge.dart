import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/vessel.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final VesselStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = AppColors.statusColor(_key(status));
    final label = switch (status) {
      VesselStatus.active => t.statusActive,
      VesselStatus.standby => t.statusStandby,
      VesselStatus.port => t.statusInPort,
      VesselStatus.maintenance => t.statusMaintenance,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _key(VesselStatus s) => switch (s) {
        VesselStatus.active => 'active',
        VesselStatus.standby => 'standby',
        VesselStatus.port => 'port',
        VesselStatus.maintenance => 'maintenance',
      };
}
