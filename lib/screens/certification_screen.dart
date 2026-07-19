import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/crew_certificate.dart';
import '../models/vessel.dart';
import '../models/vessel_certificate.dart';
import '../state/certification_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/photo_picker.dart';

Color reminderColor(CertReminderStatus s) {
  switch (s) {
    case CertReminderStatus.green:
      return AppColors.statusActive;
    case CertReminderStatus.amber:
      return AppColors.amber400;
    case CertReminderStatus.red:
      return AppColors.statusMaintenance;
    case CertReminderStatus.expired:
      return AppColors.statusExpired;
  }
}

/// Persistent red strip shown while any of this vessel's certificates is
/// expired or inside the 30-day alarm window. Expired and expiring-soon
/// counts are surfaced separately so an already-expired certificate isn't
/// misreported as "expires within 30 days".
class _ExpiryAlarmBanner extends StatelessWidget {
  final int expiredCount;
  final int expiringCount;
  const _ExpiryAlarmBanner(
      {required this.expiredCount, required this.expiringCount});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    const alarm = AppColors.statusMaintenance;
    final title = expiredCount == 0
        ? t.certAlarmTitle(expiringCount)
        : expiringCount == 0
            ? t.certAlarmTitleExpired(expiredCount)
            : t.certAlarmTitleMixed(expiredCount, expiringCount);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
      color: alarm.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: alarm, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: alarm, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class CertificationScreen extends StatefulWidget {
  final Vessel vessel;
  const CertificationScreen({super.key, required this.vessel});

  @override
  State<CertificationScreen> createState() => _CertificationScreenState();
}

class _CertificationScreenState extends State<CertificationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final certs = context.watch<CertificationProvider>();
    final alarmVesselCerts = certs.alarmVesselCerts([widget.vessel.id]);
    final alarmCrewCerts = certs.alarmCrewCerts([widget.vessel.id]);
    final expiredCount = alarmVesselCerts
            .where((c) => c.reminderStatus == CertReminderStatus.expired)
            .length +
        alarmCrewCerts
            .where((c) => c.reminderStatus == CertReminderStatus.expired)
            .length;
    final alarmCount = alarmVesselCerts.length + alarmCrewCerts.length;
    final expiringCount = alarmCount - expiredCount;
    return Scaffold(
      appBar: AppBar(
        title: Text('${t.certification} — ${widget.vessel.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: t.vesselCerts), Tab(text: t.crewCerts)],
        ),
        actions: [
          AiFillAction(onPressed: () => _extractFromFile(context, t)),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t.add,
            onPressed: () => _tabController.index == 0
                ? _showAddVesselCertSheet(context, t)
                : _showAddCrewCertSheet(context, t),
          ),
        ],
      ),
      body: Column(
        children: [
          if (alarmCount > 0)
            _ExpiryAlarmBanner(
                expiredCount: expiredCount, expiringCount: expiringCount),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _VesselCertsTab(vessel: widget.vessel),
                _CrewCertsTab(vessel: widget.vessel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AI-assisted entry: reads certificate scans / status lists for whichever
  /// tab is active. Each certificate found is reviewed in the normal add
  /// sheet before it is saved.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final isVesselTab = _tabController.index == 0;
    final outcome = await pickAndExtract(context, t,
        kind: isVesselTab ? 'vessel_certificate' : 'crew_certificate');
    if (outcome == null) return;
    final items = outcome.result.items ?? [];
    for (var i = 0; i < items.length; i++) {
      if (!context.mounted) return;
      final label = items.length > 1 ? '(${i + 1}/${items.length})' : null;
      if (isVesselTab) {
        await _showAddVesselCertSheet(context, t,
            prefill: items[i],
            initialAttachments: [outcome.file],
            progressLabel: label);
      } else {
        await _showAddCrewCertSheet(context, t,
            prefill: items[i],
            initialAttachments: [outcome.file],
            progressLabel: label);
      }
    }
  }

  Future<void> _showAddVesselCertSheet(
    BuildContext context,
    AppLocalizations t, {
    Map<String, dynamic>? prefill,
    List<Attachment> initialAttachments = const [],
    String? progressLabel,
    VesselCertificate? existing,
  }) =>
      showVesselCertSheet(context, t, widget.vessel,
          prefill: prefill,
          initialAttachments: initialAttachments,
          progressLabel: progressLabel,
          existing: existing);

  Future<void> _showAddCrewCertSheet(
    BuildContext context,
    AppLocalizations t, {
    Map<String, dynamic>? prefill,
    List<Attachment> initialAttachments = const [],
    String? progressLabel,
    CrewCertificate? existing,
  }) =>
      showCrewCertSheet(context, t, widget.vessel,
          prefill: prefill,
          initialAttachments: initialAttachments,
          progressLabel: progressLabel,
          existing: existing);
}

/// Add/edit sheet for a vessel certificate. Public so [_VesselCertsTab] can
/// open it pre-filled via [existing] for its Edit action.
Future<void> showVesselCertSheet(
  BuildContext context,
  AppLocalizations t,
  Vessel vessel, {
  Map<String, dynamic>? prefill,
  List<Attachment> initialAttachments = const [],
  String? progressLabel,
  VesselCertificate? existing,
}) {
    final nameController = TextEditingController(
        text: existing?.documentName ?? aiStr(prefill, 'documentName'));
    final authorityController = TextEditingController(
        text: existing?.issuingAuthority ?? aiStr(prefill, 'issuingAuthority'));
    DateTime issueDate = existing?.issueDate ??
        aiDateIn(prefill, 'issueDate', DateTime(2000),
            DateTime.now().add(const Duration(days: 365))) ??
        DateTime.now();
    DateTime expiryDate = existing?.expiryDate ??
        aiDateIn(prefill, 'expiryDate', DateTime(2000),
            DateTime.now().add(const Duration(days: 3650))) ??
        DateTime.now().add(const Duration(days: 365));
    List<Attachment> certFiles = [...(existing?.attachments ?? initialAttachments)];

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
                    Text(
                        [
                          existing != null ? t.edit : t.addVesselCert,
                          if (progressLabel != null) progressLabel,
                        ].join(' '),
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration:
                          InputDecoration(labelText: t.documentNameLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: authorityController,
                      decoration:
                          InputDecoration(labelText: t.issuingAuthorityLabel),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: sheetContext,
                                initialDate: issueDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (d != null) setState(() => issueDate = d);
                            },
                            child: InputDecorator(
                              decoration:
                                  InputDecoration(labelText: t.issueDateLabel),
                              child: Text(dateFmt.format(issueDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: sheetContext,
                                initialDate: expiryDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 3650)),
                              );
                              if (d != null) setState(() => expiryDate = d);
                            },
                            child: InputDecorator(
                              decoration:
                                  InputDecoration(labelText: t.expiryDateLabel),
                              child: Text(dateFmt.format(expiryDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: certFiles,
                      onAdd: (file) =>
                          setState(() => certFiles = [...certFiles, file]),
                      onRemove: (index) => setState(
                          () => certFiles = [...certFiles]..removeAt(index)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          if (existing != null) {
                            context.read<CertificationProvider>().updateVesselCert(
                                  id: existing.id,
                                  documentName: nameController.text.trim(),
                                  issuingAuthority:
                                      authorityController.text.trim(),
                                  issueDate: issueDate,
                                  expiryDate: expiryDate,
                                );
                          } else {
                            context.read<CertificationProvider>().addVesselCert(
                                  vesselId: vessel.id,
                                  documentName: nameController.text.trim(),
                                  issuingAuthority:
                                      authorityController.text.trim(),
                                  issueDate: issueDate,
                                  expiryDate: expiryDate,
                                  attachments: certFiles,
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

/// Add/edit sheet for a crew certificate. Public so [_CrewCertsTab] can open
/// it pre-filled via [existing] for its Edit action.
Future<void> showCrewCertSheet(
  BuildContext context,
  AppLocalizations t,
  Vessel vessel, {
  Map<String, dynamic>? prefill,
  List<Attachment> initialAttachments = const [],
  String? progressLabel,
  CrewCertificate? existing,
}) {
    final nameController = TextEditingController(
        text: existing?.officerName ?? aiStr(prefill, 'officerName'));
    final rankController =
        TextEditingController(text: existing?.rank ?? aiStr(prefill, 'rank'));
    CrewCertType certType = existing?.certType ??
        aiEnum(prefill, 'certType', CrewCertType.values, CrewCertType.stcw);
    DateTime issueDate = existing?.issueDate ??
        aiDateIn(prefill, 'issueDate', DateTime(2000),
            DateTime.now().add(const Duration(days: 365))) ??
        DateTime.now();
    DateTime expiryDate = existing?.expiryDate ??
        aiDateIn(prefill, 'expiryDate', DateTime(2000),
            DateTime.now().add(const Duration(days: 3650))) ??
        DateTime.now().add(const Duration(days: 365));
    String? photoBase64 = existing?.photoBase64;
    List<Attachment> certDocs = [...(existing?.attachments ?? initialAttachments)];

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
                    Text(
                        [
                          existing != null ? t.edit : t.addCrewCert,
                          if (progressLabel != null) progressLabel,
                        ].join(' '),
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    PhotoPickerStrip(
                      photosBase64: photoBase64 == null ? [] : [photoBase64!],
                      multiple: false,
                      onAdd: (encoded) => setState(() => photoBase64 = encoded),
                      onRemove: (_) => setState(() => photoBase64 = null),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration:
                          InputDecoration(labelText: t.officerNameLabel),
                    ),
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: certDocs,
                      onAdd: (file) =>
                          setState(() => certDocs = [...certDocs, file]),
                      onRemove: (index) => setState(
                          () => certDocs = [...certDocs]..removeAt(index)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: rankController,
                      decoration: InputDecoration(labelText: t.rankLabel),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<CrewCertType>(
                      initialValue: certType,
                      decoration: InputDecoration(labelText: t.certTypeLabel),
                      items: [
                        DropdownMenuItem(
                            value: CrewCertType.coc,
                            child: Text(t.certTypeCoc)),
                        DropdownMenuItem(
                            value: CrewCertType.stcw,
                            child: Text(t.certTypeStcw)),
                        DropdownMenuItem(
                            value: CrewCertType.medical,
                            child: Text(t.certTypeMedical)),
                        DropdownMenuItem(
                            value: CrewCertType.other,
                            child: Text(t.certTypeOther)),
                      ],
                      onChanged: (v) =>
                          setState(() => certType = v ?? certType),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: sheetContext,
                                initialDate: issueDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (d != null) setState(() => issueDate = d);
                            },
                            child: InputDecorator(
                              decoration:
                                  InputDecoration(labelText: t.issueDateLabel),
                              child: Text(dateFmt.format(issueDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: sheetContext,
                                initialDate: expiryDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 3650)),
                              );
                              if (d != null) setState(() => expiryDate = d);
                            },
                            child: InputDecorator(
                              decoration:
                                  InputDecoration(labelText: t.expiryDateLabel),
                              child: Text(dateFmt.format(expiryDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          if (existing != null) {
                            context.read<CertificationProvider>().updateCrewCert(
                                  id: existing.id,
                                  officerName: nameController.text.trim(),
                                  rank: rankController.text.trim(),
                                  certType: certType,
                                  issueDate: issueDate,
                                  expiryDate: expiryDate,
                                  photoBase64: photoBase64,
                                );
                          } else {
                            context.read<CertificationProvider>().addCrewCert(
                                  vesselId: vessel.id,
                                  officerName: nameController.text.trim(),
                                  rank: rankController.text.trim(),
                                  certType: certType,
                                  issueDate: issueDate,
                                  expiryDate: expiryDate,
                                  photoBase64: photoBase64,
                                  attachments: certDocs,
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

class _VesselCertsTab extends StatelessWidget {
  final Vessel vessel;
  const _VesselCertsTab({required this.vessel});

  void _showAttachments(
      BuildContext context, AppLocalizations t, VesselCertificate cert) {
    final provider = context.read<CertificationProvider>();
    var files = cert.attachments;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => Padding(
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
              Text(cert.documentName,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              if (cert.issuingAuthority.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(cert.issuingAuthority,
                    style: Theme.of(sheetContext).textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              Text(t.attachmentsLabel,
                  style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: 6),
              AttachmentPickerStrip(
                attachments: files,
                onAdd: (file) {
                  provider.addVesselCertAttachment(cert.id, file);
                  setState(() => files = [...files, file]);
                },
                onRemove: (index) {
                  provider.removeVesselCertAttachment(cert.id, index);
                  setState(() => files = [...files]..removeAt(index));
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  showVesselCertSheet(context, t, vessel, existing: cert);
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(t.edit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<CertificationProvider>();
    final certs = provider.vesselCertsFor(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    if (certs.isEmpty) {
      return Center(
          child: Text(t.noCertificates,
              style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: certs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cert = certs[index];
        final color = reminderColor(cert.reminderStatus);
        return Card(
          child: ListTile(
            onTap: () => _showAttachments(context, t, cert),
            leading: Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            title: Text(cert.documentName),
            subtitle: Text(
                '${cert.issuingAuthority}\n${t.expiryDateLabel}: ${dateFmt.format(cert.expiryDate)}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cert.attachments.isNotEmpty) ...[
                  const Icon(Icons.attach_file, size: 16),
                  Text('${cert.attachments.length}'),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: t.delete,
                  onPressed: () async {
                    final ok = await confirmDelete(context,
                        itemName: cert.documentName);
                    if (ok && context.mounted) {
                      context
                          .read<CertificationProvider>()
                          .deleteVesselCert(cert.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CrewCertsTab extends StatelessWidget {
  final Vessel vessel;
  const _CrewCertsTab({required this.vessel});

  String _typeLabel(AppLocalizations t, CrewCertType type) {
    switch (type) {
      case CrewCertType.coc:
        return t.certTypeCoc;
      case CrewCertType.stcw:
        return t.certTypeStcw;
      case CrewCertType.medical:
        return t.certTypeMedical;
      case CrewCertType.other:
        return t.certTypeOther;
    }
  }

  void _showAttachments(
      BuildContext context, AppLocalizations t, CrewCertificate cert) {
    final provider = context.read<CertificationProvider>();
    var files = cert.attachments;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => Padding(
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
              Text('${cert.officerName} — ${cert.rank}',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(_typeLabel(t, cert.certType),
                  style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(t.attachmentsLabel,
                  style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: 6),
              AttachmentPickerStrip(
                attachments: files,
                onAdd: (file) {
                  provider.addCrewCertAttachment(cert.id, file);
                  setState(() => files = [...files, file]);
                },
                onRemove: (index) {
                  provider.removeCrewCertAttachment(cert.id, index);
                  setState(() => files = [...files]..removeAt(index));
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  showCrewCertSheet(context, t, vessel, existing: cert);
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(t.edit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<CertificationProvider>();
    final certs = provider.crewCertsFor(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    if (certs.isEmpty) {
      return Center(
          child: Text(t.noCertificates,
              style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: certs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cert = certs[index];
        final color = reminderColor(cert.reminderStatus);
        return Card(
          child: ListTile(
            onTap: () => _showAttachments(context, t, cert),
            leading: cert.photoBase64 != null
                ? CircleAvatar(
                    backgroundImage:
                        MemoryImage(base64Decode(cert.photoBase64!)))
                : CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(Icons.person, color: color)),
            title: Text('${cert.officerName} — ${cert.rank}'),
            subtitle: Text(
              '${_typeLabel(t, cert.certType)}\n${t.expiryDateLabel}: ${dateFmt.format(cert.expiryDate)}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cert.attachments.isNotEmpty) ...[
                  const Icon(Icons.attach_file, size: 16),
                  Text('${cert.attachments.length}'),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: t.delete,
                  onPressed: () async {
                    final ok = await confirmDelete(context,
                        itemName: '${cert.officerName} — ${cert.rank}');
                    if (ok && context.mounted) {
                      context
                          .read<CertificationProvider>()
                          .deleteCrewCert(cert.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
