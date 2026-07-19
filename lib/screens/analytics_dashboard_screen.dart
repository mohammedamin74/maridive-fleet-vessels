import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/fleet_data.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/defect.dart';
import '../models/requisition.dart';
import '../models/vessel.dart';
import '../state/tank_data_provider.dart';
import '../state/vessel_profile_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/stat_tile.dart';

/// Fleet-wide or per-vessel KPI/chart dashboard for Defects & Requisitions.
/// Pass [initialVessel] to open pre-filtered to that vessel; the vessel
/// filter row lets the user switch to "All Vessels" or any other vessel
/// without leaving the screen.
class AnalyticsDashboardScreen extends StatefulWidget {
  final Vessel? initialVessel;
  const AnalyticsDashboardScreen({super.key, this.initialVessel});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String? _vesselId;

  @override
  void initState() {
    super.initState();
    _vesselId = widget.initialVessel?.id;
  }

  String _defectStatusLabel(AppLocalizations t, DefectStatus s) {
    switch (s) {
      case DefectStatus.open:
        return t.statusOpenDefect;
      case DefectStatus.inProgress:
        return t.statusInProgress;
      case DefectStatus.closed:
        return t.statusClosedDefect;
    }
  }

  Color _defectStatusColor(DefectStatus s) {
    switch (s) {
      case DefectStatus.open:
        return AppColors.statusMaintenance;
      case DefectStatus.inProgress:
        return AppColors.amber400;
      case DefectStatus.closed:
        return AppColors.statusActive;
    }
  }

  String _defectPriorityLabel(AppLocalizations t, DefectPriority p) {
    switch (p) {
      case DefectPriority.low:
        return t.priorityLow;
      case DefectPriority.medium:
        return t.priorityMedium;
      case DefectPriority.high:
        return t.priorityHigh;
      case DefectPriority.critical:
        return t.severityCritical;
    }
  }

  Color _defectPriorityColor(DefectPriority p) {
    switch (p) {
      case DefectPriority.low:
        return AppColors.statusPort;
      case DefectPriority.medium:
        return AppColors.teal500;
      case DefectPriority.high:
        return AppColors.amber400;
      case DefectPriority.critical:
        return AppColors.statusMaintenance;
    }
  }

  String _reqStatusLabel(AppLocalizations t, RequisitionStatus s) {
    switch (s) {
      case RequisitionStatus.pending:
        return t.reqStatusPending;
      case RequisitionStatus.hodApproval:
        return t.reqStatusHod;
      case RequisitionStatus.technicalSupApproval:
        return t.reqStatusTechSup;
      case RequisitionStatus.approved:
        return t.reqStatusApproved;
      case RequisitionStatus.ordered:
        return t.reqStatusOrdered;
      case RequisitionStatus.received:
        return t.reqStatusReceived;
      case RequisitionStatus.rejected:
        return t.reqStatusRejected;
    }
  }

  Color _reqStatusColor(RequisitionStatus s) {
    switch (s) {
      case RequisitionStatus.pending:
        return AppColors.amber400;
      case RequisitionStatus.hodApproval:
      case RequisitionStatus.technicalSupApproval:
        return AppColors.navy500;
      case RequisitionStatus.approved:
        return AppColors.statusPort;
      case RequisitionStatus.ordered:
        return AppColors.teal500;
      case RequisitionStatus.received:
        return AppColors.statusActive;
      case RequisitionStatus.rejected:
        return AppColors.statusMaintenance;
    }
  }

  String _departmentLabel(AppLocalizations t, RequisitionDepartment d) {
    switch (d) {
      case RequisitionDepartment.engine:
        return t.departmentEngine;
      case RequisitionDepartment.deck:
        return t.departmentDeck;
      case RequisitionDepartment.steward:
        return t.departmentSteward;
    }
  }

  Color _departmentColor(RequisitionDepartment d) {
    switch (d) {
      case RequisitionDepartment.engine:
        return AppColors.teal500;
      case RequisitionDepartment.deck:
        return AppColors.navy500;
      case RequisitionDepartment.steward:
        return AppColors.amber400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final profiles = context.watch<VesselProfileProvider>();
    final vessels = FleetData.vessels.map(profiles.resolve).toList();
    Vessel? selectedVessel;
    if (_vesselId != null) {
      for (final v in vessels) {
        if (v.id == _vesselId) {
          selectedVessel = v;
          break;
        }
      }
    }

    final defects = _vesselId == null
        ? data.allDefects
        : data.allDefects.where((d) => d.vesselId == _vesselId).toList();
    final requisitions = _vesselId == null
        ? data.allRequisitions
        : data.allRequisitions.where((r) => r.vesselId == _vesselId).toList();

    final openDefects =
        defects.where((d) => d.status != DefectStatus.closed).length;
    final pendingReqs =
        requisitions.where((r) => r.status == RequisitionStatus.pending).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedVessel == null
            ? t.analyticsDashboard
            : '${t.analyticsDashboard} — ${selectedVessel.name}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _VesselChip(
                    label: t.allVessels,
                    selected: _vesselId == null,
                    onTap: () => setState(() => _vesselId = null),
                  ),
                  ...vessels.map((v) => _VesselChip(
                        label: v.name,
                        selected: _vesselId == v.id,
                        onTap: () => setState(() => _vesselId = v.id),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.report_problem_outlined,
                    value: '${defects.length}',
                    label: t.totalDefects,
                    accent: AppColors.navy500,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.error_outline,
                    value: '$openDefects',
                    label: t.openDefectsLabel,
                    accent: AppColors.statusMaintenance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.shopping_cart_outlined,
                    value: '${requisitions.length}',
                    label: t.totalRequisitions,
                    accent: AppColors.teal500,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    icon: Icons.hourglass_empty,
                    value: '$pendingReqs',
                    label: t.pendingRequisitionsLabel,
                    accent: AppColors.amber400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CategoryBarChart(
              title: t.defectsByStatus,
              emptyLabel: t.noData,
              entries: DefectStatus.values
                  .map((s) => ChartEntry(
                        label: _defectStatusLabel(t, s),
                        value: defects.where((d) => d.status == s).length,
                        color: _defectStatusColor(s),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            CategoryDonutChart(
              title: t.defectsByPriority,
              emptyLabel: t.noData,
              entries: DefectPriority.values
                  .map((p) => ChartEntry(
                        label: _defectPriorityLabel(t, p),
                        value: defects.where((d) => d.priority == p).length,
                        color: _defectPriorityColor(p),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            CategoryBarChart(
              title: t.requisitionsByStatus,
              emptyLabel: t.noData,
              entries: RequisitionStatus.values
                  .map((s) => ChartEntry(
                        label: _reqStatusLabel(t, s),
                        value:
                            requisitions.where((r) => r.status == s).length,
                        color: _reqStatusColor(s),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            CategoryDonutChart(
              title: t.requisitionsByDepartment,
              emptyLabel: t.noData,
              entries: RequisitionDepartment.values
                  .map((d) => ChartEntry(
                        label: _departmentLabel(t, d),
                        value: requisitions
                            .where((r) => r.department == d)
                            .length,
                        color: _departmentColor(d),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VesselChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VesselChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final accent = scheme.primary;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: dark ? 0.22 : 0.14)
                  : (dark ? AppColors.navy800 : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.7)
                    : (dark ? AppColors.navy700 : AppColors.slate200),
                width: selected ? 1.4 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? (dark ? Colors.white : scheme.onSurface)
                    : scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
