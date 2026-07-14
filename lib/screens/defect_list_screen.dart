import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/defect.dart';
import '../models/vessel.dart';
import '../services/extraction_service.dart';
import '../services/report_service.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/attachment_picker.dart';

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
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: t.extractFromFile,
            onPressed: () => _extractFromFile(context, t),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: t.exportReport,
            onPressed: defects.isEmpty
                ? null
                : () => ReportService.exportDefectsReport(
                    vessel: vessel, defects: defects),
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
                        TextButton.icon(
                          onPressed: () {
                            data.deleteDefect(defect.id);
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

  void _showAddDefectSheet(
    BuildContext context,
    AppLocalizations t, {
    Map<String, dynamic>? prefill,
    List<Attachment> initialAttachments = const [],
  }) {
    final titleController = TextEditingController(text: _str(prefill, 'title'));
    final descController =
        TextEditingController(text: _str(prefill, 'description'));
    final officerController =
        TextEditingController(text: _str(prefill, 'assignedOfficer'));
    final sparePartsController =
        TextEditingController(text: _str(prefill, 'requiredSpareParts'));
    DefectPriority priority = _enumFrom(
        DefectPriority.values, _str(prefill, 'priority'), DefectPriority.low);
    DefectLocation location = _enumFrom(DefectLocation.values,
        _str(prefill, 'location'), DefectLocation.engineRoom);
    List<Attachment> files = [...initialAttachments];

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
                    Text(prefill != null ? t.reviewExtractedDefect : t.addDefect,
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
                          context.read<TankDataProvider>().addDefect(
                                vesselId: vessel.id,
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                location: location,
                                priority: priority,
                                assignedOfficer: officerController.text.trim(),
                                requiredSpareParts:
                                    sparePartsController.text.trim(),
                                attachments: files,
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

  static String _str(Map<String, dynamic>? m, String key) {
    final v = m?[key];
    return v == null ? '' : v.toString();
  }

  static T _enumFrom<T extends Enum>(List<T> values, String name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  /// AI-assisted entry: pick a file, upload it, ask the `extract` function to
  /// read it, then open the add sheet pre-filled with the result for review.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final picked = await pickAttachment();
    if (picked == null) return;
    if (!picked.isCloud) {
      messenger.showSnackBar(SnackBar(content: Text(t.extractionFailed)));
      return;
    }
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExtractingDialog(message: t.extractingFile),
    );

    try {
      final data = await ExtractionService.extract(
          storagePath: picked.storagePath!, kind: 'defect');
      navigator.pop(); // dismiss the loading dialog
      if (!context.mounted) return;
      _showAddDefectSheet(context, t,
          prefill: data, initialAttachments: [picked]);
    } on ExtractionException catch (e) {
      navigator.pop();
      final msg = e.code == 'not_configured'
          ? t.extractionNotConfigured
          : t.extractionFailed;
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

/// Small modal shown while the AI reads an uploaded file.
class _ExtractingDialog extends StatelessWidget {
  final String message;
  const _ExtractingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Expanded(child: Text(message)),
        ],
      ),
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
