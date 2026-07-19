import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/defect.dart';
import '../models/vessel.dart';
import '../services/report_service.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/export_feedback.dart';

class DefectListScreen extends StatelessWidget {
  final Vessel vessel;
  const DefectListScreen({super.key, required this.vessel});

  Color _priorityColor(DefectPriority p) {
    switch (p) {
      case DefectPriority.low:
        return AppColors.statusPort;
      case DefectPriority.medium:
        return AppColors.teal500;
      case DefectPriority.high:
        return AppColors.amber400;
      case DefectPriority.critical:
        return AppColors.statusMaintenance;
    }
  }

  String _priorityLabel(AppLocalizations t, DefectPriority p) {
    switch (p) {
      case DefectPriority.low:
        return t.priorityLow;
      case DefectPriority.medium:
        return t.priorityMedium;
      case DefectPriority.high:
        return t.priorityHigh;
      case DefectPriority.critical:
        return t.severityCritical;
    }
  }

  String _locationLabel(AppLocalizations t, DefectLocation l) {
    switch (l) {
      case DefectLocation.engineRoom:
        return t.locationEngineRoom;
      case DefectLocation.deck:
        return t.locationDeck;
      case DefectLocation.bridge:
        return t.locationBridge;
      case DefectLocation.accommodation:
        return t.locationAccommodation;
      case DefectLocation.galley:
        return t.locationGalley;
      case DefectLocation.other:
        return t.locationOther;
    }
  }

  String _statusLabel(AppLocalizations t, DefectStatus s) {
    switch (s) {
      case DefectStatus.open:
        return t.statusOpenDefect;
      case DefectStatus.inProgress:
        return t.statusInProgress;
      case DefectStatus.closed:
        return t.statusClosedDefect;
    }
  }

