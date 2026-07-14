import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/defect.dart';
import '../models/requisition.dart';
import '../models/tank.dart';
import '../models/urgent_notification.dart';
import '../models/vessel.dart';
import '../state/crew_provider.dart';
import '../state/daily_tasks_provider.dart';
import '../state/maintenance_provider.dart';
import '../state/port_call_provider.dart';
import '../state/port_requirement_provider.dart';
import '../state/tank_data_provider.dart';
import '../state/urgent_notification_provider.dart';
import '../state/vessel_profile_provider.dart';
import '../state/vessel_spec_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/category_tile.dart';
import '../widgets/status_badge.dart';
import 'certification_screen.dart';
import 'crew_list_screen.dart';
import 'daily_tasks_list_screen.dart';
import 'defect_list_screen.dart';
import 'export_report_screen.dart';
import 'maintenance_list_screen.dart';
import 'port_call_list_screen.dart';
import 'port_requirements_screen.dart';
import 'requisition_list_screen.dart';
import 'tank_category_screen.dart';
import 'urgent_notifications_screen.dart';
import 'vessel_logbook_screen.dart';
import 'vessel_specs_screen.dart';

class VesselDetailScreen extends StatelessWidget {
  final Vessel vessel;
  const VesselDetailScreen({super.key, required this.vessel});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final resolved = context.watch<VesselProfileProvider>().resolve(vessel);
    final openMaintenance =
        context.watch<MaintenanceProvider>().openCountFor(vessel.id);
    final specCount = context.watch<VesselSpecProvider>().countFor(vessel.id);
    final openDefects = data
        .defectsFor(vessel.id)
        .where((d) => d.status != DefectStatus.closed)
        .length;
    final pendingReqs = data
        .requisitionsFor(vessel.id)
        .where((r) => r.status == RequisitionStatus.pending)
        .length;
    final unackAlerts = context
        .watch<UrgentNotificationProvider>()
        .forVessel(vessel.id)
        .where((n) => n.escalationStatus == EscalationStatus.notAcknowledged)
        .length;
    final overdueTasks =
        context.watch<DailyTasksProvider>().overdueCountFor(vessel.id);
    final upcomingPortCalls =
        context.watch<PortCallProvider>().forVessel(vessel.id).length;
    final pendingRequirements =
        context.watch<PortRequirementProvider>().pendingCount(vessel.id);
    final crewOnboard = context.watch<CrewProvider>().currentCount(vessel.id);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _VesselHeader(vessel: resolved, t: t)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(t.tankSystems,
                    style: Theme.of(context).textTheme.titleLarge),
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
                    subtitle: t.tanksInCategory(
                        vessel.tanksOf(TankCategory.fuelOil).length),
                    color: AppColors.amber400,
                    onTap: () => _openCategory(
                        context, TankCategory.fuelOil, t.categoryFuelOil),
                  ),
                  CategoryTile(
                    icon: Icons.water_drop,
                    title: t.categoryBrineMud,
                    subtitle: t.tanksInCategory(
                        vessel.tanksOf(TankCategory.brineMud).length),
                    color: AppColors.navy500,
                    onTap: () => _openCategory(
                        context, TankCategory.brineMud, t.categoryBrineMud),
                  ),
                  CategoryTile(
                    icon: Icons.oil_barrel,
                    title: t.categoryLubeHydraulic,
                    subtitle: t.tanksInCategory(
                        vessel.tanksOf(TankCategory.lubeHydraulic).length),
                    color: AppColors.teal500,
                    onTap: () => _openCategory(context,
                        TankCategory.lubeHydraulic, t.categoryLubeHydraulic),
                  ),
                  CategoryTile(
                    icon: Icons.layers,
                    title: t.categoryOther,
                    subtitle: t.tanksInCategory(
                        vessel.tanksOf(TankCategory.other).length),
                    color: AppColors.statusPort,
                    onTap: () => _openCategory(
                        context, TankCategory.other, t.categoryOther),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(t.vesselOperations,
                    style: Theme.of(context).textTheme.titleLarge),
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
                      MaterialPageRoute(
                          builder: (_) => VesselLogbookScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.description_outlined,
                    title: t.specifications,
                    subtitle: t.filesCount(specCount),
                    color: AppColors.navy500,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => VesselSpecsScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.report_problem_outlined,
                    title: t.defects,
                    subtitle: t.openCount(openDefects),
                    color: openDefects > 0
                        ? AppColors.statusMaintenance
                        : AppColors.statusPort,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => DefectListScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.shopping_cart_outlined,
                    title: t.requisitions,
                    subtitle: t.pendingCount(pendingReqs),
                    color: AppColors.amber400,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              RequisitionListScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.local_shipping_outlined,
                    title: t.portCalls,
                    subtitle: t.upcomingCount(upcomingPortCalls),
                    color: AppColors.teal500,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => PortCallListScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.checklist_rtl_outlined,
                    title: t.portRequirements,
                    subtitle: t.pendingCount(pendingRequirements),
                    color: pendingRequirements > 0
                        ? AppColors.amber400
                        : AppColors.statusPort,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              PortRequirementsScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.verified_outlined,
                    title: t.certification,
                    subtitle: t.viewEntries,
                    color: AppColors.navy500,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => CertificationScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.groups_outlined,
                    title: t.crew,
                    subtitle: t.crewOnboard(crewOnboard),
                    color: AppColors.teal500,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => CrewListScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.crisis_alert,
                    title: t.urgentNotifications,
                    subtitle: t.unacknowledgedCount(unackAlerts),
                    color: unackAlerts > 0
                        ? AppColors.statusMaintenance
                        : AppColors.statusPort,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              UrgentNotificationsScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.checklist_outlined,
                    title: t.dailyTasks,
                    subtitle: t.overdueCount(overdueTasks),
                    color: overdueTasks > 0
                        ? AppColors.statusMaintenance
                        : AppColors.amber400,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => DailyTasksListScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.build_outlined,
                    title: t.maintenance,
                    subtitle: t.openCount(openMaintenance),
                    color: openMaintenance > 0
                        ? AppColors.amber400
                        : AppColors.statusPort,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => MaintenanceListScreen(vessel: vessel)),
                    ),
                  ),
                  CategoryTile(
                    icon: Icons.picture_as_pdf_outlined,
                    title: t.exportReport,
                    subtitle: t.tankStatusPdf,
                    color: AppColors.navy500,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => ExportReportScreen(vessel: resolved)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(
      BuildContext context, TankCategory category, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TankCategoryScreen(
            vessel: vessel, category: category, title: title),
      ),
    );
  }
}

