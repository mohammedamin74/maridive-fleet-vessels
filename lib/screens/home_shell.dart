import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/sync_queue.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'ai_assistant_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

/// Honest offline indicator: shown whenever a write hasn't reached Supabase
/// yet, so a mariner never trusts a save the cloud hasn't actually received.
class _PendingSyncBanner extends StatelessWidget {
  const _PendingSyncBanner();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ValueListenableBuilder<int>(
      valueListenable: SyncQueue.instance.pendingCount,
      builder: (context, count, _) {
        if (count == 0) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          color: AppColors.amber400.withValues(alpha: 0.16),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 16, color: AppColors.amber400),
              const SizedBox(width: 8),
              Text(
                t.pendingSyncBanner(count),
                style: const TextStyle(
                    color: AppColors.amber400,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Adaptive top-level shell: NavigationRail on wide viewports, NavigationBar
/// on narrow. Lives at the app's root route — deeper flows (vessel detail and
/// its modules) keep pushing full-window routes on the root Navigator, which
/// cover the shell; popping returns here with tab state intact.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// Tabs are materialized on first visit so the first frame only builds the
  /// dashboard; after that IndexedStack keeps every visited tab's state.
  final Set<int> _built = {0};

  static const _icons = [
    (Icons.directions_boat_outlined, Icons.directions_boat_filled),
    (Icons.insights_outlined, Icons.insights),
    (Icons.smart_toy_outlined, Icons.smart_toy),
    (Icons.settings_outlined, Icons.settings),
  ];

  Widget _tab(int i) => switch (i) {
        0 => const DashboardScreen(),
        1 => const AnalyticsDashboardScreen(),
        2 => const AiAssistantScreen(),
        _ => const SettingsScreen(),
      };

  void _select(int i) => setState(() {
        _index = i;
        _built.add(i);
      });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final labels = [t.navFleet, t.navAnalytics, t.navAssistant, t.settings];
    final body = Column(
      children: [
        const _PendingSyncBanner(),
        Expanded(
          child: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < 4; i++)
                _built.contains(i) ? _tab(i) : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= AppBreakpoints.medium) {
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (var i = 0; i < 4; i++)
                      NavigationRailDestination(
                        icon: Icon(_icons[i].$1),
                        selectedIcon: Icon(_icons[i].$2),
                        label: Text(labels[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: body),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            for (var i = 0; i < 4; i++)
              NavigationDestination(
                icon: Icon(_icons[i].$1),
                selectedIcon: Icon(_icons[i].$2),
                label: labels[i],
              ),
          ],
        ),
      );
    });
  }
}
