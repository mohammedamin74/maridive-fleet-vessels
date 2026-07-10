import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/daily_task.dart';
import '../state/daily_tasks_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/photo_picker.dart';
import 'daily_tasks_list_screen.dart';

class DailyTaskDetailScreen extends StatelessWidget {
  final DailyTask task;
  const DailyTaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<DailyTasksProvider>();
    final current = provider
        .forVessel(task.vesselId)
        .firstWhere((x) => x.id == task.id, orElse: () => task);

    return Scaffold(
      appBar: AppBar(
        title: Text(current.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              provider.delete(current.id);
              Navigator.of(context).pop();
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
                final commentController =
                    TextEditingController(text: item.comment);
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
          Text(t.evidencePhotosLabel,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          PhotoPickerStrip(
            photosBase64: current.photosBase64,
            onAdd: (encoded) => context
                .read<DailyTasksProvider>()
                .addPhoto(current.id, encoded),
            onRemove: (i) =>
                context.read<DailyTasksProvider>().removePhoto(current.id, i),
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
