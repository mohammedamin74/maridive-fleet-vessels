import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/requisition.dart';
import '../models/vessel.dart';
import '../services/extraction_service.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/attachment_picker.dart';

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

  String _departmentLabel(AppLocalizations t, RequisitionDepartment d) {
    switch (d) {
      case RequisitionDepartment.engine:
        return t.departmentEngine;
      case RequisitionDepartment.deck:
        return t.departmentDeck;
      case RequisitionDepartment.steward:
        return t.departmentSteward;
    }
  }

  String _statusLabel(AppLocalizations t, RequisitionStatus s) {
    switch (s) {
      case RequisitionStatus.pending:
        return t.reqStatusPending;
      case RequisitionStatus.hodApproval:
        return t.reqStatusHod;
      case RequisitionStatus.technicalSupApproval:
        return t.reqStatusTechSup;
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
      case RequisitionStatus.hodApproval:
      case RequisitionStatus.technicalSupApproval:
        return AppColors.navy500;
      case RequisitionStatus.approved:
        return AppColors.statusPort;
      case RequisitionStatus.ordered:
        return AppColors.teal500;
      case RequisitionStatus.received:
        return AppColors.statusActive;
      case RequisitionStatus.rejected:
        return AppColors.statusMaintenance;
    }
  }

  String _fmtQty(double q) => q.toStringAsFixed(q == q.roundToDouble() ? 0 : 1);

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
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: t.extractFromFile,
            onPressed: () => _extractFromFile(context, t),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRequisitionSheet(context, t),
          ),
        ],
      ),
      body: requisitions.isEmpty
          ? Center(
              child: Text(t.noRequisitions,
                  style: Theme.of(context).textTheme.bodyMedium))
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
                          Text(
                            req.requisitionNumber,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${req.itemName} — ${_fmtQty(req.quantity)} ${req.unit}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              _Chip(
                                  label: _priorityLabel(t, req.priority),
                                  color: _priorityColor(req.priority)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Chip(
                                  label: _statusLabel(t, req.status),
                                  color: _statusColor(req.status)),
                              const SizedBox(width: 8),
                              Text(
                                _departmentLabel(t, req.department),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (req.attachments.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.attach_file,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 2),
                                Text('${req.attachments.length}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
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

  void _showRequisitionDetailSheet(
      BuildContext context, AppLocalizations t, Requisition req) {
    final data = context.read<TankDataProvider>();
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);
    var files = req.attachments;
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
                    Text(req.requisitionNumber,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(req.itemName,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmtQty(req.quantity)} ${req.unit} · ${_departmentLabel(t, req.department)}',
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                    if (req.partNumber.isNotEmpty ||
                        req.oemManufacturer.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      if (req.partNumber.isNotEmpty)
                        Text('${t.partNumberLabel}: ${req.partNumber}',
                            style: Theme.of(sheetContext).textTheme.bodyMedium),
                      if (req.oemManufacturer.isNotEmpty)
                        Text('${t.oemLabel}: ${req.oemManufacturer}',
                            style: Theme.of(sheetContext).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${t.stockLabel}: ${_fmtQty(req.quantityInStock)} ${req.unit} · ${t.unitPriceLabel}: ${req.unitPrice.toStringAsFixed(2)}',
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                    if (req.requiredDeliveryDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${t.requiredDeliveryLabel}: ${dateFmt.format(req.requiredDeliveryDate!)}',
                        style: Theme.of(sheetContext).textTheme.bodyMedium,
                      ),
                    ],
                    if (req.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(req.notes,
                          style: Theme.of(sheetContext).textTheme.bodyLarge),
                    ],
                    const SizedBox(height: 14),
                    Text(t.attachmentsLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    AttachmentPickerStrip(
                      attachments: files,
                      onAdd: (file) {
                        data.addRequisitionAttachment(req.id, file);
                        setState(() => files = [...files, file]);
                      },
                      onRemove: (index) {
                        data.removeRequisitionAttachment(req.id, index);
                        setState(() => files = [...files]..removeAt(index));
                      },
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (req.status == RequisitionStatus.pending) ...[
                          OutlinedButton(
                            onPressed: () {
                              data.updateRequisitionStatus(
                                  req.id, RequisitionStatus.hodApproval);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markHodApproval),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              data.updateRequisitionStatus(
                                  req.id, RequisitionStatus.rejected);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markRejected),
                          ),
                        ],
                        if (req.status == RequisitionStatus.hodApproval) ...[
                          OutlinedButton(
                            onPressed: () {
                              data.updateRequisitionStatus(req.id,
                                  RequisitionStatus.technicalSupApproval);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markTechSupApproval),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              data.updateRequisitionStatus(
                                  req.id, RequisitionStatus.rejected);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markRejected),
                          ),
                        ],
                        if (req.status ==
                            RequisitionStatus.technicalSupApproval) ...[
                          OutlinedButton(
                            onPressed: () {
                              data.updateRequisitionStatus(
                                  req.id, RequisitionStatus.approved);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markApproved),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              data.updateRequisitionStatus(
                                  req.id, RequisitionStatus.rejected);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markRejected),
                          ),
                        ],
                        if (req.status == RequisitionStatus.approved)
                          OutlinedButton(
                            onPressed: () {
                              data.updateRequisitionStatus(
                                  req.id, RequisitionStatus.ordered);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markOrdered),
                          ),
                        if (req.status == RequisitionStatus.ordered)
                          OutlinedButton(
                            onPressed: () {
                              data.updateRequisitionStatus(
                                  req.id, RequisitionStatus.received);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(t.markReceived),
                          ),
                        TextButton.icon(
                          onPressed: () {
                            data.deleteRequisition(req.id);
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddRequisitionSheet(
    BuildContext context,
    AppLocalizations t, {
    Map<String, dynamic>? prefill,
    List<Attachment> initialAttachments = const [],
  }) {
    final itemController =
        TextEditingController(text: _str(prefill, 'itemName'));
    final partNumberController =
        TextEditingController(text: _str(prefill, 'partNumber'));
    final oemController =
        TextEditingController(text: _str(prefill, 'oemManufacturer'));
    final qtyController =
        TextEditingController(text: _numStr(prefill, 'quantity', '1'));
    final stockController = TextEditingController(text: '0');
    final unitController =
        TextEditingController(text: _strOr(prefill, 'unit', 'pcs'));
    final priceController =
        TextEditingController(text: _numStr(prefill, 'unitPrice', '0'));
    final notesController = TextEditingController(text: _str(prefill, 'notes'));
    RequisitionPriority priority = _enumFrom(RequisitionPriority.values,
        _str(prefill, 'priority'), RequisitionPriority.normal);
    RequisitionDepartment department = _enumFrom(RequisitionDepartment.values,
        _str(prefill, 'department'), RequisitionDepartment.deck);
    DateTime? requiredDeliveryDate;
    List<Attachment> newFiles = [...initialAttachments];

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
                    Text(
                        prefill != null
                            ? t.reviewExtractedRequisition
                            : t.addRequisition,
                        style: Theme.of(sheetContext).textTheme.titleLarge),
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
                            controller: partNumberController,
                            decoration:
                                InputDecoration(labelText: t.partNumberLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: oemController,
                            decoration: InputDecoration(labelText: t.oemLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                InputDecoration(labelText: t.quantityLabel),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                InputDecoration(labelText: t.stockLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                InputDecoration(labelText: t.unitPriceLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<RequisitionDepartment>(
                      initialValue: department,
                      decoration: InputDecoration(labelText: t.departmentLabel),
                      items: RequisitionDepartment.values
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text(_departmentLabel(t, d))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => department = v ?? department),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate:
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => requiredDeliveryDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration:
                            InputDecoration(labelText: t.requiredDeliveryLabel),
                        child: Text(
                          requiredDeliveryDate == null
                              ? '—'
                              : DateFormat.yMMMd(
                                      Localizations.localeOf(sheetContext)
                                          .languageCode)
                                  .format(requiredDeliveryDate!),
                        ),
                      ),
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
                    const SizedBox(height: 14),
                    Text(t.priorityLabel,
                        style: Theme.of(sheetContext).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<RequisitionPriority>(
                      segments: [
                        ButtonSegment(
                            value: RequisitionPriority.low,
                            label: Text(t.priorityLow)),
                        ButtonSegment(
                            value: RequisitionPriority.normal,
                            label: Text(t.priorityNormal)),
                        ButtonSegment(
                            value: RequisitionPriority.urgent,
                            label: Text(t.priorityUrgent)),
                      ],
                      selected: {priority},
                      onSelectionChanged: (s) =>
                          setState(() => priority = s.first),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final qty = double.tryParse(qtyController.text);
                          if (itemController.text.trim().isEmpty ||
                              qty == null) {
                            return;
                          }
                          context.read<TankDataProvider>().addRequisition(
                                vesselId: vessel.id,
                                vesselName: vessel.name,
                                itemName: itemController.text.trim(),
                                partNumber: partNumberController.text.trim(),
                                oemManufacturer: oemController.text.trim(),
                                quantity: qty,
                                quantityInStock:
                                    double.tryParse(stockController.text) ?? 0,
                                unit: unitController.text.trim().isEmpty
                                    ? 'pcs'
                                    : unitController.text.trim(),
                                unitPrice:
                                    double.tryParse(priceController.text) ?? 0,
                                department: department,
                                priority: priority,
                                requiredDeliveryDate: requiredDeliveryDate,
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

  static String _str(Map<String, dynamic>? m, String key) {
    final v = m?[key];
    return v == null ? '' : v.toString();
  }

  static String _strOr(Map<String, dynamic>? m, String key, String fallback) {
    final s = _str(m, key);
    return s.isEmpty ? fallback : s;
  }

  static String _numStr(Map<String, dynamic>? m, String key, String fallback) {
    final v = m?[key];
    if (v is num) {
      return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    }
    return fallback;
  }

  static T _enumFrom<T extends Enum>(List<T> values, String name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  /// AI-assisted entry: pick a file, upload it, ask the `extract` function to
  /// read it, then open the add sheet pre-filled with the result for review.
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final picked = await pickAttachment();
    if (picked == null) return;
    if (!picked.isCloud) {
      messenger.showSnackBar(SnackBar(content: Text(t.extractionFailed)));
      return;
    }
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExtractingDialog(message: t.extractingFile),
    );

    try {
      final data = await ExtractionService.extract(
          storagePath: picked.storagePath!, kind: 'requisition');
      navigator.pop();
      if (!context.mounted) return;
      _showAddRequisitionSheet(context, t,
          prefill: data, initialAttachments: [picked]);
    } on ExtractionException catch (e) {
      navigator.pop();
      final msg = e.code == 'not_configured'
          ? t.extractionNotConfigured
          : t.extractionFailed;
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

/// Small modal shown while the AI reads an uploaded file.
class _ExtractingDialog extends StatelessWidget {
  final String message;
  const _ExtractingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Expanded(child: Text(message)),
        ],
      ),
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
