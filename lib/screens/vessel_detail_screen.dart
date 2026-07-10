import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/defect.dart';
import '../models/requisition.dart';
import '../models/tank.dart';
import '../models/vessel.dart';
import '../services/report_service.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/category_tile.dart';
import '../widgets/status_badge.dart';
import 'defect_list_screen.dart';
import 'requisition_list_screen.dart';
import 'tank_category_screen.dart';
import 'vessel_logbook_screen.dart';

class VesselDetailScreen extends StatelessWidget {
  final Vessel vessel;
  const VesselDetailScreen({super.key, required this.vessel});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final openDefects = data.defectsFor(vessel.id).where((d) => d.status != DefectStatus.closed).length;
    final pendingReqs = data.requisitionsFor(vessel.id).where((r) => r.status == RequisitionStatus.pending).length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _VesselHeader(vessel: vessel, t: t)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(t.tankSystems, style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildListDelegate([
                  CategoryTile(
                    icon: Icons.local_gas_station,
                    title: t.categoryFuelOil,
                    subtitle: t.tanksInCategory(vessel.tanksOf(TankCategory.fuelOil).length),
                    color: AppColors.amber400,
                    onTap: () => _openCategory(context, TankCategory.fuelOil, t.categoryFuelOil),
                  ),
                  CategoryTile(
                    icon: Icons.water_drop,
                    title: t.categoryBrineMud,
                    subtitle: t.tanksInCategory(vessel.tanksOf(TankCategory.brineMud).length),
                    color: AppColors.navy500,
                    onTap: () => _openCategory(context, TankCategory.brineMud, t.categoryBrineMud),
                  ),
                  CategoryTile(
                    icon: Icons.oil_barrel,
                    title: t.categoryLubeHydraulic,
                    subtitle: t.tanksInCategory(vessel.tanksOf(TankCategory.lubeHydraulic).length),
                    color: AppColors.teal500,
                    onTap: () => _openCategory(context, TankCategory.lubeHydraulic, t.categoryLubeHydraulic),
                  ),
                  CategoryTile(
                    icon: Icons.layers,
                    title: t.categoryOther,
                    subtitle: t.tanksInCategory(vessel.tanksOf(TankCategory.other).length),
                    color: AppColors.statusPort,
                    onTap: () => _openCategory(context, TankCategory.other, t.categoryOther),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(t.vesselOperations, style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildListDelegate([
                  CategoryTile(
                    icon: Icons.menu_book_outlined,
                    title: t.logbook,
                    subtitle: t.viewEntries,
                    color: AppColors.teal500,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => VesselLogbookScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.report_problem_outlined,
                    title: t.defects,
                    subtitle: t.openCount(openDefects),
                    color: openDefects > 0 ? AppColors.statusMaintenance : AppColors.statusPort,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DefectListScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.shopping_cart_outlined,
                    title: t.requisitions,
                    subtitle: t.pendingCount(pendingReqs),
                    color: AppColors.amber400,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RequisitionListScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.picture_as_pdf_outlined,
                    title: t.exportReport,
                    subtitle: t.tankStatusPdf,
                    color: AppColors.navy500,
                    onTap: () async {
                      await ReportService.exportVesselReport(vessel: vessel, data: data);
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, TankCategory category, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TankCategoryScreen(vessel: vessel, category: category, title: title),
      ),
    );
  }
}

class _VesselHeader extends StatelessWidget {
  final Vessel vessel;
  final AppLocalizations t;
  const _VesselHeader({required this.vessel, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      decoration: BoxDecoration(gradient: AppColors.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              StatusBadge(status: vessel.status),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vessel.name,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  vessel.type,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _InfoChip(icon: Icons.tag, label: t.imoNumber, value: vessel.imo),
                    const SizedBox(width: 10),
                    _InfoChip(icon: Icons.location_on, label: t.homePort, value: vessel.homePort),
                    const SizedBox(width: 10),
                    _InfoChip(icon: Icons.groups, label: t.crewOnBoard, value: '${vessel.crew}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
