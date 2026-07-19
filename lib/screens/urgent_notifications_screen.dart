import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/urgent_notification.dart';
import '../models/vessel.dart';
import '../state/urgent_notification_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import '../widgets/confirm_delete.dart';

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

String actionStatusLabel(AppLocalizations t, ActionStatus s) {
  switch (s) {
    case ActionStatus.pending:
      return t.taskStatusPending;
    case ActionStatus.inProgress:
      return t.statusInProgress;
    case ActionStatus.completed:
      return t.taskStatusCompleted;
  }
}

Color actionStatusColor(ActionStatus s) {
  switch (s) {
    case ActionStatus.pending:
      return AppColors.amber600;
    case ActionStatus.inProgress:
      return AppColors.statusPort;
    case ActionStatus.completed:
      return AppColors.statusActive;
  }
}

enum _NotifFilter { all, actions, overdue }

class UrgentNotificationsScreen extends StatefulWidget {
  final Vessel vessel;
  const UrgentNotificationsScreen({super.key, required this.vessel});

  @override
  State<UrgentNotificationsScreen> createState() =>
      _UrgentNotificationsScreenState();
}

class _UrgentNotificationsScreenState extends State<UrgentNotificationsScreen> {
  _NotifFilter _filter = _NotifFilter.all;

  Vessel get vessel => widget.vessel;

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

  List<UrgentNotification> _applyFilter(List<UrgentNotification> all) {
    switch (_filter) {
      case _NotifFilter.all:
        return all;
      case _NotifFilter.actions:
        return all.where((n) => n.isAction).toList();
      case _NotifFilter.overdue:
        return all.where((n) => n.isOverdue).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<UrgentNotificationProvider>();
    final all = provider.forVessel(vessel.id);
    final notifications = _applyFilter(all);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();
    final dueFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.urgentNotifications} — ${vessel.name}'),
        actions: [
          AiFillAction(onPressed: () => _extractFromFile(context, t)),
          IconButton(
              icon: const Icon(Icons.add),
              tooltip: t.addUrgentNotification,
              onPressed: () => _showAddSheet(context, t)),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            filter: _filter,
            actionCount: all.where((n) => n.isAction).length,
            overdueCount: all.where((n) => n.isOverdue).length,
            onChanged: (f) => setState(() => _filter = f),
            t: t,
          ),
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Text(
                        _filter == _NotifFilter.all
                            ? t.noUrgentNotifications
                            : t.noAssignedActions,
                        style: Theme.of(context).textTheme.bodyMedium))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return _NotificationCard(
                        n: n,
                        t: t,
                        dateFmt: dateFmt,
                        dueFmt: dueFmt,
                        escalationLabel: _escalationLabel(t, n.escalationStatus),
                        escalationColor: _escalationColor(n.escalationStatus),
                        onTap: () => _showDetailSheet(context, t, n),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(
      BuildContext context, AppLocalizations t, UrgentNotification n) {
    final provider = context.read<UrgentNotificationProvider>();
    final locale = Localizations.localeOf(context).languageCode;
    final dueFmt = DateFormat.yMMMd(locale);
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
          child: SingleChildScrollView(
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
                if (n.isAction) ...[
                  const SizedBox(height: 16),
                  _ActionDetail(n: n, t: t, dueFmt: dueFmt),
                ],
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
                    // Assigned-action workflow transitions.
                    if (n.isAction &&
                        n.actionStatus == ActionStatus.pending)
                      OutlinedButton.icon(
                        onPressed: () {
                          provider.updateActionStatus(
                              n.id, ActionStatus.inProgress);
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(t.markInProgress),
                      ),
                    if (n.isAction &&
                        n.actionStatus != ActionStatus.completed)
                      FilledButton.icon(
                        onPressed: () {
                          provider.updateActionStatus(
                              n.id, ActionStatus.completed);
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(t.markCompleted),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showAddSheet(context, t, existing: n);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(t.edit),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await confirmDelete(sheetContext,
                            itemName: n.description);
                        if (ok) {
                          provider.delete(n.id);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        }
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
          ),
        );
      },
    );
  }

  /// AI-assisted entry: extract an alert from an incident message/report,
  /// reviewed in the normal add sheet before saving.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final outcome =
        await pickAndExtract(context, t, kind: 'urgent_notification');
    if (outcome == null || !context.mounted) return;
    _showAddSheet(context, t, prefill: outcome.result.fields);
  }