  Color _statusColor(DefectStatus s) {
    switch (s) {
      case DefectStatus.open:
        return AppColors.statusMaintenance;
      case DefectStatus.inProgress:
        return AppColors.amber400;
      case DefectStatus.closed:
        return AppColors.statusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final defects = data.defectsFor(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.defects} — ${vessel.name}'),
        actions: [
          AiFillAction(onPressed: () => _extractFromFile(context, t)),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: t.exportReport,
            onPressed: defects.isEmpty
                ? null
                : () => exportPdfWithFeedback(context, t,
                    () => ReportService.exportDefectsReport(
                        vessel: vessel, defects: defects)),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t.addDefect,
            onPressed: () => _showAddDefectSheet(context, t),
          ),
        ],
      ),
      body: defects.isEmpty
          ? Center(
              child: Text(t.noDefects,
                  style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: defects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final defect = defects[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showDefectDetailSheet(context, t, defect),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(defect.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              _Chip(
                                  label: _priorityLabel(t, defect.priority),
                                  color: _priorityColor(defect.priority)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _locationLabel(t, defect.location),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Chip(
                                  label: _statusLabel(t, defect.status),
                                  color: _statusColor(defect.status)),
                              if (defect.attachments.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.attach_file,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 2),
                                Text('${defect.attachments.length}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                              const Spacer(),
                              Text(
                                '${t.reportedOn}: ${dateFmt.format(defect.reportedAt)}',
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

  void _showDefectDetailSheet(
      BuildContext context, AppLocalizations t, Defect defect) {
    final data = context.read<TankDataProvider>();
    final actionController = TextEditingController(text: defect.actionTaken);
    var files = defect.attachments;
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
                    Text(defect.title,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(_locationLabel(t, defect.location),
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Text(defect.description,
                        style: Theme.of(sheetContext).textTheme.bodyLarge),
                    if (defect.assignedOfficer.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                          '${t.assignedOfficerLabel}: ${defect.assignedOfficer}',
                          style: Theme.of(sheetContext).textTheme.bodyMedium),
                    ],
                    if (defect.requiredSpareParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                          '${t.requiredSparePartsLabel}: ${defect.requiredSpareParts}',
                          style: Theme.of(sheetContext).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: actionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          InputDecoration(labelText: t.actionTakenLabel),
                      onSubmitted: (v) =>
                          data.updateDefectActionTaken(defect.id, v),
                    ),
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: files,
                      onAdd: (file) {
                        data.addDefectAttachment(defect.id, file);
                        setState(() => files = [...files, file]);
                      },
                      onRemove: (index) {
                        data.removeDefectAttachment(defect.id, index);
                        setState(() => files = [...files]..removeAt(index));
                      },
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (defect.status != DefectStatus.inProgress)
                          OutlinedButton(
                            onPressed: () {
                              data.updateDefectActionTaken(
                                  defect.id, actionController.text);
                              data.updateDefectStatus(
                                  defect.id, DefectStatus.inProgress);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markInProgress),
                          ),
                        if (defect.status != DefectStatus.closed)
                          OutlinedButton(
                            onPressed: () {
                              data.updateDefectActionTaken(
                                  defect.id, actionController.text);
                              data.updateDefectStatus(
                                  defect.id, DefectStatus.closed);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markClosed),
                          ),
                        if (defect.status == DefectStatus.closed)
                          OutlinedButton(
                            onPressed: () {
                              data.updateDefectStatus(
                                  defect.id, DefectStatus.open);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.reopen),
                          ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _showAddDefectSheet(context, t, existing: defect);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(t.edit),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await confirmDelete(sheetContext,
                                itemName: defect.title);
                            if (ok) {
                              data.deleteDefect(defect.id);
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
      },
    );
  }

  Future<void> _showAddDefectSheet(
    BuildContext context,
    AppLocalizations t, {
    Map<String, dynamic>? prefill,
    List<Attachment> initialAttachments = const [],
    String? progressLabel,
    Defect? existing,
  }) {
    final titleController = TextEditingController(
        text: existing?.title ?? aiStr(prefill, 'title'));
    final descController = TextEditingController(
        text: existing?.description ?? aiStr(prefill, 'description'));
    final officerController = TextEditingController(
        text: existing?.assignedOfficer ?? aiStr(prefill, 'assignedOfficer'));
    final sparePartsController = TextEditingController(
        text: existing?.requiredSpareParts ??
            aiStr(prefill, 'requiredSpareParts'));
    DefectPriority priority = existing?.priority ??
        aiEnum(prefill, 'priority', DefectPriority.values, DefectPriority.low);
    DefectLocation location = existing?.location ??
        aiEnum(prefill, 'location', DefectLocation.values,
            DefectLocation.engineRoom);
    List<Attachment> files = [...(existing?.attachments ?? initialAttachments)];

    return showModalBottomSheet(
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
                    Text(
                        [
                          existing != null
                              ? t.editDefect
                              : prefill != null
                                  ? t.reviewExtractedDefect
                                  : t.addDefect,
                          if (progressLabel != null) progressLabel,
                        ].join(' '),
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration:
                          InputDecoration(labelText: t.defectTitleLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          InputDecoration(labelText: t.defectDescriptionLabel),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<DefectLocation>(
                      initialValue: location,
                      decoration: InputDecoration(labelText: t.locationLabel),
                      items: DefectLocation.values
                          .map((l) => DropdownMenuItem(
                              value: l, child: Text(_locationLabel(t, l))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => location = v ?? location),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: officerController,
                      decoration:
                          InputDecoration(labelText: t.assignedOfficerLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: sparePartsController,
                      decoration:
                          InputDecoration(labelText: t.requiredSparePartsLabel),
                    ),
                    const SizedBox(height: 14),
                    Text(t.priorityLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<DefectPriority>(
                      segments: [
                        ButtonSegment(
                            value: DefectPriority.low,
                            label: Text(t.priorityLow)),
                        ButtonSegment(
                            value: DefectPriority.medium,
                            label: Text(t.priorityMedium)),
                        ButtonSegment(
                            value: DefectPriority.high,
                            label: Text(t.priorityHigh)),
                        ButtonSegment(
                            value: DefectPriority.critical,
                            label: Text(t.severityCritical)),
                      ],
                      selected: {priority},
                      onSelectionChanged: (s) =>
                          setState(() => priority = s.first),
                    ),
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: files,
                      onAdd: (file) =>
                          setState(() => files = [...files, file]),
                      onRemove: (index) => setState(
                          () => files = [...files]..removeAt(index)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          if (existing != null) {
                            context.read<TankDataProvider>().updateDefect(
                                  id: existing.id,
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  location: location,
                                  priority: priority,
                                  assignedOfficer:
                                      officerController.text.trim(),
                                  requiredSpareParts:
                                      sparePartsController.text.trim(),
                                );
                          } else {
                            context.read<TankDataProvider>().addDefect(
                                  vesselId: vessel.id,
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  location: location,
                                  priority: priority,
                                  assignedOfficer:
                                      officerController.text.trim(),
                                  requiredSpareParts:
                                      sparePartsController.text.trim(),
                                  attachments: files,
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

  /// AI-assisted entry: each defect row the AI finds in the file (a single
  /// report, or a defect register/log listing many) is reviewed (and
  /// editable) in the normal add sheet before it is saved.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'defect');
    if (outcome == null) return;
    final items = outcome.result.items ?? [];
    for (var i = 0; i < items.length; i++) {
      if (!context.mounted) return;
      await _showAddDefectSheet(
        context,
        t,
        prefill: items[i],
        initialAttachments: [outcome.file],
        progressLabel: items.length > 1 ? '(${i + 1}/${items.length})' : null,
      );
    }
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
