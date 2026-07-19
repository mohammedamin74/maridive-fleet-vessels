import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/daily_task.dart';
import '../models/vessel.dart';
import '../services/report_service.dart';
import '../state/daily_tasks_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import '../widgets/export_feedback.dart';
import 'daily_task_detail_screen.dart';
import 'report_preview_screen.dart';

String taskCategoryLabel(AppLocalizations t, TaskCategory c) {
  switch (c) {
    case TaskCategory.engineRoomRounds:
      return t.categoryEngineRoomRounds;
    case TaskCategory.deckRounds:
      return t.categoryDeckRounds;
    case TaskCategory.safetyEquipmentChecks:
      return t.categorySafetyEquipment;
    case TaskCategory.navigationEquipmentTests:
      return t.categoryNavigationEquipment;
    case TaskCategory.galleyHygieneInspections:
      return t.categoryGalleyHygiene;
  }
}

String taskFrequencyLabel(AppLocalizations t, TaskFrequency f) {
  switch (f) {
    case TaskFrequency.daily:
      return t.frequencyDaily;
    case TaskFrequency.everyWatch:
      return t.frequencyEveryWatch;
    case TaskFrequency.weekly:
      return t.frequencyWeekly;
  }
}

String taskStatusLabel(AppLocalizations t, TaskStatus s) {
  switch (s) {
    case TaskStatus.pending:
      return t.taskStatusPending;
    case TaskStatus.inProgress:
      return t.statusInProgress;
    case TaskStatus.completed:
      return t.taskStatusCompleted;
  }
}

List<String> defaultChecklistFor(AppLocalizations t, TaskCategory c) {
  switch (c) {
    case TaskCategory.engineRoomRounds:
      return [
        t.checklistEngineOilPressure,
        t.checklistEngineCoolingWaterTemp,
        t.checklistBilgesLeaks,
        t.checklistGeneratorParams,
      ];
    case TaskCategory.deckRounds:
      return [
        t.checklistMooringLines,
        t.checklistDeckLighting,
        t.checklistCargoEquipment,
      ];
    case TaskCategory.safetyEquipmentChecks:
      return [
        t.checklistLifeboatMechanism,
        t.checklistFireExtinguisher,
        t.checklistEmergencyAlarm,
        t.checklistLifeJackets,
      ];
    case TaskCategory.navigationEquipmentTests:
      return [
        t.checklistRadarArpa,
        t.checklistGpsAccuracy,
        t.checklistSteeringGear,
      ];
    case TaskCategory.galleyHygieneInspections:
      return [
        t.checklistGalleyCleanliness,
        t.checklistFoodStorageTemp,
        t.checklistPestControl,
      ];
  }
}

/// Mirrors [ReportService.exportDailyTasksReport]'s columns so the in-app
/// review shows exactly what the PDF export would contain.
ReportSection _dailyTasksSection(AppLocalizations t, List<DailyTask> tasks) {
  return ReportSection(
    t.dailyTasks,
    [
      t.taskTitleLabel,
      t.taskCategoryLabel,
      t.frequencyLabel,
      t.scheduledTimeLabel,
      t.status,
      t.checklistItemsLabel,
      t.attachmentsLabel,
    ],
    tasks.map((task) {
      final checkedCount = task.checklistItems.where((c) => c.checked).length;
      return [
        task.title,
        taskCategoryLabel(t, task.category),
        taskFrequencyLabel(t, task.frequency),
        DateFormat.yMMMd().add_Hm().format(task.scheduledTime),
        task.isOverdue ? t.taskStatusOverdue : taskStatusLabel(t, task.status),
        '$checkedCount/${task.checklistItems.length}',
        task.attachments.isEmpty ? '—' : '${task.attachments.length}',
      ];
    }).toList(),
  );
}

class DailyTasksListScreen extends StatelessWidget {
  final Vessel vessel;
  const DailyTasksListScreen({super.key, required this.vessel});

