import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/urgent_notification.dart';
import '../models/vessel.dart';
import '../state/urgent_notification_provider.dart';
import '../theme/app_colors.dart';

String alertTypeLabel(AppLocalizations t, AlertType type) {
  switch (type) {
    case AlertType.fire:
      return t.alertTypeFire;
    case AlertType.flooding:
      return t.alertTypeFlooding;
    case AlertType.engineFailure:
      return t.alertTypeEngineFailure;
    case AlertType.routing:
      return t.alertTypeRouting;
    case AlertType.other:
      return t.alertTypeOther;
  }
}

IconData alertTypeIcon(AlertType type) {
  switch (type) {
    case AlertType.fire:
      return Icons.local_fire_department;
    case AlertType.flooding:
      return Icons.water;
    case AlertType.engineFailure:
      return Icons.engineering;
    case AlertType.routing:
      return Icons.route;
    case AlertType.other:
      return Icons.error_outline;
  }
}

class UrgentNotificationsScreen extends StatelessWidget {
  final Vessel vessel;
  const UrgentNotificationsScreen({super.key, required this.vessel});

  String _escalationLabel(AppLocalizations t, EscalationStatus s) {
    switch (s) {
      case EscalationStatus.notAcknowledged:
        return t.escalationNotAcknowledged;
      case EscalationStatus.acknowledged:
        return t.escalationAcknowledged;
      case EscalationStatus.resolved:
        return t.escalationResolved;
    }
  }

  Color _escalationColor(EscalationStatus s) {
    switch (s) {
      case EscalationStatus.notAcknowledged:
        return AppColors.statusMaintenance;
      case EscalationStatus.acknowledged:
        return AppColors.amber400;
      case EscalationStatus.resolved:
        return AppColors.statusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<UrgentNotificationProvider>();
    final notifications = provider.forVessel(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.urgentNotifications} — ${vessel.name}'),
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddSheet(context, t)),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(t.noUrgentNotifications,
                  style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = notifications[index];
                final color = _escalationColor(n.escalationStatus);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showDetailSheet(context, t, n),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(alertTypeIcon(n.alertType), color: color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alertTypeLabel(t, n.alertType),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _escalationLabel(t, n.escalationStatus),
                                        style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(n.location,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Text(dateFmt.format(n.timestamp),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDetailSheet(
      BuildContext context, AppLocalizations t, UrgentNotification n) {
    final provider = context.read<UrgentNotificationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
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
              Text(alertTypeLabel(t, n.alertType),
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(n.location,
                  style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Text(n.description,
                  style: Theme.of(sheetContext).textTheme.bodyLarge),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (n.escalationStatus == EscalationStatus.notAcknowledged)
                    OutlinedButton(
                      onPressed: () {
                        provider.updateStatus(
                            n.id, EscalationStatus.acknowledged);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.markAcknowledged),
                    ),
                  if (n.escalationStatus != EscalationStatus.resolved)
                    OutlinedButton(
                      onPressed: () {
                        provider.updateStatus(n.id, EscalationStatus.resolved);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.markResolved),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      provider.delete(n.id);
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.statusMaintenance),
                    label: Text(t.delete,
                        style: const TextStyle(
                            color: AppColors.statusMaintenance)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSheet(BuildContext context, AppLocalizations t) {
    final locationController = TextEditingController();
    final descController = TextEditingController();
    AlertType alertType = AlertType.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.addUrgentNotification,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AlertType>(
                      initialValue: alertType,
                      decoration: InputDecoration(labelText: t.alertTypeLabel),
                      items: AlertType.values
                          .map((v) => DropdownMenuItem(
                              value: v, child: Text(alertTypeLabel(t, v))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => alertType = v ?? alertType),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: locationController,
                      decoration:
                          InputDecoration(labelText: t.locationOnVesselLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          InputDecoration(labelText: t.defectDescriptionLabel),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusMaintenance),
                        onPressed: () {
                          if (descController.text.trim().isEmpty) return;
                          context.read<UrgentNotificationProvider>().add(
                                vesselId: vessel.id,
                                alertType: alertType,
                                location: locationController.text.trim(),
                                description: descController.text.trim(),
                              );
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(t.raiseAlert),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
