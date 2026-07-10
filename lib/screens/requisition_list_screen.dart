import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/requisition.dart';
import '../models/vessel.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';

class RequisitionListScreen extends StatelessWidget {
  final Vessel vessel;
  const RequisitionListScreen({super.key, required this.vessel});

  Color _priorityColor(RequisitionPriority p) {
    switch (p) {
      case RequisitionPriority.low:
        return AppColors.statusPort;
      case RequisitionPriority.normal:
        return AppColors.teal500;
      case RequisitionPriority.urgent:
        return AppColors.statusMaintenance;
    }
  }

  String _priorityLabel(AppLocalizations t, RequisitionPriority p) {
    switch (p) {
      case RequisitionPriority.low:
        return t.priorityLow;
      case RequisitionPriority.normal:
        return t.priorityNormal;
      case RequisitionPriority.urgent:
        return t.priorityUrgent;
    }
  }

  String _statusLabel(AppLocalizations t, RequisitionStatus s) {
    switch (s) {
      case RequisitionStatus.pending:
        return t.reqStatusPending;
      case RequisitionStatus.approved:
        return t.reqStatusApproved;
      case RequisitionStatus.ordered:
        return t.reqStatusOrdered;
      case RequisitionStatus.received:
        return t.reqStatusReceived;
      case RequisitionStatus.rejected:
        return t.reqStatusRejected;
    }
  }

  Color _statusColor(RequisitionStatus s) {
    switch (s) {
      case RequisitionStatus.pending:
        return AppColors.amber400;
      case RequisitionStatus.approved:
        return AppColors.statusPort;
      case RequisitionStatus.ordered:
        return AppColors.navy500;
      case RequisitionStatus.received:
        return AppColors.statusActive;
      case RequisitionStatus.rejected:
        return AppColors.statusMaintenance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final requisitions = data.requisitionsFor(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.requisitions} — ${vessel.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRequisitionSheet(context, t),
          ),
        ],
      ),
      body: requisitions.isEmpty
          ? Center(child: Text(t.noRequisitions, style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: requisitions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = requisitions[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showRequisitionDetailSheet(context, t, req),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${req.itemName} — ${req.quantity.toStringAsFixed(req.quantity == req.quantity.roundToDouble() ? 0 : 1)} ${req.unit}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              _Chip(label: _priorityLabel(t, req.priority), color: _priorityColor(req.priority)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Chip(label: _statusLabel(t, req.status), color: _statusColor(req.status)),
                              const Spacer(),
                              Text(
                                '${t.requestedOn}: ${dateFmt.format(req.requestedAt)}',
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

  void _showRequisitionDetailSheet(BuildContext context, AppLocalizations t, Requisition req) {
    final data = context.read<TankDataProvider>();
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
              Text(req.itemName, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${req.quantity.toStringAsFixed(req.quantity == req.quantity.roundToDouble() ? 0 : 1)} ${req.unit}',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              if (req.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(req.notes, style: Theme.of(sheetContext).textTheme.bodyLarge),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (req.status == RequisitionStatus.pending) ...[
                    OutlinedButton(
                      onPressed: () {
                        data.updateRequisitionStatus(req.id, RequisitionStatus.approved);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.markApproved),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        data.updateRequisitionStatus(req.id, RequisitionStatus.rejected);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.markRejected),
                    ),
                  ],
                  if (req.status == RequisitionStatus.approved)
                    OutlinedButton(
                      onPressed: () {
                        data.updateRequisitionStatus(req.id, RequisitionStatus.ordered);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.markOrdered),
                    ),
                  if (req.status == RequisitionStatus.ordered)
                    OutlinedButton(
                      onPressed: () {
                        data.updateRequisitionStatus(req.id, RequisitionStatus.received);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.markReceived),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      data.deleteRequisition(req.id);
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.statusMaintenance),
                    label: Text(t.delete, style: const TextStyle(color: AppColors.statusMaintenance)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddRequisitionSheet(BuildContext context, AppLocalizations t) {
    final itemController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'pcs');
    final notesController = TextEditingController();
    RequisitionPriority priority = RequisitionPriority.normal;

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
                    Text(t.addRequisition, style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: itemController,
                      decoration: InputDecoration(labelText: t.itemNameLabel),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: t.quantityLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: InputDecoration(labelText: t.unitLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: t.notesLabel),
                    ),
                    const SizedBox(height: 14),
                    Text(t.priorityLabel, style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<RequisitionPriority>(
                      segments: [
                        ButtonSegment(value: RequisitionPriority.low, label: Text(t.priorityLow)),
                        ButtonSegment(value: RequisitionPriority.normal, label: Text(t.priorityNormal)),
                        ButtonSegment(value: RequisitionPriority.urgent, label: Text(t.priorityUrgent)),
                      ],
                      selected: {priority},
                      onSelectionChanged: (s) => setState(() => priority = s.first),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final qty = double.tryParse(qtyController.text);
                          if (itemController.text.trim().isEmpty || qty == null) return;
                          context.read<TankDataProvider>().addRequisition(
                                vesselId: vessel.id,
                                itemName: itemController.text.trim(),
                                quantity: qty,
                                unit: unitController.text.trim().isEmpty ? 'pcs' : unitController.text.trim(),
                                priority: priority,
                                notes: notesController.text.trim(),
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
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
