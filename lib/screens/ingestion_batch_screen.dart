import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/crew_certificate.dart';
import '../models/daily_task.dart';
import '../models/defect.dart';
import '../models/module_item.dart';
import '../models/port_requirement.dart';
import '../models/requisition.dart';
import '../models/urgent_notification.dart';
import '../models/vessel.dart';
import '../state/auth_provider.dart';
import '../state/certification_provider.dart';
import '../state/crew_provider.dart';
import '../state/daily_tasks_provider.dart';
import '../state/handover_provider.dart';
import '../state/ingestion_provider.dart';
import '../state/maintenance_provider.dart';
import '../state/port_call_provider.dart';
import '../state/port_requirement_provider.dart';
import '../state/tank_data_provider.dart';
import '../state/urgent_notification_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';

/// Bulk file ingestion: upload many files at once, each gets auto-routed to
/// a module kind (see routing_rules.dart) and extracted (reusing the same
/// `extract` edge function every single-file AI-fill screen already calls),
/// then staged here for review. Nothing reaches a module's real table until
/// a human accepts a staged item — same invariant as single-file AI-fill,
/// just applied to many files/modules in one pass.
class IngestionBatchScreen extends StatefulWidget {
  final Vessel vessel;
  const IngestionBatchScreen({super.key, required this.vessel});

  @override
  State<IngestionBatchScreen> createState() => _IngestionBatchScreenState();
}

