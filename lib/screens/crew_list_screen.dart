import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/crew_member.dart';
import '../models/vessel.dart';
import '../state/crew_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import '../widgets/confirm_delete.dart';

class CrewListScreen extends StatelessWidget {
  final Vessel vessel;
  const CrewListScreen({super.key, required this.vessel});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<CrewProvider>();
    final current = provider.current(vessel.id);
    final previous = provider.previous(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${t.crewListTitle} — ${vessel.name}'),
          actions: [
            AiFillAction(onPressed: () => _extractFromFile(context, t)),
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: t.addCrew,
              onPressed: () => _showAddSheet(context, t),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: '${t.currentCrew} (${current.length})'),
              Tab(text: '${t.previousCrew} (${previous.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CrewList(
              members: current,
              emptyText: t.noCurrentCrew,
              t: t,
              dateFmt: dateFmt,
              onTap: (m) => _showDetailSheet(context, t, m, dateFmt),
            ),
            _CrewList(
              members: previous,
              emptyText: t.noPreviousCrew,
              t: t,
              dateFmt: dateFmt,
              onTap: (m) => _showDetailSheet(context, t, m, dateFmt),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, AppLocalizations t, CrewMember m,
      DateFormat dateFmt) {
    final provider = context.read<CrewProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                [m.rank, m.nationality].where((s) => s.isNotEmpty).join(' · '),
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _kv(sheetContext, t.signOnDateLabel, dateFmt.format(m.signOnDate)),
              if (m.signOffDate != null)
                _kv(sheetContext, t.signOffDateLabel,
                    dateFmt.format(m.signOffDate!)),
              if (m.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(m.notes,
                    style: Theme.of(sheetContext).textTheme.bodyLarge),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (m.status == CrewStatus.current)
                    OutlinedButton.icon(
                      onPressed: () {
                        provider.signOff(m.id);
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(t.signOffCrew),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () {
                        provider.reactivate(m.id);
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(Icons.login, size: 18),
                      label: Text(t.reactivateCrew),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _showAddSheet(context, t, existing: m);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(t.edit),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final ok =
                          await confirmDelete(sheetContext, itemName: m.name);
                      if (ok) {
                        provider.delete(m.id);
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
        );
      },
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(k,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.slate600)),
            ),
            Expanded(
              child: Text(v,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  /// AI-assisted entry: reads a crew list / sign-on document; each crew
  /// member found is reviewed in the normal add sheet before saving. The
  /// extraction prompt forbids passport/ID numbers, and everything is
  /// editable here before it persists.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'crew');
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
    CrewMember? existing,
  }) {
    final nameController = TextEditingController(
        text: existing?.name ?? aiStr(prefill, 'name'));
    final rankController = TextEditingController(
        text: existing?.rank ?? aiStr(prefill, 'rank'));
    final nationalityController = TextEditingController(
        text: existing?.nationality ?? aiStr(prefill, 'nationality'));
    final notesController = TextEditingController(
        text: existing?.notes ?? aiStr(prefill, 'notes'));
    // Clamped to the sheet's date-picker bounds (now.year-5 .. now.year+1).
    DateTime signOnDate = existing?.signOnDate ??
        aiDateIn(prefill, 'signOnDate', DateTime(DateTime.now().year - 5),
            DateTime(DateTime.now().year + 1)) ??
        DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

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
                          existing != null ? t.edit : t.addCrew,
                          if (progressLabel != null) progressLabel,
                        ].join(' '),
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: t.crewNameLabel),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rankController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(labelText: t.rankLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: nationalityController,
                            textCapitalization: TextCapitalization.words,
                            decoration:
                                InputDecoration(labelText: t.nationalityLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: signOnDate,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 1),
                        );
                        if (picked != null) {
                          setState(() => signOnDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: t.signOnDateLabel),
                        child: Text(dateFmt.format(signOnDate)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: t.notesLabel),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          if (existing != null) {
                            context.read<CrewProvider>().update(
                                  id: existing.id,
                                  name: nameController.text.trim(),
                                  rank: rankController.text.trim(),
                                  nationality:
                                      nationalityController.text.trim(),
                                  signOnDate: signOnDate,
                                  notes: notesController.text.trim(),
                                );
                          } else {
                            context.read<CrewProvider>().add(
                                  vesselId: vessel.id,
                                  name: nameController.text.trim(),
                                  rank: rankController.text.trim(),
                                  nationality:
                                      nationalityController.text.trim(),
                                  signOnDate: signOnDate,
                                  notes: notesController.text.trim(),
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

class _CrewList extends StatelessWidget {
  final List<CrewMember> members;
  final String emptyText;
  final AppLocalizations t;
  final DateFormat dateFmt;
  final ValueChanged<CrewMember> onTap;

  const _CrewList({
    required this.members,
    required this.emptyText,
    required this.t,
    required this.dateFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
          child: Text(emptyText,
              style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final m = members[index];
        final subtitle =
            [m.rank, m.nationality].where((s) => s.isNotEmpty).join(' · ');
        final isPrevious = m.status == CrewStatus.previous;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(m),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.navy100,
                    child: Text(
                      _initials(m.name),
                      style: const TextStyle(
                          color: AppColors.navy700,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          isPrevious && m.signOffDate != null
                              ? '${t.signOffDateLabel}: ${dateFmt.format(m.signOffDate!)}'
                              : '${t.signOnDateLabel}: ${dateFmt.format(m.signOnDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
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
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
