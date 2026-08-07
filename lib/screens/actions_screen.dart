import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/fleet_data.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/superintendent_action.dart';
import '../state/action_provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/risk_presentation.dart';

/// Superintendent Action Center: the follow-up list that detected risks turn
/// into. Four views — My actions, Fleet, Overdue, Critical — over one shared
/// cloud-backed list, so an action raised on the bridge and one raised in the
/// office are the same record.
class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<ActionProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.actionsTitle),
          automaticallyImplyLeading: Navigator.of(context).canPop(),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: t.actionAdd,
              onPressed: () => showActionSheet(context, t),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: t.actionsMine),
              Tab(text: t.actionsFleet),
              Tab(text: t.actionsOverdue),
              Tab(text: t.actionsCritical),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _ActionList(items: provider.mine(user?.username ?? '')),
              _ActionList(items: provider.open),
              _ActionList(items: provider.overdue),
              _ActionList(items: provider.critical),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final List<SuperintendentAction> items;
  const _ActionList({required this.items});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(t.noActions,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.slate400)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, i) => _ActionCard(action: items[i]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final SuperintendentAction action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final vesselName = FleetData.vessels
        .firstWhere((v) => v.id == action.vesselId,
            orElse: () => FleetData.vessels.first)
        .name
        .replaceFirst('Maridive ', '');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RiskChip(
                    label: priorityLabel(t, action.priority),
                    color: priorityColor(action.priority)),
                Gaps.w8,
                Flexible(
                  child: Text(vesselName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                if (action.isOverdue) ...[
                  Gaps.w8,
                  RiskChip(
                      label: t.actionOverdueBadge,
                      color: AppColors.statusExpired,
                      icon: Icons.schedule),
                ],
                const Spacer(),
                _StatusMenu(action: action),
              ],
            ),
            Gaps.h8,
            Text(action.title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (action.recommendation.isNotEmpty) ...[
              Gaps.h4,
              Text(action.recommendation,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            Gaps.h8,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              children: [
                _MetaLine(
                  icon: Icons.flag_outlined,
                  text: actionStatusLabel(t, action.status),
                ),
                if (action.assignedTo.isNotEmpty)
                  _MetaLine(
                      icon: Icons.person_outline, text: action.assignedTo),
                _MetaLine(
                  icon: Icons.event_outlined,
                  text: action.dueDate == null
                      ? t.noDueDate
                      : DateFormat.yMMMd(locale).format(action.dueDate!),
                  color: action.isOverdue ? AppColors.statusExpired : null,
                ),
                if (action.sourceType.isNotEmpty)
                  _MetaLine(
                      icon: Icons.link,
                      text: sourceModuleLabel(t, action.sourceType)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _MetaLine({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.slate400;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        Gaps.w4,
        Text(text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c)),
      ],
    );
  }
}

class _StatusMenu extends StatelessWidget {
  final SuperintendentAction action;
  const _StatusMenu({required this.action});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (value) async {
        final provider = context.read<ActionProvider>();
        if (value == 'edit') {
          showActionSheet(context, t, existing: action);
          return;
        }
        if (value == 'delete') {
          final ok = await confirmDelete(context, itemName: action.title);
          if (ok) await provider.delete(action.id);
          return;
        }
        final status = SuperActionStatus.values.asNameMap()[value];
        if (status != null) await provider.setStatus(action.id, status);
      },
      itemBuilder: (context) => [
        for (final s in SuperActionStatus.values)
          if (s != action.status)
            PopupMenuItem(
                value: s.name, child: Text(actionStatusLabel(t, s))),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'edit', child: Text(t.actionEdit)),
        PopupMenuItem(value: 'delete', child: Text(t.delete)),
      ],
    );
  }
}

/// Add / edit sheet. Shared with the Command Center so an action can be
/// raised from anywhere the superintendent spots something.
Future<void> showActionSheet(
  BuildContext context,
  AppLocalizations t, {
  SuperintendentAction? existing,
  String? presetVesselId,
}) async {
  final provider = context.read<ActionProvider>();
  final user = context.read<AuthProvider>().currentUser;

  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final recCtrl = TextEditingController(text: existing?.recommendation ?? '');
  final assigneeCtrl = TextEditingController(text: existing?.assignedTo ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  var vesselId =
      existing?.vesselId ?? presetVesselId ?? FleetData.vessels.first.id;
  var priority = existing?.priority ?? ActionPriority.medium;
  DateTime? dueDate = existing?.dueDate;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? t.actionAdd : t.actionEdit,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              Gaps.h16,
              DropdownButtonFormField<String>(
                initialValue: vesselId,
                decoration: InputDecoration(labelText: t.vesselLabel),
                items: [
                  for (final v in FleetData.vessels)
                    DropdownMenuItem(
                        value: v.id,
                        child: Text(v.name.replaceFirst('Maridive ', ''))),
                ],
                onChanged: (v) =>
                    setSheetState(() => vesselId = v ?? vesselId),
              ),
              Gaps.h12,
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: t.actionTitleLabel),
                maxLines: 2,
                minLines: 1,
              ),
              Gaps.h12,
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(labelText: t.maintenanceDescLabel),
                maxLines: 3,
                minLines: 1,
              ),
              Gaps.h12,
              TextField(
                controller: recCtrl,
                decoration: InputDecoration(labelText: t.recommendationLabel),
                maxLines: 3,
                minLines: 1,
              ),
              Gaps.h12,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ActionPriority>(
                      initialValue: priority,
                      decoration: InputDecoration(labelText: t.priorityLabel),
                      items: [
                        for (final p in ActionPriority.values)
                          DropdownMenuItem(
                              value: p, child: Text(priorityLabel(t, p))),
                      ],
                      onChanged: (p) =>
                          setSheetState(() => priority = p ?? priority),
                    ),
                  ),
                  Gaps.w12,
                  Expanded(
                    child: TextField(
                      controller: assigneeCtrl,
                      decoration:
                          InputDecoration(labelText: t.assignedToLabel),
                    ),
                  ),
                ],
              ),
              Gaps.h12,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(dueDate == null
                          ? t.noDueDate
                          : DateFormat.yMMMd(
                                  Localizations.localeOf(sheetContext)
                                      .languageCode)
                              .format(dueDate!)),
                      onPressed: () async {
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
                    ),
                  ),
                  if (dueDate != null)
                    IconButton(
                      tooltip: t.clearDueDate,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setSheetState(() => dueDate = null),
                    ),
                ],
              ),
              Gaps.h12,
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(labelText: t.notesLabel),
                maxLines: 3,
                minLines: 1,
              ),
              Gaps.h20,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    if (existing == null) {
                      await provider.add(
                        vesselId: vesselId,
                        title: title,
                        description: descCtrl.text.trim(),
                        recommendation: recCtrl.text.trim(),
                        priority: priority,
                        assignedTo: assigneeCtrl.text.trim(),
                        dueDate: dueDate,
                        notes: notesCtrl.text.trim(),
                        createdBy: user?.username ?? '',
                      );
                    } else {
                      await provider.update(
                        id: existing.id,
                        title: title,
                        description: descCtrl.text.trim(),
                        recommendation: recCtrl.text.trim(),
                        priority: priority,
                        assignedTo: assigneeCtrl.text.trim(),
                        dueDate: dueDate,
                        notes: notesCtrl.text.trim(),
                      );
                    }
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: Text(t.save),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  titleCtrl.dispose();
  descCtrl.dispose();
  recCtrl.dispose();
  assigneeCtrl.dispose();
  notesCtrl.dispose();
}
