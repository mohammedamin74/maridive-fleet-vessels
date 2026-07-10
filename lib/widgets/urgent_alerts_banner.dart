import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/urgent_notification.dart';
import '../models/vessel.dart';
import '../screens/urgent_notifications_screen.dart';
import '../theme/app_colors.dart';

/// Fleet-wide banner for unacknowledged emergency alerts (fire, flooding,
/// engine failure, etc.) — takes visual priority over the low-tank-level
/// and defect panels since these represent active incidents, not routine
/// maintenance items.
class UrgentAlertsBanner extends StatelessWidget {
  final List<UrgentNotification> notifications;
  final List<Vessel> vessels;
  const UrgentAlertsBanner(
      {super.key, required this.notifications, required this.vessels});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.statusMaintenance,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: const Icon(Icons.crisis_alert, color: Colors.white),
          title: Text(
            t.urgentAlertsTitle(notifications.length),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: notifications.map((n) {
            final vessel = vessels.firstWhere((v) => v.id == n.vesselId);
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(alertTypeIcon(n.alertType),
                  color: Colors.white, size: 20),
              title: Text(
                '${alertTypeLabel(t, n.alertType)} · ${vessel.name}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                n.location,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => UrgentNotificationsScreen(vessel: vessel)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
