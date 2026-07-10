import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/fleet_data.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/vessel.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/alerts_panel.dart';
import '../widgets/stat_tile.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final vessels = FleetData.vessels;
    final filtered = vessels
        .where((v) => v.name.toLowerCase().contains(_query.toLowerCase()) ||
            v.homePort.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final activeCount = vessels.where((v) => v.status == VesselStatus.active).length;
    final portCount = vessels.where((v) => v.status == VesselStatus.port).length;
    final avgFuel = vessels.isEmpty
        ? 0.0
        : vessels.fold<double>(0, (sum, v) => sum + data.avgFuelPercent(v)) / vessels.length;
    final alerts = data.alertsFor(vessels);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(t: t)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: FontAwesomeIcons.ship,
                        value: '${vessels.length}',
                        label: t.totalVessels,
                        accent: AppColors.teal400,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: FontAwesomeIcons.circleCheck,
                        value: '$activeCount',
                        label: t.activeVessels,
                        accent: AppColors.statusActive,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: FontAwesomeIcons.anchor,
                        value: '$portCount',
                        label: t.inPort,
                        accent: AppColors.statusPort,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        icon: FontAwesomeIcons.gaugeHigh,
                        value: '${(avgFuel * 100).round()}%',
                        label: t.avgFuelLevel,
                        accent: AppColors.amber400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (alerts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(child: AlertsPanel(alerts: alerts)),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(t.noResults, style: Theme.of(context).textTheme.bodyMedium),
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
  const _Header({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(gradient: AppColors.heroGradient),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.dashboardTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.dashboardSubtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
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
    );
  }
}
