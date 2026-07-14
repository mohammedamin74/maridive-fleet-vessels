import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/vessel.dart';
import '../models/vessel_spec.dart';
import '../state/vessel_spec_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/attachment_picker.dart';

class VesselSpecsScreen extends StatelessWidget {
  final Vessel vessel;
  const VesselSpecsScreen({super.key, required this.vessel});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<VesselSpecProvider>();
    final specs = provider.forVessel(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.specifications} — ${vessel.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t.add,
            onPressed: () => _showAddSheet(context, t),
          ),
        ],
      ),
      body: specs.isEmpty
          ? Center(
              child: Text(t.noSpecs,
                  style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: specs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final spec = specs[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showDetailSheet(context, t, spec),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(spec.title,
                              style: Theme.of(context).textTheme.titleMedium),
                          if (spec.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(spec.notes,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.attach_file,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5)),
                              const SizedBox(width: 2),
                              Text('${spec.attachments.length}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const Spacer(),
                              Text(
                                dateFmt.format(spec.createdAt),
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
      BuildContext context, AppLocalizations t, VesselSpec spec) {
    final provider = context.read<VesselSpecProvider>();
    var files = spec.attachments;
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
                    Text(spec.title,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    if (spec.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(spec.notes,
                          style: Theme.of(sheetContext).textTheme.bodyLarge),
                    ],
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: files,
                      onAdd: (file) {
                        provider.addAttachment(spec.id, file);
                        setState(() => files = [...files, file]);
                      },
                      onRemove: (index) {
                        provider.removeAttachment(spec.id, index);
                        setState(() => files = [...files]..removeAt(index));
                      },
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () {
                        provider.delete(spec.id);
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
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSheet(BuildContext context, AppLocalizations t) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    List<Attachment> newFiles = [];

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
                    Text(t.addSpec,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration:
                          InputDecoration(labelText: t.specTitleLabel),
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
                          context.read<VesselSpecProvider>().add(
                                vesselId: vessel.id,
                                title: titleController.text.trim(),
                                notes: notesController.text.trim(),
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
