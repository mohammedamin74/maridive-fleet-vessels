import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/vessel.dart';
import '../models/vessel_note.dart';
import '../state/tank_data_provider.dart';
import '../widgets/ai_fill.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/confirm_delete.dart';

class VesselLogbookScreen extends StatefulWidget {
  final Vessel vessel;
  const VesselLogbookScreen({super.key, required this.vessel});

  @override
  State<VesselLogbookScreen> createState() => _VesselLogbookScreenState();
}

class _VesselLogbookScreenState extends State<VesselLogbookScreen> {
  final _noteController = TextEditingController();

  /// The uploaded source file of an AI-extracted note, attached as evidence
  /// when the user approves the text by sending it.
  Attachment? _pendingAiFile;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    final file = _pendingAiFile;
    await context.read<TankDataProvider>().addNote(widget.vessel.id, text,
        attachments: file == null ? const [] : [file]);
    if (!mounted) return;
    _noteController.clear();
    _pendingAiFile = null;
    FocusScope.of(context).unfocus();
  }

  /// AI-assisted entry: the extracted text lands in the note field for the
  /// user to review and edit — nothing is saved until they tap send.
  Future<void> _extractFromFile(AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'logbook');
    if (outcome == null || !mounted) return;
    setState(() {
      _noteController.text = aiStr(outcome.result.fields, 'text');
      _pendingAiFile = outcome.file;
    });
  }

  Future<void> _editNote(
      BuildContext context, AppLocalizations t, VesselNote note) async {
    final controller = TextEditingController(text: note.text);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.edit),
        content: TextField(
          controller: controller,
          minLines: 1,
          maxLines: 6,
          autofocus: true,
          decoration: InputDecoration(hintText: t.addNoteHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(t.save),
          ),
        ],
      ),
    );
    final text = result?.trim();
    if (text == null || text.isEmpty || !context.mounted) return;
    context.read<TankDataProvider>().updateNote(note.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final notes = data.notesFor(widget.vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.logbook} — ${widget.vessel.name}'),
        actions: [AiFillAction(onPressed: () => _extractFromFile(t))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(hintText: t.addNoteHint),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _addNote,
                    child: const Icon(Icons.send, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Text(t.noNotes,
                        style: Theme.of(context).textTheme.bodyMedium),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFmt.format(note.timestamp),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () =>
                                            _editNote(context, t, note),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      InkWell(
                                        onTap: () async {
                                          final preview = note.text.length > 60
                                              ? '${note.text.substring(0, 60)}…'
                                              : note.text;
                                          final ok = await confirmDelete(
                                              context,
                                              itemName: preview);
                                          if (ok && context.mounted) {
                                            context
                                                .read<TankDataProvider>()
                                                .deleteNote(note.id);
                                          }
                                        },
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(note.text,
                                  style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 10),
                              AttachmentPickerStrip(
                                attachments: note.attachments,
                                onAdd: (file) => context
                                    .read<TankDataProvider>()
                                    .addNoteAttachment(note.id, file),
                                onRemove: (i) => context
                                    .read<TankDataProvider>()
                                    .removeNoteAttachment(note.id, i),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
