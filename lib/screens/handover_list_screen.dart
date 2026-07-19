import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/defect.dart';
import '../models/handover_report.dart';
import '../models/vessel.dart';
import '../models/vessel_certificate.dart' show CertReminderStatus;
import '../services/report_service.dart';
import '../state/certification_provider.dart';
import '../state/handover_provider.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/export_feedback.dart';

/// Crew handover reports: the outgoing officer writes (or AI-drafts) a
/// structured report, issues it, and the incoming officer acknowledges it.
/// Acknowledged reports are locked as permanent handover history.
class HandoverListScreen extends StatelessWidget {
  final Vessel vessel;
  const HandoverListScreen({super.key, required this.vessel});

  String _statusLabel(AppLocalizations t, HandoverStatus s) {
    switch (s) {
      case HandoverStatus.draft:
        return t.handoverStatusDraft;
      case HandoverStatus.issued:
        return t.handoverStatusIssued;
      case HandoverStatus.acknowledged:
        return t.handoverStatusAcknowledged;
    }
  }

  Color _statusColor(HandoverStatus s) {
    switch (s) {
      case HandoverStatus.draft:
        return AppColors.statusPort;
      case HandoverStatus.issued:
        return AppColors.amber400;
      case HandoverStatus.acknowledged:
        return AppColors.statusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<HandoverProvider>();
    final reports = provider.forVessel(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.handover} — ${vessel.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: t.generateDraft,
            onPressed: () => _generateDraft(context, t),
          ),
          AiFillAction(onPressed: () => _extractFromFile(context, t)),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t.add,
            onPressed: () => _showEditSheet(context, t),
          ),
        ],
      ),
      body: reports.isEmpty
          ? Center(
              child: Text(t.noHandovers,
                  style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showDetailSheet(context, t, report.id),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${report.outgoingOfficer} → ${report.incomingOfficer}',
                              style: Theme.of(context).textTheme.titleMedium),
                          if (report.rank.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(report.rank,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Chip(
                                  label: _statusLabel(t, report.status),
                                  color: _statusColor(report.status)),
                              if (report.attachments.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.attach_file,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 2),
                                Text('${report.attachments.length}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                              const Spacer(),
                              Text(dateFmt.format(report.handoverDate),
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

  void _showDetailSheet(BuildContext context, AppLocalizations t, String id) {
    final provider = context.read<HandoverProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            // Re-read on every rebuild so status/attachment changes show
            // live. Copied to a `final` so closures below see it promoted.
            HandoverReport? current;
            for (final h in provider.forVessel(vessel.id)) {
              if (h.id == id) {
                current = h;
                break;
              }
            }
            if (current == null) return const SizedBox.shrink();
            final report = current;
            final locale = Localizations.localeOf(sheetContext).languageCode;
            final dateFmt = DateFormat.yMMMd(locale);
            final sections = <(String, String)>[
              (t.safetySectionLabel, report.safety),
              (t.machinerySectionLabel, report.machinery),
              (t.pendingDefectsLabel, report.pendingDefects),
              (t.bunkersTanksLabel, report.bunkersAndTanks),
              (t.certsExpiringLabel, report.certificatesExpiring),
              (t.remarksLabel, report.remarks),
            ];
            final locked = report.status == HandoverStatus.acknowledged;
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
                        '${report.outgoingOfficer} → ${report.incomingOfficer}',
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (report.rank.isNotEmpty)
                          Text('${t.rankLabel}: ${report.rank}',
                              style:
                                  Theme.of(sheetContext).textTheme.bodyMedium),
                        Text(
                            '${t.handoverDateLabel}: ${dateFmt.format(report.handoverDate)}',
                            style:
                                Theme.of(sheetContext).textTheme.bodyMedium),
                        if (report.acknowledgedBy.isNotEmpty)
                          Text(
                              '${t.acknowledgedByLabel}: ${report.acknowledgedBy}',
                              style:
                                  Theme.of(sheetContext).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final (label, body) in sections)
                      if (body.isNotEmpty) ...[
                        Text(label,
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleSmall),
                        const SizedBox(height: 2),
                        Text(body,
                            style:
                                Theme.of(sheetContext).textTheme.bodyMedium),
                        const SizedBox(height: 10),
                      ],
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: report.attachments,
                      onAdd: (file) {
                        provider.addAttachment(id, file);
                        setState(() {});
                      },
                      onRemove: (index) {
                        provider.removeAttachment(id, index);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (report.status == HandoverStatus.draft) ...[
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _showEditSheet(context, t, existing: report);
                            },
                            child: Text(t.editReport),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              provider.issue(report.id);
                              setState(() {});
                            },
                            child: Text(t.issueReport),
                          ),
                        ],
                        if (report.status == HandoverStatus.issued) ...[
                          OutlinedButton(
                            onPressed: () {
                              provider.acknowledge(report.id);
                              setState(() {});
                            },
                            child: Text(t.acknowledgeReport),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              provider.reopen(report.id);
                              setState(() {});
                            },
                            child: Text(t.reopen),
                          ),
                        ],
                        OutlinedButton.icon(
                          onPressed: () => exportPdfWithFeedback(
                              sheetContext,
                              t,
                              () => ReportService.exportHandoverReport(
                                  vessel: vessel, report: report)),
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 18),
                          label: Text(t.exportPdf),
                        ),
                        if (!locked)
                          TextButton.icon(
                            onPressed: () async {
                              final ok = await confirmDelete(sheetContext,
                                  itemName:
                                      '${report.outgoingOfficer} → ${report.incomingOfficer}');
                              if (ok) {
                                provider.delete(report.id);
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

  /// AI-assisted entry: the report extracted from an uploaded file is
  /// reviewed (and editable) in the normal sheet before it is saved.
  Future<void> _extractFromFile(
      BuildContext context, AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'handover');
    if (outcome == null || !context.mounted) return;
    await _showEditSheet(
      context,
      t,
      prefill: outcome.result.fields,
      initialAttachments: [outcome.file],
    );
  }

  /// Pre-fills a draft from the vessel's live data: open defects, current
  /// tank levels, and certificates near expiry. The officer reviews and
  /// completes the draft before anything is saved.
  Future<void> _generateDraft(BuildContext context, AppLocalizations t) async {
    final data = context.read<TankDataProvider>();
    final certs = context.read<CertificationProvider>();
    final dateFmt = DateFormat('yyyy-MM-dd');

    final openDefects = data
        .defectsFor(vessel.id)
        .where((d) => d.status != DefectStatus.closed)
        .map((d) => '- ${d.title} (${d.priority.name})')
        .join('\n');

    final tanks = vessel.tanks.map((tank) {
      final current = data.currentLevel(vessel.id, tank.id);
      final percent = (data.percentFor(vessel.id, tank) * 100).round();
      return '- ${tank.name}: ${current.toStringAsFixed(1)} / '
          '${tank.capacityM3.toStringAsFixed(1)} m³ ($percent%)';
    }).join('\n');

    final expiring = [
      ...certs
          .vesselCertsFor(vessel.id)
          .where((c) => c.reminderStatus != CertReminderStatus.green)
          .map((c) =>
              '- ${c.documentName}: ${dateFmt.format(c.expiryDate)}'),
      ...certs
          .crewCertsFor(vessel.id)
          .where((c) => c.reminderStatus != CertReminderStatus.green)
          .map((c) =>
              '- ${c.officerName} (${c.certType.name}): ${dateFmt.format(c.expiryDate)}'),
    ].join('\n');

    await _showEditSheet(context, t, prefill: {
      'pendingDefects': openDefects,
      'bunkersAndTanks': tanks,
      'certificatesExpiring': expiring,
    });
  }

  Future<void> _showEditSheet(
    BuildContext context,
    AppLocalizations t, {
    HandoverReport? existing,
    Map<String, dynamic>? prefill,
    List<Attachment> initialAttachments = const [],
  }) {
    final outgoingController = TextEditingController(
        text: existing?.outgoingOfficer ?? aiStr(prefill, 'outgoingOfficer'));
    final incomingController = TextEditingController(
        text: existing?.incomingOfficer ?? aiStr(prefill, 'incomingOfficer'));
    final rankController =
        TextEditingController(text: existing?.rank ?? aiStr(prefill, 'rank'));
    final safetyController = TextEditingController(
        text: existing?.safety ?? aiStr(prefill, 'safety'));
    final machineryController = TextEditingController(
        text: existing?.machinery ?? aiStr(prefill, 'machinery'));
    final defectsController = TextEditingController(
        text: existing?.pendingDefects ?? aiStr(prefill, 'pendingDefects'));
    final bunkersController = TextEditingController(
        text: existing?.bunkersAndTanks ?? aiStr(prefill, 'bunkersAndTanks'));
    final certsController = TextEditingController(
        text: existing?.certificatesExpiring ??
            aiStr(prefill, 'certificatesExpiring'));
    final remarksController = TextEditingController(
        text: existing?.remarks ?? aiStr(prefill, 'remarks'));
    DateTime handoverDate = existing?.handoverDate ??
        aiDateIn(prefill, 'handoverDate', DateTime(2000),
            DateTime.now().add(const Duration(days: 365))) ??
        DateTime.now();
    List<Attachment> newFiles = [...initialAttachments];

    Widget field(TextEditingController controller, String label,
            {int lines = 1}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextField(
            controller: controller,
            minLines: lines,
            maxLines: lines == 1 ? 1 : lines + 2,
            decoration: InputDecoration(labelText: label),
          ),
        );

    return showModalBottomSheet(
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
                    Text(existing == null ? t.addHandover : t.editReport,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    field(outgoingController, t.outgoingOfficerLabel),
                    field(incomingController, t.incomingOfficerLabel),
                    field(rankController, t.rankLabel),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: handoverDate,
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => handoverDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: t.handoverDateLabel),
                        child: Text(dateFmt.format(handoverDate)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    field(safetyController, t.safetySectionLabel, lines: 2),
                    field(machineryController, t.machinerySectionLabel,
                        lines: 2),
                    field(defectsController, t.pendingDefectsLabel, lines: 3),
                    field(bunkersController, t.bunkersTanksLabel, lines: 3),
                    field(certsController, t.certsExpiringLabel, lines: 3),
                    field(remarksController, t.remarksLabel, lines: 2),
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
                          if (outgoingController.text.trim().isEmpty &&
                              incomingController.text.trim().isEmpty) {
                            return;
                          }
                          final provider = context.read<HandoverProvider>();
                          if (existing == null) {
                            provider.add(
                              vesselId: vessel.id,
                              outgoingOfficer: outgoingController.text.trim(),
                              incomingOfficer: incomingController.text.trim(),
                              rank: rankController.text.trim(),
                              handoverDate: handoverDate,
                              safety: safetyController.text.trim(),
                              machinery: machineryController.text.trim(),
                              pendingDefects: defectsController.text.trim(),
                              bunkersAndTanks: bunkersController.text.trim(),
                              certificatesExpiring:
                                  certsController.text.trim(),
                              remarks: remarksController.text.trim(),
                              attachments: newFiles,
                            );
                          } else {
                            provider.update(existing.copyWith(
                              outgoingOfficer: outgoingController.text.trim(),
                              incomingOfficer: incomingController.text.trim(),
                              rank: rankController.text.trim(),
                              handoverDate: handoverDate,
                              safety: safetyController.text.trim(),
                              machinery: machineryController.text.trim(),
                              pendingDefects: defectsController.text.trim(),
                              bunkersAndTanks: bunkersController.text.trim(),
                              certificatesExpiring:
                                  certsController.text.trim(),
                              remarks: remarksController.text.trim(),
                              attachments: [
                                ...existing.attachments,
                                ...newFiles
                              ],
                            ));
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
