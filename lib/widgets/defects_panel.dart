import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/defect.dart';
import '../models/vessel.dart';
import '../screens/defect_list_screen.dart';
import '../theme/app_colors.dart';

class DefectsPanel extends StatelessWidget {
  final List<Defect> defects;
  final List<Vessel> vessels;
  const DefectsPanel({super.key, required this.defects, required this.vessels});

  @override
  Widget build(BuildContext context) {
    if (defects.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.amber400.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber400.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: const Icon(Icons.report_problem_outlined, color: AppColors.amber400),
          title: Text(
            t.criticalDefectsTitle(defects.length),
            style: const TextStyle(color: AppColors.amber400, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          iconColor: AppColors.amber400,
          collapsedIconColor: AppColors.amber400,
          children: defects.map((defect) {
            final vessel = vessels.firstWhere((v) => v.id == defect.vesselId);
            final color =
                defect.severity == DefectSeverity.critical ? AppColors.statusMaintenance : AppColors.amber400;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              title: Text(
                '${defect.title} · ${vessel.name}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DefectListScreen(vessel: vessel)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