class _VesselHeader extends StatelessWidget {
  final Vessel vessel;
  final AppLocalizations t;
  const _VesselHeader({required this.vessel, required this.t});

  String _statusLabel(AppLocalizations t, VesselStatus s) => switch (s) {
        VesselStatus.active => t.statusActive,
        VesselStatus.standby => t.statusStandby,
        VesselStatus.port => t.statusInPort,
        VesselStatus.maintenance => t.statusMaintenance,
        VesselStatus.offHire => t.statusOffHire,
      };

  void _showEditSheet(BuildContext context, AppLocalizations t) {
    final provider = context.read<VesselProfileProvider>();
    VesselStatus status = vessel.status;
    final imoController = TextEditingController(
        text: vessel.imo.toUpperCase() == 'N/A' ? '' : vessel.imo);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.editVessel,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<VesselStatus>(
                initialValue: status,
                decoration: InputDecoration(labelText: t.vesselStatusLabel),
                items: VesselStatus.values
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(_statusLabel(t, s))))
                    .toList(),
                onChanged: (v) => setState(() => status = v ?? status),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: imoController,
                decoration: InputDecoration(labelText: t.imoNumber),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.setStatus(vessel.id, status);
                    provider.setImo(vessel.id, imoController.text.trim());
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text(t.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              IconButton(
                onPressed: () => _showEditSheet(context, t),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: t.editVessel,
              ),
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
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  vessel.type,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _InfoChip(
                        icon: Icons.tag,
                        label: t.imoNumber,
                        value: (vessel.imo.isEmpty ||
                                vessel.imo.toUpperCase() == 'N/A')
                            ? '—'
                            : vessel.imo),
                    const SizedBox(width: 10),
                    _InfoChip(
                        icon: Icons.groups,
                        label: t.crewOnBoard,
                        value: '${vessel.crew}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _InfoChip(
                        icon: Icons.home_outlined,
                        label: t.homePort,
                        value: vessel.homePort),
                    const SizedBox(width: 10),
                    _InfoChip(
                        icon: Icons.anchor,
                        label: t.workingPort,
                        value: vessel.workingPort.isEmpty
                            ? '—'
                            : vessel.workingPort),
                  ],
                ),
                if (vessel.photoAsset.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      vessel.photoAsset,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
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
  const _InfoChip(
      {required this.icon, required this.label, required this.value});

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
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
