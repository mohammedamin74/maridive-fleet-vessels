import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/maintenance_record.dart';
import '../models/vessel.dart';
import '../state/maintenance_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/attachment_picker.dart';

class MaintenanceListScreen extends StatelessWidget {
  final Vessel vessel;
  const MaintenanceListScreen({super.key, required this.vessel});

  String _statusLabel(AppLocalizations t, MaintenanceStatus s) {
    switch (s) {
      case MaintenanceStatus.planned:
        return t.maintStatusPlanned;
      case MaintenanceStatus.inProgress:
        return t.maintStatusInProgress;
      case MaintenanceStatus.completed:
        return t.maintStatusCompleted;
    }
  }

  Color _statusColor(MaintenanceStatus s) {
    switch (s) {
      case MaintenanceStatus.planned:
        return AppColors.statusPort;
      case MaintenanceStatus.inProgress:
        return AppColors.amber400;
      case MaintenanceStatus.completed:
        return AppColors.statusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<MaintenanceProvider>();
    final records = provider.forVessel(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.maintenance} — ${vessel.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSheet(context, t),
          ),
        ],
      ),
      body: records.isEmpty
          ? Center(
              child: Text(t.noMaintenance,
                  style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rec = records[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showDetailSheet(context, t, rec),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rec.title,
                              style: Theme.of(context).textTheme.titleMedium),
                          if (rec.performedBy.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(rec.performedBy,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Chip(
                                  label: _statusLabel(t, rec.status),
                                  color: _statusColor(rec.status)),
                              if (rec.attachments.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.attach_file,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 2),
                                Text('${rec.attachments.length}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                              const Spacer(),
                              Text(
                                '${t.maintenanceDueLabel}: ${dateFmt.format(rec.dueDate)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
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

  void _showDetailSheet(
      BuildContext context, AppLocalizations t, MaintenanceRecord rec) {
    final provider = context.read<MaintenanceProvider>();
    var files = rec.attachments;
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
                    Text(rec.title,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    if (rec.performedBy.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('${t.performedByLabel}: ${rec.performedBy}',
                          style: Theme.of(sheetContext).textTheme.bodyMedium),
                    ],
                    if (rec.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(rec.description,
                          style: Theme.of(sheetContext).textTheme.bodyLarge),
                    ],
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: files,
                      onAdd: (file) {
                        provider.addAttachment(rec.id, file);
                        setState(() => files = [...files, file]);
                      },
                      onRemove: (index) {
                        provider.removeAttachment(rec.id, index);
                        setState(() => files = [...files]..removeAt(index));
                      },
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (rec.status != MaintenanceStatus.inProgress)
                          OutlinedButton(
                            onPressed: () {
                              provider.updateStatus(
                                  rec.id, MaintenanceStatus.inProgress);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markInProgress),
                          ),
                        if (rec.status != MaintenanceStatus.completed)
                          OutlinedButton(
                            onPressed: () {
                              provider.updateStatus(
                                  rec.id, MaintenanceStatus.completed);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markCompleted),
                          ),
                        if (rec.status == MaintenanceStatus.completed)
                          OutlinedButton(
                            onPressed: () {
                              provider.updateStatus(
                                  rec.id, MaintenanceStatus.planned);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.reopen),
                          ),
                        TextButton.icon(
                          onPressed: () {
                            provider.delete(rec.id);
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
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSheet(BuildContext context, AppLocalizations t) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final performedByController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    List<Attachment> newFiles = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final locale = Localizations.localeOf(sheetContext).languageCode;
            final dateFmt = DateFormat.yMMMd(locale);
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
                    Text(t.addMaintenance,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration:
                          InputDecoration(labelText: t.maintenanceTitleLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          InputDecoration(labelText: t.maintenanceDescLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: performedByController,
                      decoration:
                          InputDecoration(labelText: t.performedByLabel),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: dueDate,
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() => dueDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                            labelText: t.maintenanceDueLabel),
                        child: Text(dateFmt.format(dueDate)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: newFiles,
                      onAdd: (file) =>
                          setState(() => newFiles = [...newFiles, file]),
                      onRemove: (index) => setState(
                          () => newFiles = [...newFiles]..removeAt(index)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          context.read<MaintenanceProvider>().add(
                                vesselId: vessel.id,
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                performedBy: performedByController.text.trim(),
                                dueDate: dueDate,
                                attachments: newFiles,
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
