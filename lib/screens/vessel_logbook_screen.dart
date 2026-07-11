import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/vessel.dart';
import '../state/tank_data_provider.dart';
import '../widgets/attachment_picker.dart';

class VesselLogbookScreen extends StatefulWidget {
  final Vessel vessel;
  const VesselLogbookScreen({super.key, required this.vessel});

  @override
  State<VesselLogbookScreen> createState() => _VesselLogbookScreenState();
}

class _VesselLogbookScreenState extends State<VesselLogbookScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    await context.read<TankDataProvider>().addNote(widget.vessel.id, text);
    if (!mounted) return;
    _noteController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final notes = data.notesFor(widget.vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text('${t.logbook} — ${widget.vessel.name}')),
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
                    child: Icon(Icons.send, size: 18),
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
                                  InkWell(
                                    onTap: () => context
                                        .read<TankDataProvider>()
                                        .deleteNote(note.id),
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