  void _showAddSheet(BuildContext context, AppLocalizations t,
      {Map<String, dynamic>? prefill, UrgentNotification? existing}) {
    final locationController = TextEditingController(
        text: existing?.location ?? aiStr(prefill, 'location'));
    final descController = TextEditingController(
        text: existing?.description ?? aiStr(prefill, 'description'));
    final assigneeController =
        TextEditingController(text: existing?.assignee ?? '');
    AlertType alertType = existing?.alertType ??
        aiEnum(prefill, 'alertType', AlertType.values, AlertType.other);
    bool isAction = existing?.isAction ?? false;
    DateTime? dueDate = existing?.dueDate;
    final locale = Localizations.localeOf(context).languageCode;
    final dueFmt = DateFormat.yMMMd(locale);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                    Text(existing != null ? t.edit : t.addUrgentNotification,
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
                          setSheetState(() => alertType = v ?? alertType),
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
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isAction,
                      title: Text(t.assignToManagement),
                      secondary: const Icon(Icons.assignment_ind_outlined),
                      onChanged: (v) => setSheetState(() => isAction = v),
                    ),
                    if (isAction) ...[
                      TextField(
                        controller: assigneeController,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            InputDecoration(labelText: t.assignedToLabel),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: sheetContext,
                            initialDate: dueDate ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setSheetState(() => dueDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.event_outlined, size: 20),
                              const SizedBox(width: 10),
                              Text(dueDate == null
                                  ? t.setDueDate
                                  : '${t.dueDateLabel}: ${dueFmt.format(dueDate!)}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusMaintenance),
                        onPressed: () {
                          if (descController.text.trim().isEmpty) return;
                          final assignee = isAction &&
                                  assigneeController.text.trim().isNotEmpty
                              ? assigneeController.text.trim()
                              : null;
                          if (existing != null) {
                            context.read<UrgentNotificationProvider>().update(
                                  id: existing.id,
                                  alertType: alertType,
                                  location: locationController.text.trim(),
                                  description: descController.text.trim(),
                                  isAction: isAction,
                                  assignee: assignee,
                                  dueDate: isAction ? dueDate : null,
                                );
                          } else {
                            context.read<UrgentNotificationProvider>().add(
                                  vesselId: vessel.id,
                                  alertType: alertType,
                                  location: locationController.text.trim(),
                                  description: descController.text.trim(),
                                  isAction: isAction,
                                  assignee: assignee,
                                  dueDate: isAction ? dueDate : null,
                                );
                          }
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(existing != null ? t.save : t.raiseAlert),
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

/// Segmented filter above the list: All · Actions · Overdue.
class _FilterBar extends StatelessWidget {
  final _NotifFilter filter;
  final int actionCount;
  final int overdueCount;
  final ValueChanged<_NotifFilter> onChanged;
  final AppLocalizations t;

  const _FilterBar({
    required this.filter,
    required this.actionCount,
    required this.overdueCount,
    required this.onChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    // Only surface the filter once there is at least one assigned action.
    if (actionCount == 0) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 12),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(t.filterAll),
            selected: filter == _NotifFilter.all,
            onSelected: (_) => onChanged(_NotifFilter.all),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('${t.filterActions} ($actionCount)'),
            selected: filter == _NotifFilter.actions,
            onSelected: (_) => onChanged(_NotifFilter.actions),
          ),
          if (overdueCount > 0) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text('${t.taskStatusOverdue} ($overdueCount)'),
              labelStyle: const TextStyle(color: AppColors.statusMaintenance),
              selected: filter == _NotifFilter.overdue,
              onSelected: (_) => onChanged(_NotifFilter.overdue),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final UrgentNotification n;
  final AppLocalizations t;
  final DateFormat dateFmt;
  final DateFormat dueFmt;
  final String escalationLabel;
  final Color escalationColor;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.n,
    required this.t,
    required this.dateFmt,
    required this.dueFmt,
    required this.escalationLabel,
    required this.escalationColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = n.isOverdue;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: overdue
          ? RoundedRectangleBorder(
              side: const BorderSide(
                  color: AppColors.statusMaintenance, width: 1.5),
              borderRadius: BorderRadius.circular(12))
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(alertTypeIcon(n.alertType), color: escalationColor),
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: escalationColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            escalationLabel,
                            style: TextStyle(
                                color: escalationColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.location,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(dateFmt.format(n.timestamp),
                        style: Theme.of(context).textTheme.bodyMedium),
                    if (n.isAction) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Pill(
                            icon: Icons.assignment_ind_outlined,
                            label: n.assignee?.isNotEmpty == true
                                ? n.assignee!
                                : t.unassignedLabel,
                            color: AppColors.navy600,
                          ),
                          _Pill(
                            icon: Icons.flag_outlined,
                            label: actionStatusLabel(t, n.actionStatus),
                            color: actionStatusColor(n.actionStatus),
                          ),
                          if (n.dueDate != null)
                            _Pill(
                              icon: Icons.event_outlined,
                              label: overdue
                                  ? '${t.taskStatusOverdue}: ${dueFmt.format(n.dueDate!)}'
                                  : '${t.dueDateLabel}: ${dueFmt.format(n.dueDate!)}',
                              color: overdue
                                  ? AppColors.statusMaintenance
                                  : AppColors.slate600,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail block for an assigned action, shown inside the detail sheet.
class _ActionDetail extends StatelessWidget {
  final UrgentNotification n;
  final AppLocalizations t;
  final DateFormat dueFmt;

  const _ActionDetail(
      {required this.n, required this.t, required this.dueFmt});

  @override
  Widget build(BuildContext context) {
    final overdue = n.isOverdue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navy100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: overdue
            ? Border.all(color: AppColors.statusMaintenance, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined,
                  size: 18, color: AppColors.navy600),
              const SizedBox(width: 8),
              Text(t.managementAction,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          _kv(context, t.assignedToLabel,
              n.assignee?.isNotEmpty == true ? n.assignee! : t.unassignedLabel),
          _kv(context, t.vesselStatusLabel, actionStatusLabel(t, n.actionStatus),
              valueColor: actionStatusColor(n.actionStatus)),
          if (n.dueDate != null)
            _kv(context, t.dueDateLabel, dueFmt.format(n.dueDate!),
                valueColor: overdue ? AppColors.statusMaintenance : null),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.slate600)),
          ),
          Expanded(
            child: Text(v,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
