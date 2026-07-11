import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/fleet_data.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/vessel.dart';
import '../state/tank_data_provider.dart';
import '../state/urgent_notification_provider.dart';
import '../state/vessel_profile_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/alerts_panel.dart';
import '../widgets/defects_panel.dart';
import '../widgets/stat_tile.dart';
import '../widgets/urgent_alerts_banner.dart';
import '../widgets/vessel_card.dart';
import 'settings_screen.dart';
import 'vessel_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  VesselStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final profiles = context.watch<VesselProfileProvider>();
    final vessels = FleetData.vessels.map(profiles.resolve).toList();
    final filtered = vessels
        .where((v) =>
            (_statusFilter == null || v.status == _statusFilter) &&
            (v.name.toLowerCase().contains(_query.toLowerCase()) ||
                v.homePort.toLowerCase().contains(_query.toLowerCase()) ||
                v.workingPort.toLowerCase().contains(_query.toLowerCase())))
        .toList();

    final activeCount =
        vessels.where((v) => v.status == VesselStatus.active).length;
    final portCount =
        vessels.where((v) => v.status == VesselStatus.port).length;
    final avgFuel = vessels.isEmpty
        ? 0.0
        : vessels.fold<double>(0, (sum, v) => sum + data.avgFuelPercent(v)) /
            vessels.length;
    final alerts = data.alertsFor(vessels);
    final criticalDefects = data.criticalOpenDefects(vessels);
    final urgentNotifications = context
        .watch<UrgentNotificationProvider>()
        .unacknowledgedFleetWide(vessels.map((v) => v.id).toList());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                t: t,
                activeCount: activeCount,
                portCount: portCount,
                alertCount: alerts.length +
                    criticalDefects.length +
                    urgentNotifications.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.directions_boat_filled,
                        value: '${vessels.length}',
                        label: t.totalVessels,
                        accent: AppColors.teal400,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.check_circle,
                        value: '$activeCount',
                        label: t.activeVessels,
                        accent: AppColors.statusActive,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.anchor,
                        value: '$portCount',
                        label: t.inPort,
                        accent: AppColors.statusPort,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: Icons.speed,
                        value: '${(avgFuel * 100).round()}%',
                        label: t.avgFuelLevel,
                        accent: AppColors.amber400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (urgentNotifications.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: UrgentAlertsBanner(
                      notifications: urgentNotifications, vessels: vessels),
                ),
              ),
            if (alerts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(child: AlertsPanel(alerts: alerts)),
              ),
            if (criticalDefects.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child:
                      DefectsPanel(defects: criticalDefects, vessels: vessels),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      t.fleetLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filtered.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: t.searchVessels,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 0, 4),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: t.filterAll,
                        selected: _statusFilter == null,
                        onTap: () => setState(() => _statusFilter = null),
                      ),
                      _FilterChip(
                        label: t.statusActive,
                        color: AppColors.statusActive,
                        selected: _statusFilter == VesselStatus.active,
                        onTap: () => setState(
                            () => _statusFilter = VesselStatus.active),
                      ),
                      _FilterChip(
                        label: t.statusInPort,
                        color: AppColors.statusPort,
                        selected: _statusFilter == VesselStatus.port,
                        onTap: () =>
                            setState(() => _statusFilter = VesselStatus.port),
                      ),
                      _FilterChip(
                        label: t.statusStandby,
                        color: AppColors.statusStandby,
                        selected: _statusFilter == VesselStatus.standby,
                        onTap: () => setState(
                            () => _statusFilter = VesselStatus.standby),
                      ),
                      _FilterChip(
                        label: t.statusMaintenance,
                        color: AppColors.statusMaintenance,
                        selected: _statusFilter == VesselStatus.maintenance,
                        onTap: () => setState(
                            () => _statusFilter = VesselStatus.maintenance),
                      ),
                      _FilterChip(
                        label: t.statusOffHire,
                        color: AppColors.statusOffHire,
                        selected: _statusFilter == VesselStatus.offHire,
                        onTap: () => setState(
                            () => _statusFilter = VesselStatus.offHire),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(t.noResults,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final vessel = filtered[index];
                    return VesselCard(
                      vessel: vessel,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VesselDetailScreen(vessel: vessel),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppLocalizations t;
  final int activeCount;
  final int portCount;
  final int alertCount;

  const _Header({
    required this.t,
    required this.activeCount,
    required this.portCount,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final today = DateFormat('EEEE, d MMMM yyyy', locale).format(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy900.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.directions_boat_filled,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.dashboardTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.dashboardSubtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                today,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _HeaderPulse(
                icon: Icons.check_circle,
                label: '$activeCount',
                color: AppColors.statusActive,
              ),
              const SizedBox(width: 8),
              _HeaderPulse(
                icon: Icons.anchor,
                label: '$portCount',
                color: AppColors.statusPort,
              ),
              if (alertCount > 0) ...[
                const SizedBox(width: 8),
                _HeaderPulse(
                  icon: Icons.warning_amber_rounded,
                  label: '$alertCount',
                  color: AppColors.amber400,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPulse extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeaderPulse(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final accent = color ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? (dark ? Colors.white : scheme.onSurface)
                        : scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
