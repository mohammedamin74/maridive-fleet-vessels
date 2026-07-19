import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/port_call.dart';
import '../models/vessel.dart';
import '../state/port_call_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_fill.dart';
import 'port_call_detail_screen.dart';

class PortCallListScreen extends StatelessWidget {
  final Vessel vessel;
  const PortCallListScreen({super.key, required this.vessel});

  Color _statusColor(PortCallStatus s) {
    switch (s) {
      case PortCallStatus.upcoming:
        return AppColors.amber400;
      case PortCallStatus.arrived:
        return AppColors.teal500;
      case PortCallStatus.departed:
        return AppColors.statusActive;
    }
  }

  String _statusLabel(AppLocalizations t, PortCallStatus s) {
    switch (s) {
      case PortCallStatus.upcoming:
        return t.portStatusUpcoming;
      case PortCallStatus.arrived:
        return t.portStatusArrived;
      case PortCallStatus.departed:
        return t.portStatusDeparted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<PortCallProvider>();
    final calls = provider.forVessel(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.portCalls} — ${vessel.name}'),
        actions: [
          AiFillAction(onPressed: () => _extractFromFile(context, t)),
          IconButton(
              icon: const Icon(Icons.add),
              tooltip: t.add,
              onPressed: () => _showAddSheet(context, t)),
        ],
      ),
      body: calls.isEmpty
          ? Center(
              child: Text(t.noPortCalls,
                  style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: calls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final call = calls[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => PortCallDetailScreen(portCall: call)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(call.portName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(call.status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusLabel(t, call.status),
                                  style: TextStyle(
                                      color: _statusColor(call.status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${t.arrivalEtaLabel}: ${dateFmt.format(call.arrivalEta)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (call.agentName.isNotEmpty)
                            Text(
                              '${t.agentLabel}: ${call.agentName}',
                              style: Theme.of(context).textTheme.bodyMedium,
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

  /// AI-assisted entry: extract port call logistics from an agent message /
  /// pre-arrival notice, reviewed in the normal add sheet before saving.
  /// (The source file can be attached from the port call's detail screen.)
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'port_call');
    if (outcome == null || !context.mounted) return;
    showPortCallSheet(context, t, vessel, prefill: outcome.result.fields);
  }

  void _showAddSheet(BuildContext context, AppLocalizations t,
          {Map<String, dynamic>? prefill}) =>
      showPortCallSheet(context, t, vessel, prefill: prefill);
}

/// Add/edit sheet for a port call. Public so [PortCallDetailScreen] can open
/// it pre-filled via [existing] for its Edit action.
void showPortCallSheet(BuildContext context, AppLocalizations t, Vessel vessel,
    {Map<String, dynamic>? prefill, PortCall? existing}) {
    final portController = TextEditingController(
        text: existing?.portName ?? aiStr(prefill, 'portName'));
    final agentNameController = TextEditingController(
        text: existing?.agentName ?? aiStr(prefill, 'agentName'));
    final agentContactController = TextEditingController(
        text: existing?.agentContact ?? aiStr(prefill, 'agentContact'));
    final mgoController = TextEditingController(
        text: existing != null
            ? existing.bunkersMgoRequired.toString()
            : aiNumStr(prefill, 'bunkersMgoRequired', '0'));
    final hfoController = TextEditingController(
        text: existing != null
            ? existing.bunkersHfoRequired.toString()
            : aiNumStr(prefill, 'bunkersHfoRequired', '0'));
    final fwController = TextEditingController(
        text: existing != null
            ? existing.freshWaterRequired.toString()
            : aiNumStr(prefill, 'freshWaterRequired', '0'));
    final provisionsController = TextEditingController(
        text: existing?.provisionsRequired ??
            aiStr(prefill, 'provisionsRequired'));
    final sludgeQtyController = TextEditingController(
        text: existing != null
            ? existing.sludgeQuantity.toString()
            : aiNumStr(prefill, 'sludgeQuantity', '0'));
    DateTime arrivalEta = existing?.arrivalEta ??
        aiDate(prefill, 'arrivalEta') ??
        DateTime.now().add(const Duration(days: 1));
    DateTime? pilotBoardingTime =
        existing?.pilotBoardingTime ?? aiDate(prefill, 'pilotBoardingTime');
    bool sludgeRequired =
        existing?.sludgeDisposalRequired ?? aiBool(prefill, 'sludgeDisposalRequired');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final locale = Localizations.localeOf(sheetContext).languageCode;
            final dateFmt = DateFormat.yMMMd(locale).add_Hm();
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
                    Text(existing != null ? t.edit : t.addPortCall,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: portController,
                      decoration: InputDecoration(labelText: t.portNameLabel),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: sheetContext,
                          initialDate: arrivalEta,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date == null || !sheetContext.mounted) return;
                        final time = await showTimePicker(
                          context: sheetContext,
                          initialTime: TimeOfDay.fromDateTime(arrivalEta),
                        );
                        setState(() => arrivalEta = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? 0,
                              time?.minute ?? 0,
                            ));
                      },
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: t.arrivalEtaLabel),
                        child: Text(dateFmt.format(arrivalEta)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final base = pilotBoardingTime ?? arrivalEta;
                        final date = await showDatePicker(
                          context: sheetContext,
                          initialDate: base,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date == null || !sheetContext.mounted) return;
                        final time = await showTimePicker(
                          context: sheetContext,
                          initialTime: TimeOfDay.fromDateTime(base),
                        );
                        setState(() => pilotBoardingTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? 0,
                              time?.minute ?? 0,
                            ));
                      },
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: t.pilotBoardingLabel),
                        child: Text(pilotBoardingTime == null
                            ? '—'
                            : dateFmt.format(pilotBoardingTime!)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: agentNameController,
                            decoration:
                                InputDecoration(labelText: t.agentLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: agentContactController,
                            decoration:
                                InputDecoration(labelText: t.agentContactLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: mgoController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                InputDecoration(labelText: t.mgoRequiredLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: hfoController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                InputDecoration(labelText: t.hfoRequiredLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: fwController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: t.freshWaterRequiredLabel),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: provisionsController,
                      minLines: 1,
                      maxLines: 3,
                      decoration:
                          InputDecoration(labelText: t.provisionsRequiredLabel),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.sludgeDisposalLabel),
                      value: sludgeRequired,
                      onChanged: (v) => setState(() => sludgeRequired = v),
                    ),
                    if (sludgeRequired)
                      TextField(
                        controller: sludgeQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            InputDecoration(labelText: t.sludgeQuantityLabel),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (portController.text.trim().isEmpty) return;
                          if (existing != null) {
                            context.read<PortCallProvider>().update(
                                  id: existing.id,
                                  portName: portController.text.trim(),
                                  arrivalEta: arrivalEta,
                                  pilotBoardingTime: pilotBoardingTime,
                                  agentName: agentNameController.text.trim(),
                                  agentContact:
                                      agentContactController.text.trim(),
                                  bunkersMgoRequired:
                                      double.tryParse(mgoController.text) ?? 0,
                                  bunkersHfoRequired:
                                      double.tryParse(hfoController.text) ?? 0,
                                  freshWaterRequired:
                                      double.tryParse(fwController.text) ?? 0,
                                  provisionsRequired:
                                      provisionsController.text.trim(),
                                  sludgeDisposalRequired: sludgeRequired,
                                  sludgeQuantity: double.tryParse(
                                          sludgeQtyController.text) ??
                                      0,
                                );
                          } else {
                            context.read<PortCallProvider>().add(
                                  vesselId: vessel.id,
                                  portName: portController.text.trim(),
                                  arrivalEta: arrivalEta,
                                  pilotBoardingTime: pilotBoardingTime,
                                  agentName: agentNameController.text.trim(),
                                  agentContact:
                                      agentContactController.text.trim(),
                                  bunkersMgoRequired:
                                      double.tryParse(mgoController.text) ?? 0,
                                  bunkersHfoRequired:
                                      double.tryParse(hfoController.text) ?? 0,
                                  freshWaterRequired:
                                      double.tryParse(fwController.text) ?? 0,
                                  provisionsRequired:
                                      provisionsController.text.trim(),
                                  sludgeDisposalRequired: sludgeRequired,
                                  sludgeQuantity: double.tryParse(
                                          sludgeQtyController.text) ??
                                      0,
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