class _IngestionBatchScreenState extends State<IngestionBatchScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureBatch());
  }

  Future<void> _ensureBatch() async {
    final provider = context.read<IngestionBatchProvider>();
    if (provider.active != null) return;
    final username = context.read<AuthProvider>().currentUser?.username ?? '';
    await provider.startBatch(uploadedBy: username, vesselScope: [widget.vessel.id]);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
      allowMultiple: true,
    );
    final picked = result?.files ?? const <PlatformFile>[];
    if (picked.isEmpty || !mounted) return;
    setState(() => _busy = true);
    final files = <(String, Uint8List)>[
      for (final f in picked)
        if (f.bytes != null) (f.name, f.bytes!),
    ];
    final provider = context.read<IngestionBatchProvider>();
    await provider.addFiles(files);
    await provider.processAll(targetVesselId: widget.vessel.id);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _accept(ModuleItem item) async {
    final provider = context.read<IngestionBatchProvider>();
    final file = provider.files.where((f) => f.id == item.sourceFileId);
    final source = file.isEmpty ? null : file.first.attachment;
    try {
      await _persist(context, item, widget.vessel, source);
      provider.markPersisted(item.id, '');
    } catch (_) {
      await provider.logPersistError(item.id, 'persist_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<IngestionBatchProvider>();
    final byKind = provider.itemsByKind;
    final summary = provider.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.bulkImport} — ${widget.vessel.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: t.addFiles,
            onPressed: _busy ? null : _pickFiles,
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SummaryBar(t: t, summary: summary, errorCount: provider.errors.length),
                const SizedBox(height: 20),
                if (provider.files.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Text(t.bulkImportEmpty,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                for (final entry in byKind.entries) ...[
                  Text(_kindLabel(t, entry.key),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  for (final item in entry.value)
                    if (item.status == ItemStatus.pending)
                      _StagedItemCard(
                        item: item,
                        onAccept: () => _accept(item),
                        onReject: () => provider.rejectItem(item.id),
                        onEdit: (fields) => provider.updateItemFields(item.id, fields),
                      ),
                  const SizedBox(height: 20),
                ],
                if (provider.errors.isNotEmpty) ...[
                  Text(t.bulkImportErrors,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  for (final err in provider.errors)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.error_outline,
                            color: AppColors.statusMaintenance),
                        title: Text(err.reasonCode),
                        subtitle: Text(err.message.isEmpty ? err.stage.name : err.message),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  String _kindLabel(AppLocalizations t, String kind) {
    switch (kind) {
      case 'defect':
        return t.defects;
      case 'requisition':
        return t.requisitions;
      case 'tank_reading':
        return t.tankSystems;
      case 'logbook':
        return t.logbook;
      case 'maintenance':
        return t.maintenance;
      case 'port_call':
        return t.portCalls;
      case 'port_requirement':
        return t.portRequirements;
      case 'vessel_certificate':
        return t.vesselCerts;
      case 'crew_certificate':
        return t.crewCerts;
      case 'crew':
        return t.crew;
      case 'daily_task':
        return t.dailyTasks;
      case 'urgent_notification':
        return t.urgentNotifications;
      case 'handover':
        return t.handover;
      default:
        return kind;
    }
  }
}

Future<void> _persist(BuildContext context, ModuleItem item, Vessel vessel,
    Attachment? sourceFile) async {
  final f = item.fields;
  final attachments = sourceFile == null ? const <Attachment>[] : [sourceFile];
  switch (item.targetKind) {
    case 'defect':
      await context.read<TankDataProvider>().addDefect(
            vesselId: vessel.id,
            title: aiStr(f, 'title'),
            description: aiStr(f, 'description'),
            location: aiEnum(f, 'location', DefectLocation.values, DefectLocation.other),
            priority: aiEnum(f, 'priority', DefectPriority.values, DefectPriority.medium),
            assignedOfficer: aiStr(f, 'assignedOfficer'),
            requiredSpareParts: aiStr(f, 'requiredSpareParts'),
            attachments: attachments,
          );
    case 'requisition':
      await context.read<TankDataProvider>().addRequisition(
            vesselId: vessel.id,
            vesselName: vessel.name,
            itemName: aiStr(f, 'itemName'),
            partNumber: aiStr(f, 'partNumber'),
            oemManufacturer: aiStr(f, 'oemManufacturer'),
            quantity: aiNum(f, 'quantity') ?? 0,
            quantityInStock: 0,
            unit: aiStrOr(f, 'unit', 'pcs'),
            unitPrice: aiNum(f, 'unitPrice') ?? 0,
            department: aiEnum(
                f, 'department', RequisitionDepartment.values, RequisitionDepartment.deck),
            priority:
                aiEnum(f, 'priority', RequisitionPriority.values, RequisitionPriority.normal),
            notes: aiStr(f, 'notes'),
            attachments: attachments,
          );
    case 'tank_reading':
      final tankName = aiStr(f, 'tankName').toLowerCase().trim();
      var tankId = '';
      for (final tank in vessel.tanks) {
        final name = tank.name.toLowerCase();
        if (name == tankName || name.contains(tankName) || tankName.contains(name)) {
          tankId = tank.id;
          break;
        }
      }
      if (tankId.isEmpty) throw Exception('tank_not_found');
      await context.read<TankDataProvider>().addReading(
            vessel.id,
            tankId,
            aiNum(f, 'levelM3') ?? 0,
            temperatureC: aiNum(f, 'temperatureC'),
          );
    case 'logbook':
      await context
          .read<TankDataProvider>()
          .addNote(vessel.id, aiStr(f, 'text'), attachments: attachments);
    case 'maintenance':
      await context.read<MaintenanceProvider>().add(
            vesselId: vessel.id,
            title: aiStr(f, 'title'),
            description: aiStr(f, 'description'),
            performedBy: aiStr(f, 'performedBy'),
            dueDate: aiDate(f, 'dueDate') ?? DateTime.now(),
            attachments: attachments,
          );
    case 'port_call':
      await context.read<PortCallProvider>().add(
            vesselId: vessel.id,
            portName: aiStr(f, 'portName'),
            arrivalEta: aiDate(f, 'arrivalEta') ?? DateTime.now(),
            pilotBoardingTime: aiDate(f, 'pilotBoardingTime'),
            agentName: aiStr(f, 'agentName'),
            agentContact: aiStr(f, 'agentContact'),
            bunkersMgoRequired: aiNum(f, 'bunkersMgoRequired') ?? 0,
            bunkersHfoRequired: aiNum(f, 'bunkersHfoRequired') ?? 0,
            freshWaterRequired: aiNum(f, 'freshWaterRequired') ?? 0,
            provisionsRequired: aiStr(f, 'provisionsRequired'),
            sludgeDisposalRequired: aiBool(f, 'sludgeDisposalRequired'),
            sludgeQuantity: aiNum(f, 'sludgeQuantity') ?? 0,
          );
    case 'port_requirement':
      await context.read<PortRequirementProvider>().add(
            vesselId: vessel.id,
            title: aiStr(f, 'title'),
            portName: aiStr(f, 'portName'),
            category:
                aiEnum(f, 'category', RequirementCategory.values, RequirementCategory.documents),
            notes: aiStr(f, 'notes'),
            attachments: attachments,
          );
    case 'vessel_certificate':
      await context.read<CertificationProvider>().addVesselCert(
            vesselId: vessel.id,
            documentName: aiStr(f, 'documentName'),
            issuingAuthority: aiStr(f, 'issuingAuthority'),
            issueDate: aiDate(f, 'issueDate') ?? DateTime.now(),
            expiryDate: aiDate(f, 'expiryDate') ?? DateTime.now(),
            attachments: attachments,
          );
    case 'crew_certificate':
      await context.read<CertificationProvider>().addCrewCert(
            vesselId: vessel.id,
            officerName: aiStr(f, 'officerName'),
            rank: aiStr(f, 'rank'),
            certType: aiEnum(f, 'certType', CrewCertType.values, CrewCertType.other),
            issueDate: aiDate(f, 'issueDate') ?? DateTime.now(),
            expiryDate: aiDate(f, 'expiryDate') ?? DateTime.now(),
            attachments: attachments,
          );
    case 'crew':
      await context.read<CrewProvider>().add(
            vesselId: vessel.id,
            name: aiStr(f, 'name'),
            rank: aiStr(f, 'rank'),
            nationality: aiStr(f, 'nationality'),
            signOnDate: aiDate(f, 'signOnDate'),
            notes: aiStr(f, 'notes'),
          );
    case 'daily_task':
      await context.read<DailyTasksProvider>().add(
            vesselId: vessel.id,
            category: aiEnum(f, 'category', TaskCategory.values, TaskCategory.engineRoomRounds),
            title: aiStr(f, 'title'),
            assignedTo: aiStr(f, 'assignedTo'),
            frequency: aiEnum(f, 'frequency', TaskFrequency.values, TaskFrequency.daily),
            scheduledTime: aiDate(f, 'scheduledTime') ?? DateTime.now(),
            checklistLabels: const [],
          );
    case 'urgent_notification':
      await context.read<UrgentNotificationProvider>().add(
            vesselId: vessel.id,
            alertType: aiEnum(f, 'alertType', AlertType.values, AlertType.other),
            location: aiStr(f, 'location'),
            description: aiStr(f, 'description'),
          );
    case 'handover':
      await context.read<HandoverProvider>().add(
            vesselId: vessel.id,
            outgoingOfficer: aiStr(f, 'outgoingOfficer'),
            incomingOfficer: aiStr(f, 'incomingOfficer'),
            rank: aiStr(f, 'rank'),
            handoverDate: aiDate(f, 'handoverDate') ?? DateTime.now(),
            safety: aiStr(f, 'safety'),
            machinery: aiStr(f, 'machinery'),
            pendingDefects: aiStr(f, 'pendingDefects'),
            bunkersAndTanks: aiStr(f, 'bunkersAndTanks'),
            certificatesExpiring: aiStr(f, 'certificatesExpiring'),
            remarks: aiStr(f, 'remarks'),
            attachments: attachments,
          );
    default:
      throw Exception('unknown_kind');
  }
}

class _SummaryBar extends StatelessWidget {
  final AppLocalizations t;
  final dynamic summary; // BatchSummary
  final int errorCount;
  const _SummaryBar({required this.t, required this.summary, required this.errorCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _stat(context, t.bulkImportFilesTotal, '${summary.filesTotal}'),
            _stat(context, t.bulkImportFilesFailed, '${summary.filesFailed}'),
            _stat(context, t.bulkImportDuplicates, '${summary.duplicatesSkipped}'),
            _stat(context, t.bulkImportUnclassified, '${summary.unclassified}'),
            _stat(context, t.bulkImportErrors, '$errorCount'),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _StagedItemCard extends StatefulWidget {
  final ModuleItem item;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final ValueChanged<Map<String, dynamic>> onEdit;
  const _StagedItemCard({
    required this.item,
    required this.onAccept,
    required this.onReject,
    required this.onEdit,
  });

  @override
  State<_StagedItemCard> createState() => _StagedItemCardState();
}

class _StagedItemCardState extends State<_StagedItemCard> {
  late final Map<String, TextEditingController> _controllers = {
    for (final entry in widget.item.fields.entries)
      entry.key: TextEditingController(text: entry.value?.toString() ?? ''),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _commit() {
    final updated = {for (final e in _controllers.entries) e.key: e.value.text};
    widget.onEdit(updated);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final key in _controllers.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _controllers[key],
                  decoration: InputDecoration(labelText: key),
                  onSubmitted: (_) => _commit(),
                  onTapOutside: (_) => _commit(),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onReject,
                  child: Text(t.delete),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    _commit();
                    widget.onAccept();
                  },
                  child: Text(t.bulkImportAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
