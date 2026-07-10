import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/daily_task.dart';
import '../models/vessel.dart';
import '../services/report_service.dart';
import '../state/daily_tasks_provider.dart';
import '../theme/app_colors.dart';
import 'daily_task_detail_screen.dart';

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

const Map<TaskCategory, List<String>> defaultChecklistsByCategory = {
  TaskCategory.engineRoomRounds: [
    'Check Main Engine Oil Pressure',
    'Check Main Engine Cooling Water Temperature',
    'Inspect Bilges for Leaks',
    'Check Generator Running Parameters',
  ],
  TaskCategory.deckRounds: [
    'Inspect Mooring Lines & Fittings',
    'Check Deck Lighting',
    'Inspect Cargo/Deck Equipment for Damage',
  ],
  TaskCategory.safetyEquipmentChecks: [
    'Inspect Lifeboat Release Mechanism',
    'Check Fire Extinguisher Pressure Gauges',
    'Test Emergency Alarm System',
    'Check Life Jacket Stock & Condition',
  ],
  TaskCategory.navigationEquipmentTests: [
    'Test Radar & ARPA',
    'Check GPS/GNSS Position Accuracy',
    'Test Steering Gear (Manual/Auto)',
  ],
  TaskCategory.galleyHygieneInspections: [
    'Check Galley Cleanliness',
    'Check Food Storage Temperatures',
    'Inspect Pest Control Measures',
  ],
};

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
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: tasks.isEmpty
                ? null
                : () => ReportService.exportDailyTasksReport(
                    vessel: vessel, tasks: tasks),
          ),
          IconButton(
              icon: const Icon(Icons.add),
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
                              if (task.photosBase64.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.photo_camera,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 2),
                                Text('${task.photosBase64.length}',
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

  void _showAddSheet(BuildContext context, AppLocalizations t) {
    final titleController = TextEditingController();
    final assignedController = TextEditingController();
    final checklistController = TextEditingController(
      text: defaultChecklistsByCategory[TaskCategory.engineRoomRounds]!
          .join('\n'),
    );
    TaskCategory category = TaskCategory.engineRoomRounds;
    TaskFrequency frequency = TaskFrequency.daily;
    DateTime scheduledTime = DateTime.now();

    showModalBottomSheet(
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
                    Text(t.addDailyTask,
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
                              defaultChecklistsByCategory[v]!.join('\n');
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
                        if (date == null) return;
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
}