  Color _statusColor(DailyTask task) {
    if (task.isOverdue) return AppColors.statusMaintenance;
    switch (task.status) {
      case TaskStatus.pending:
        return AppColors.amber400;
      case TaskStatus.inProgress:
        return AppColors.navy500;
      case TaskStatus.completed:
        return AppColors.statusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<DailyTasksProvider>();
    final tasks = provider.forVessel(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.dailyTasks} — ${vessel.name}'),
        actions: [
          AiFillAction(onPressed: () => _extractFromFile(context, t)),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: t.reviewReport,
            onPressed: tasks.isEmpty
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReportPreviewScreen(
                        vessel: vessel,
                        sections: [_dailyTasksSection(t, tasks)]))),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: t.exportReport,
            onPressed: tasks.isEmpty
                ? null
                : () => exportPdfWithFeedback(context, t,
                    () => ReportService.exportDailyTasksReport(
                        vessel: vessel, tasks: tasks)),
          ),
          IconButton(
              icon: const Icon(Icons.add),
              tooltip: t.add,
              onPressed: () => _showAddSheet(context, t)),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Text(t.noDailyTasks,
                  style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = tasks[index];
                final color = _statusColor(task);
                final checkedCount =
                    task.checklistItems.where((c) => c.checked).length;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => DailyTaskDetailScreen(task: task)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(task.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  task.isOverdue
                                      ? t.taskStatusOverdue
                                      : taskStatusLabel(t, task.status),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(taskCategoryLabel(t, task.category),
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (task.checklistItems.isNotEmpty)
                                Text(
                                  '$checkedCount/${task.checklistItems.length}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (task.attachments.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.attach_file,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 2),
                                Text('${task.attachments.length}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                              const Spacer(),
                              Text(dateFmt.format(task.scheduledTime),
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
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

  /// AI-assisted entry: each task/round found in a work plan is reviewed in
  /// the normal add sheet before it is saved.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'daily_task');
    if (outcome == null) return;
    final items = outcome.result.items ?? [];
    for (var i = 0; i < items.length; i++) {
      if (!context.mounted) return;
      await _showAddSheet(
        context,
        t,
        prefill: items[i],
        progressLabel: items.length > 1 ? '(${i + 1}/${items.length})' : null,
      );
    }
  }

  Future<void> _showAddSheet(
    BuildContext context,
    AppLocalizations t, {
    Map<String, dynamic>? prefill,
    String? progressLabel,
    DailyTask? existing,
  }) =>
      showDailyTaskSheet(context, t, vessel,
          prefill: prefill, progressLabel: progressLabel, existing: existing);
}

/// Add/edit sheet for a daily task. Public so [DailyTaskDetailScreen] can
/// open it pre-filled via [existing] for its Edit action.
Future<void> showDailyTaskSheet(
  BuildContext context,
  AppLocalizations t,
  Vessel vessel, {
  Map<String, dynamic>? prefill,
  String? progressLabel,
  DailyTask? existing,
}) {
    TaskCategory category = existing?.category ??
        aiEnum(prefill, 'category', TaskCategory.values,
            TaskCategory.engineRoomRounds);
    final titleController = TextEditingController(
        text: existing?.title ?? aiStr(prefill, 'title'));
    final assignedController = TextEditingController(
        text: existing?.assignedTo ?? aiStr(prefill, 'assignedTo'));
    final checklistController = TextEditingController(
      text: existing != null
          ? existing.checklistItems.map((c) => c.label).join('\n')
          : defaultChecklistFor(t, category).join('\n'),
    );
    TaskFrequency frequency = existing?.frequency ??
        aiEnum(prefill, 'frequency', TaskFrequency.values, TaskFrequency.daily);
    DateTime scheduledTime = existing?.scheduledTime ??
        aiDate(prefill, 'scheduledTime') ??
        DateTime.now();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final locale = Localizations.localeOf(sheetContext).languageCode;
            final dateFmt = DateFormat.yMMMd(locale).add_Hm();
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
                    Text(
                        [
                          existing != null ? t.edit : t.addDailyTask,
                          if (progressLabel != null) progressLabel,
                        ].join(' '),
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskCategory>(
                      initialValue: category,
                      decoration:
                          InputDecoration(labelText: t.taskCategoryLabel),
                      items: TaskCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(taskCategoryLabel(t, c))))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          category = v;
                          checklistController.text =
                              defaultChecklistFor(t, v).join('\n');
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: t.taskTitleLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: assignedController,
                      decoration: InputDecoration(labelText: t.assignedToLabel),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<TaskFrequency>(
                      initialValue: frequency,
                      decoration: InputDecoration(labelText: t.frequencyLabel),
                      items: TaskFrequency.values
                          .map((f) => DropdownMenuItem(
                              value: f, child: Text(taskFrequencyLabel(t, f))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => frequency = v ?? frequency),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: sheetContext,
                          initialDate: scheduledTime,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date == null || !sheetContext.mounted) return;
                        final time = await showTimePicker(
                          context: sheetContext,
                          initialTime: TimeOfDay.fromDateTime(scheduledTime),
                        );
                        setState(() => scheduledTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? 0,
                              time?.minute ?? 0,
                            ));
                      },
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: t.scheduledTimeLabel),
                        child: Text(dateFmt.format(scheduledTime)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(t.checklistItemsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    TextField(
                      controller: checklistController,
                      minLines: 3,
                      maxLines: 6,
                      decoration:
                          InputDecoration(hintText: t.checklistItemsHint),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          if (existing != null) {
                            context.read<DailyTasksProvider>().update(
                                  id: existing.id,
                                  category: category,
                                  title: titleController.text.trim(),
                                  assignedTo: assignedController.text.trim(),
                                  frequency: frequency,
                                  scheduledTime: scheduledTime,
                                );
                          } else {
                            final labels = checklistController.text
                                .split('\n')
                                .map((l) => l.trim())
                                .where((l) => l.isNotEmpty)
                                .toList();
                            context.read<DailyTasksProvider>().add(
                                  vesselId: vessel.id,
                                  category: category,
                                  title: titleController.text.trim(),
                                  assignedTo: assignedController.text.trim(),
                                  frequency: frequency,
                                  scheduledTime: scheduledTime,
                                  checklistLabels: labels,
                                );
                          }
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(t.save),
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
