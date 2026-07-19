import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/port_requirement.dart';
import '../models/vessel.dart';
import '../state/port_requirement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/confirm_delete.dart';

String requirementCategoryLabel(AppLocalizations t, RequirementCategory c) {
  switch (c) {
    case RequirementCategory.documents:
      return t.reqCatDocuments;
    case RequirementCategory.customs:
      return t.reqCatCustoms;
    case RequirementCategory.health:
      return t.reqCatHealth;
    case RequirementCategory.security:
      return t.reqCatSecurity;
    case RequirementCategory.provisions:
      return t.reqCatProvisions;
    case RequirementCategory.other:
      return t.reqCatOther;
  }
}

IconData requirementCategoryIcon(RequirementCategory c) {
  switch (c) {
    case RequirementCategory.documents:
      return Icons.description_outlined;
    case RequirementCategory.customs:
      return Icons.gavel_outlined;
    case RequirementCategory.health:
      return Icons.health_and_safety_outlined;
    case RequirementCategory.security:
      return Icons.security_outlined;
    case RequirementCategory.provisions:
      return Icons.inventory_2_outlined;
    case RequirementCategory.other:
      return Icons.folder_outlined;
  }
}

class PortRequirementsScreen extends StatelessWidget {
  final Vessel vessel;
  const PortRequirementsScreen({super.key, required this.vessel});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<PortRequirementProvider>();
    final items = provider.forVessel(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.portRequirementsTitle} — ${vessel.name}'),
        actions: [
          AiFillAction(onPressed: () => _extractFromFile(context, t)),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t.addRequirement,
            onPressed: () => _showAddSheet(context, t),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(t.noRequirements,
                  style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = items[index];
                final ready = r.status == RequirementStatus.ready;
                final statusColor =
                    ready ? AppColors.statusActive : AppColors.amber600;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showDetailSheet(context, t, r),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(requirementCategoryIcon(r.category),
                              color: AppColors.navy500),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(r.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        ready
                                            ? t.reqStatusReady
                                            : t.reqStatusPendingLabel,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${requirementCategoryLabel(t, r.category)}'
                                  '${r.portName.isNotEmpty ? ' · ${r.portName}' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.attach_file,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5)),
                                    const SizedBox(width: 2),
                                    Text('${r.attachments.length}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    const Spacer(),
                                    Text(dateFmt.format(r.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
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
      BuildContext context, AppLocalizations t, PortRequirement req) {
    final provider = context.read<PortRequirementProvider>();
    var files = req.attachments;
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
                    Text(req.title,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${requirementCategoryLabel(t, req.category)}'
                      '${req.portName.isNotEmpty ? ' · ${req.portName}' : ''}',
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                    if (req.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(req.notes,
                          style: Theme.of(sheetContext).textTheme.bodyLarge),
                    ],
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: files,
                      onAdd: (file) {
                        provider.addAttachment(req.id, file);
                        setState(() => files = [...files, file]);
                      },
                      onRemove: (index) {
                        provider.removeAttachment(req.id, index);
                        setState(() => files = [...files]..removeAt(index));
                      },
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (req.status == RequirementStatus.pending)
                          FilledButton.icon(
                            onPressed: () {
                              provider.updateStatus(
                                  req.id, RequirementStatus.ready);
                              Navigator.of(sheetContext).pop();
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(t.markReady),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              provider.updateStatus(
                                  req.id, RequirementStatus.pending);
                              Navigator.of(sheetContext).pop();
                            },
                            icon: const Icon(Icons.undo, size: 18),
                            label: Text(t.markPending),
                          ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _showAddSheet(context, t, existing: req);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(t.edit),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await confirmDelete(sheetContext,
                                itemName: req.title);
                            if (ok) {
                              provider.delete(req.id);
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

  /// AI-assisted entry: each requirement found in the file is reviewed (and
  /// editable) in the normal add sheet before it is saved.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'port_requirement');
    if (outcome == null) return;
    final items = outcome.result.items ?? [];
    for (var i = 0; i < items.length; i++) {
      if (!context.mounted) return;
      await _showAddSheet(
        context,
        t,
        prefill: items[i],
        initialAttachments: [outcome.file],
        progressLabel: items.length > 1 ? '(${i + 1}/${items.length})' : null,
      );
    }
  }

  Future<void> _showAddSheet(
    BuildContext context,
    AppLocalizations t, {
    Map<String, dynamic>? prefill,
    List<Attachment> initialAttachments = const [],
    String? progressLabel,
    PortRequirement? existing,
  }) {
    final titleController = TextEditingController(
        text: existing?.title ?? aiStr(prefill, 'title'));
    final portController = TextEditingController(
        text: existing?.portName ?? aiStr(prefill, 'portName'));
    final notesController = TextEditingController(
        text: existing?.notes ?? aiStr(prefill, 'notes'));
    RequirementCategory category = existing?.category ??
        aiEnum(prefill, 'category', RequirementCategory.values,
            RequirementCategory.documents);
    List<Attachment> newFiles = [...(existing?.attachments ?? initialAttachments)];

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
                          existing != null ? t.edit : t.addRequirement,
                          if (progressLabel != null) progressLabel,
                        ].join(' '),
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration:
                          InputDecoration(labelText: t.requirementTitleLabel),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<RequirementCategory>(
                      initialValue: category,
                      decoration:
                          InputDecoration(labelText: t.reqCategoryLabel),
                      items: RequirementCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(requirementCategoryLabel(t, c))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => category = v ?? category),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: portController,
                      decoration: InputDecoration(labelText: t.portNameLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: t.notesLabel),
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
                          if (existing != null) {
                            context.read<PortRequirementProvider>().update(
                                  id: existing.id,
                                  title: titleController.text.trim(),
                                  portName: portController.text.trim(),
                                  category: category,
                                  notes: notesController.text.trim(),
                                );
                          } else {
                            context.read<PortRequirementProvider>().add(
                                  vesselId: vessel.id,
                                  title: titleController.text.trim(),
                                  portName: portController.text.trim(),
                                  category: category,
                                  notes: notesController.text.trim(),
                                  attachments: newFiles,
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
}
