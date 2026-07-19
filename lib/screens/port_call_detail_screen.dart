import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../data/fleet_data.dart';
import '../models/port_call.dart';
import '../state/port_call_provider.dart';
import '../state/vessel_profile_provider.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/confirm_delete.dart';
import 'port_call_list_screen.dart' show showPortCallSheet;

class PortCallDetailScreen extends StatelessWidget {
  final PortCall portCall;
  const PortCallDetailScreen({super.key, required this.portCall});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<PortCallProvider>();
    final call = provider
        .forVessel(portCall.vesselId)
        .firstWhere((c) => c.id == portCall.id, orElse: () => portCall);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text(call.portName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: t.edit,
            onPressed: () {
              final base =
                  FleetData.vessels.firstWhere((v) => v.id == call.vesselId);
              final resolved =
                  context.read<VesselProfileProvider>().resolve(base);
              showPortCallSheet(context, t, resolved, existing: call);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: t.delete,
            onPressed: () async {
              final ok = await confirmDelete(context, itemName: call.portName);
              if (!ok || !context.mounted) return;
              context.read<PortCallProvider>().delete(call.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row(
                      label: t.arrivalEtaLabel,
                      value: dateFmt.format(call.arrivalEta)),
                  if (call.pilotBoardingTime != null)
                    _Row(
                        label: t.pilotBoardingLabel,
                        value: dateFmt.format(call.pilotBoardingTime!)),
                  if (call.agentName.isNotEmpty)
                    _Row(label: t.agentLabel, value: call.agentName),
                  if (call.agentContact.isNotEmpty)
                    _Row(label: t.agentContactLabel, value: call.agentContact),
                  _Row(
                      label: t.mgoRequiredLabel,
                      value:
                          '${call.bunkersMgoRequired.toStringAsFixed(1)} MT'),
                  _Row(
                      label: t.hfoRequiredLabel,
                      value:
                          '${call.bunkersHfoRequired.toStringAsFixed(1)} MT'),
                  _Row(
                      label: t.freshWaterRequiredLabel,
                      value:
                          '${call.freshWaterRequired.toStringAsFixed(1)} m³'),
                  if (call.provisionsRequired.isNotEmpty)
                    _Row(
                        label: t.provisionsRequiredLabel,
                        value: call.provisionsRequired),
                  if (call.sludgeDisposalRequired)
                    _Row(
                        label: t.sludgeDisposalLabel,
                        value: '${call.sludgeQuantity.toStringAsFixed(1)} m³'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(t.customsChecklistLabel,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(call.customsChecklist.length, (i) {
                final item = call.customsChecklist[i];
                return CheckboxListTile(
                  value: item.checked,
                  title: Text(item.label),
                  onChanged: (v) => context
                      .read<PortCallProvider>()
                      .toggleChecklistItem(call.id, i, v ?? false),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Text(t.attachmentsLabel,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AttachmentPickerStrip(
            attachments: call.attachments,
            onAdd: (file) =>
                context.read<PortCallProvider>().addAttachment(call.id, file),
            onRemove: (i) =>
                context.read<PortCallProvider>().removeAttachment(call.id, i),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (call.status != PortCallStatus.arrived)
                OutlinedButton(
                  onPressed: () => context
                      .read<PortCallProvider>()
                      .updateStatus(call.id, PortCallStatus.arrived),
                  child: Text(t.portStatusArrived),
                ),
              if (call.status != PortCallStatus.departed)
                OutlinedButton(
                  onPressed: () => context
                      .read<PortCallProvider>()
                      .updateStatus(call.id, PortCallStatus.departed),
                  child: Text(t.portStatusDeparted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
