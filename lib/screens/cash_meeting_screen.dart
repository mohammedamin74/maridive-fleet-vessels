import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/fleet_data.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../models/cash_item.dart';
import '../state/cash_meeting_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/ai_fill.dart';
import '../widgets/confirm_delete.dart';

/// The cash meeting sheet, digitized from the office's Excel: a rolling
/// ledger of purchase lines (PR + PO) per vessel, split into "not approved"
/// and "approved" — the app's version of the workbook's two tabs. Amounts
/// are subtotaled per currency and never summed across currencies.
class CashMeetingScreen extends StatefulWidget {
  const CashMeetingScreen({super.key});

  @override
  State<CashMeetingScreen> createState() => _CashMeetingScreenState();
}

class _CashMeetingScreenState extends State<CashMeetingScreen> {
  String? _vesselFilter;

  static final _money = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.watch<CashMeetingProvider>();
    final vessels = FleetData.vessels;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.cashMeetingTitle),
          actions: [
            AiFillAction(onPressed: () => _extractFromFile(context, t)),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: t.cashItemAdd,
              onPressed: () => _showItemSheet(context, t),
            ),
          ],
          bottom: TabBar(tabs: [
            Tab(text: t.cashPendingTab),
            Tab(text: t.cashApprovedTab),
          ]),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.lg, top: AppSpacing.sm),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(t.allVesselsFilter),
                          selected: _vesselFilter == null,
                          onSelected: (_) =>
                              setState(() => _vesselFilter = null),
                        ),
                      ),
                      for (final v in vessels)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                              end: AppSpacing.xs),
                          child: ChoiceChip(
                            label: Text(_shortName(v.name)),
                            selected: _vesselFilter == v.id,
                            onSelected: (_) =>
                                setState(() => _vesselFilter = v.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(children: [
                  _ItemsList(
                    items: provider.byStatus(CashItemStatus.pending,
                        vesselId: _vesselFilter),
                    subtotals: provider.subtotals,
                    money: _money,
                    onEdit: (item) => _showItemSheet(context, t, existing: item),
                    onToggle: (item) => provider.setStatus(
                        item.id, CashItemStatus.approved),
                    onDelete: (item) => _confirmDelete(context, item),
                    toggleLabel: t.markApproved,
                    toggleIcon: Icons.check_circle_outline,
                  ),
                  _ItemsList(
                    items: provider.byStatus(CashItemStatus.approved,
                        vesselId: _vesselFilter),
                    subtotals: provider.subtotals,
                    money: _money,
                    onEdit: (item) => _showItemSheet(context, t, existing: item),
                    onToggle: (item) =>
                        provider.setStatus(item.id, CashItemStatus.pending),
                    onDelete: (item) => _confirmDelete(context, item),
                    toggleLabel: t.markPending,
                    toggleIcon: Icons.undo,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortName(String name) =>
      name.replaceFirst('Maridive ', '');

  Future<void> _confirmDelete(BuildContext context, CashItem item) async {
    final ok = await confirmDelete(context,
        itemName: item.description.isEmpty ? item.poNumber : item.description);
    if (!ok || !context.mounted) return;
    await context.read<CashMeetingProvider>().delete(item.id);
  }

  /// AI scan of a meeting sheet / PR stack: every extracted row is reviewed
  /// one by one in the normal add sheet before anything is saved (same
  /// row-per-item flow as the Defects module).
  Future<void> _extractFromFile(BuildContext context, AppLocalizations t) async {
    final outcome = await pickAndExtract(context, t, kind: 'cash_item');
    if (outcome == null) return;
    final items = outcome.result.items ?? [];
    for (var i = 0; i < items.length; i++) {
      if (!context.mounted) return;
      await _showItemSheet(
        context,
        t,
        prefill: items[i],
        initialAttachments: [outcome.file],
        progressLabel: items.length > 1 ? '(${i + 1}/${items.length})' : null,
      );
    }
  }

  /// Maps an extracted vessel string ("ZOHR I", "MD601"...) onto a fleet
  /// vessel id; falls back to the current filter, then the first vessel.
  String _guessVesselId(String? raw) {
    final v = (raw ?? '').toLowerCase().replaceAll(' ', '');
    if (v.contains('zohr')) {
      return v.contains('ii') || v.contains('2') ? 'mrd-zohr-2' : 'mrd-zohr-1';
    }
    if (v.contains('601')) return 'mrd-601';
    if (v.contains('704')) return 'mrd-704';
    if (v.contains('701') || v.contains('7')) return 'mrd-701';
    return _vesselFilter ?? FleetData.vessels.first.id;
  }

  Future<void> _showItemSheet(
    BuildContext context,
    AppLocalizations t, {
    CashItem? existing,
    Map<String, dynamic>? prefill,
    List<Attachment> initialAttachments = const [],
    String? progressLabel,
  }) {
    final provider = context.read<CashMeetingProvider>();
    var vesselId = existing?.vesselId ??
        _guessVesselId(prefill == null ? _vesselFilter : aiStr(prefill, 'vessel'));
    if (FleetData.vessels.every((v) => v.id != vesselId)) {
      vesselId = FleetData.vessels.first.id;
    }
    var currency = existing?.currency ??
        (prefill != null
            ? parseCashCurrency(aiStr(prefill, 'currency'))
            : CashCurrency.eur);
    final operationController = TextEditingController(
        text: existing?.operation ??
            aiStrOr(prefill, 'operation', 'Operations'));
    final descriptionController = TextEditingController(
        text: existing?.description ?? aiStr(prefill, 'description'));
    final prController = TextEditingController(
        text: existing?.prNumber ?? aiStr(prefill, 'prNumber'));
    final costController = TextEditingController(
        text: existing != null
            ? existing.cost.toString()
            : aiNumStr(prefill, 'cost', ''));
    final supplierController = TextEditingController(
        text: existing?.supplier ?? aiStr(prefill, 'supplier'));
    final poController = TextEditingController(
        text: existing?.poNumber ?? aiStr(prefill, 'poNumber'));
    final notesController = TextEditingController(text: existing?.notes ?? '');

    final title = [
      existing != null
          ? t.cashItemEdit
          : prefill != null
              ? t.cashItemReviewExtracted
              : t.cashItemAdd,
      if (progressLabel != null) progressLabel,
    ].join(' ');

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom:
                  MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(sheetContext).textTheme.titleLarge),
                  Gaps.h16,
                  DropdownButtonFormField<String>(
                    initialValue: vesselId,
                    decoration: InputDecoration(labelText: t.vesselLabel),
                    items: [
                      for (final v in FleetData.vessels)
                        DropdownMenuItem(
                            value: v.id, child: Text(_shortName(v.name))),
                    ],
                    onChanged: (v) => setSheet(() => vesselId = v ?? vesselId),
                  ),
                  Gaps.h12,
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration:
                        InputDecoration(labelText: t.requestDescriptionLabel),
                  ),
                  Gaps.h12,
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(labelText: t.costLabel),
                      ),
                    ),
                    Gaps.w12,
                    Expanded(
                      child: DropdownButtonFormField<CashCurrency>(
                        initialValue: currency,
                        decoration:
                            InputDecoration(labelText: t.currencyLabel),
                        items: [
                          for (final c in CashCurrency.values)
                            DropdownMenuItem(
                                value: c, child: Text(c.label)),
                        ],
                        onChanged: (c) =>
                            setSheet(() => currency = c ?? currency),
                      ),
                    ),
                  ]),
                  Gaps.h12,
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: prController,
                        decoration:
                            InputDecoration(labelText: t.prNumberLabel),
                      ),
                    ),
                    Gaps.w12,
                    Expanded(
                      child: TextField(
                        controller: poController,
                        decoration:
                            InputDecoration(labelText: t.poNumberLabel),
                      ),
                    ),
                  ]),
                  Gaps.h12,
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: supplierController,
                        decoration:
                            InputDecoration(labelText: t.supplierLabel),
                      ),
                    ),
                    Gaps.w12,
                    Expanded(
                      child: TextField(
                        controller: operationController,
                        decoration:
                            InputDecoration(labelText: t.operationLabel),
                      ),
                    ),
                  ]),
                  Gaps.h12,
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: t.notesLabel),
                  ),
                  Gaps.h16,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final cost = double.tryParse(costController.text
                                .replaceAll(',', '.')
                                .replaceAll(' ', '')) ??
                            0;
                        if (existing != null) {
                          await provider.update(
                            id: existing.id,
                            vesselId: vesselId,
                            operation: operationController.text.trim(),
                            description: descriptionController.text.trim(),
                            prNumber: prController.text.trim(),
                            cost: cost,
                            currency: currency,
                            supplier: supplierController.text.trim(),
                            poNumber: poController.text.trim(),
                            notes: notesController.text.trim(),
                          );
                        } else {
                          await provider.add(
                            vesselId: vesselId,
                            operation: operationController.text.trim(),
                            description: descriptionController.text.trim(),
                            prNumber: prController.text.trim(),
                            cost: cost,
                            currency: currency,
                            supplier: supplierController.text.trim(),
                            poNumber: poController.text.trim(),
                            notes: notesController.text.trim(),
                            attachments: initialAttachments,
                          );
                        }
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: Text(t.save),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class _ItemsList extends StatelessWidget {
  final List<CashItem> items;
  final Map<CashCurrency, double> Function(List<CashItem>) subtotals;
  final NumberFormat money;
  final void Function(CashItem) onEdit;
  final void Function(CashItem) onToggle;
  final void Function(CashItem) onDelete;
  final String toggleLabel;
  final IconData toggleIcon;

  const _ItemsList({
    required this.items,
    required this.subtotals,
    required this.money,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.toggleLabel,
    required this.toggleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(t.cashNoItems,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    final totals = subtotals(items);
    final vesselNames = {
      for (final v in FleetData.vessels)
        v.id: v.name.replaceFirst('Maridive ', '')
    };
    final dateFmt = DateFormat('yyyy-MM-dd');

    return LayoutBuilder(builder: (context, constraints) {
      final gutter = AppBreakpoints.pageGutter(constraints.maxWidth);
      return ListView(
        padding: gutter.add(const EdgeInsetsDirectional.only(
            top: AppSpacing.sm, bottom: AppSpacing.xxl)),
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${t.totalsLabel}: ',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              for (final e in totals.entries)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${e.key.label} ${money.format(e.value)}'),
                ),
            ],
          ),
          Gaps.h8,
          for (final item in items)
            Card(
              child: ListTile(
                onTap: () => onEdit(item),
                title: Text(item.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    vesselNames[item.vesselId] ?? item.vesselId,
                    if (item.supplier.isNotEmpty) item.supplier,
                    if (item.poNumber.isNotEmpty) 'PO ${item.poNumber}',
                    if (item.status == CashItemStatus.approved &&
                        item.decidedAt != null)
                      t.approvedOn(dateFmt.format(item.decidedAt!)),
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.currency.label} ${money.format(item.cost)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'toggle':
                            onToggle(item);
                          case 'edit':
                            onEdit(item);
                          case 'delete':
                            onDelete(item);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(toggleIcon,
                                color: AppColors.teal500),
                            title: Text(toggleLabel),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(t.cashItemEdit),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.delete_outline,
                                color: AppColors.statusMaintenance),
                            title: Text(t.delete),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}
