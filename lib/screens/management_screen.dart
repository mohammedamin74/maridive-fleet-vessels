import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../state/cash_meeting_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/category_tile.dart';
import 'cash_meeting_screen.dart';

/// Office/management hub reached from the fleet dashboard. Hosts the
/// fleet-level modules that belong to the office rather than a single
/// vessel — first up the Cash Meeting Sheet; future management modules
/// slot into the same grid.
class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final pendingCount = context.watch<CashMeetingProvider>().pendingCount;

    return Scaffold(
      appBar: AppBar(title: Text(t.managementTitle)),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final gutter = AppBreakpoints.pageGutter(constraints.maxWidth);
          return CustomScrollView(
            slivers: [
              if (pendingCount > 0)
                SliverPadding(
                  padding: gutter.add(
                      const EdgeInsetsDirectional.only(top: AppSpacing.lg)),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      color: AppColors.amber400.withValues(alpha: 0.12),
                      child: ListTile(
                        leading: const Icon(Icons.pending_actions,
                            color: AppColors.amber400),
                        title: Text(t.cashPendingBadge(pendingCount)),
                        onTap: () => _openCashMeeting(context),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: gutter.add(const EdgeInsetsDirectional.only(
                    top: AppSpacing.lg, bottom: AppSpacing.xxl)),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisExtent: 148,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                  ),
                  delegate: SliverChildListDelegate([
                    CategoryTile(
                      icon: Icons.request_quote_outlined,
                      title: t.cashMeetingTitle,
                      subtitle: t.cashMeetingSubtitle,
                      color: AppColors.teal500,
                      onTap: () => _openCashMeeting(context),
                    ),
                  ]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _openCashMeeting(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CashMeetingScreen()),
    );
  }
}
