import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/fleet_data.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/daily_task.dart';
import '../state/daily_tasks_provider.dart';
import '../state/vessel_profile_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/confirm_delete.dart';
import 'daily_tasks_list_screen.dart';

class DailyTaskDetailScreen extends StatefulWidget {
  final DailyTask task;
  const DailyTaskDetailScreen({super.key, required this.task});

  @override
  State<DailyTaskDetailScreen> createState() => _DailyTaskDetailScreenState();
}

class _DailyTaskDetailScreenState extends State<DailyTaskDetailScreen> {
  // Kept alive across provider-triggered rebuilds (e.g. toggling a checkbox)
  // so text typed into a comment field isn't wiped out mid-edit. Checklist
  // items are a fixed-size list set at task creation, so indexing is stable.
  final Map<int, TextEditingController> _commentControllers = {};

  TextEditingController _controllerFor(int index, String initialText) {
    return _commentControllers.putIfAbsent(
        index, () => TextEditingController(text: initialText));
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<DailyTasksProvider>();
    final current = provider
        .forVessel(widget.task.vesselId)
        .firstWhere((x) => x.id == widget.task.id, orElse: () => widget.task);

    return Scaffold(
      appBar: AppBar(
        title: Text(current.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: t.edit,
            onPressed: () {
              final vessel = FleetData.vessels
                  .firstWhere((v) => v.id == current.vesselId);
              final resolved =
                  context.read<VesselProfileProvider>().resolve(vessel);
              showDailyTaskSheet(context, t, resolved, existing: current);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: t.delete,
            onPressed: () async {
              final ok =
                  await confirmDelete(context, itemName: current.title);
              if (ok) {
                provider.delete(current.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(taskCategoryLabel(t, current.category),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${taskFrequencyLabel(t, current.frequency)} · ${current.assignedTo}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(t.checklistItemsLabel,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(current.checklistItems.length, (i) {
                final item = current.checklistItems[i];
                final commentController = _controllerFor(i, item.comment);
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: item.checked,
                        title: Text(item.label),
                        onChanged: (v) => context
                            .read<DailyTasksProvider>()
                            .toggleChecklistItem(current.id, i, v ?? false),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 44, right: 12, bottom: 10),
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                              hintText: t.commentHint, isDense: true),
                          onSubmitted: (v) => context
                              .read<DailyTasksProvider>()
                              .setChecklistComment(current.id, i, v),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Text(t.attachmentsLabel,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AttachmentPickerStrip(
            attachments: current.attachments,
            onAdd: (file) => context
                .read<DailyTasksProvider>()
                .addAttachment(current.id, file),
            onRemove: (i) => context
                .read<DailyTasksProvider>()
                .removeAttachment(current.id, i),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (current.status != TaskStatus.inProgress)
                OutlinedButton(
                  onPressed: () => context
                      .read<DailyTasksProvider>()
                      .updateStatus(current.id, TaskStatus.inProgress),
                  child: Text(t.markInProgress),
                ),
              if (current.status != TaskStatus.completed)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusActive),
                  onPressed: () => context
                      .read<DailyTasksProvider>()
                      .updateStatus(current.id, TaskStatus.completed),
                  child: Text(t.markCompleted),
                ),
              if (current.status == TaskStatus.completed)
                OutlinedButton(
                  onPressed: () => context
                      .read<DailyTasksProvider>()
                      .updateStatus(current.id, TaskStatus.pending),
                  child: Text(t.reopen),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
