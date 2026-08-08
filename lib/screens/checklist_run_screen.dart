import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/checklist_run.dart';
import '../models/checklist_template.dart';
import '../models/vessel.dart';
import '../state/auth_provider.dart';
import '../state/checklist_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'checklist_report_screen.dart';

/// One month's sheet for one controlled form.
///
/// Deliberately a list rather than the spreadsheet's grid: 31 day-columns are
/// unusable on a laptop and impossible on a phone, and these get filled in on
/// a moving vessel. Each item shows its slots as tappable chips; the PDF
/// export renders the full printed grid for the office.
class ChecklistRunScreen extends StatelessWidget {
  final Vessel vessel;
  final ChecklistTemplate template;
  final String runId;

  const ChecklistRunScreen({
    super.key,
    required this.vessel,
    required this.template,
    required this.runId,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';
    final provider = context.watch<ChecklistProvider>();
    final run = provider.forVessel(vessel.id).where((r) => r.id == runId);
    if (run.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final sheet = run.first;
    final slots = template.slotCount(sheet.year, sheet.month);
    final (done, total) = sheet.progress(template.items.length, slots);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? template.titleAr : template.titleEn),
        actions: [
          // Review first, download from there: the office signs off on what
          // it can read on screen, not on a file it has to open blind.
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: t.reviewReport,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChecklistReportScreen(
                  vessel: vessel, template: template, runId: runId),
            )),
          ),
          IconButton(
            icon: Icon(sheet.isSubmitted
                ? Icons.lock_open_outlined
                : Icons.verified_outlined),
            tooltip: sheet.isSubmitted ? t.checklistReopen : t.checklistSubmit,
            onPressed: () => sheet.isSubmitted
                ? provider.reopen(sheet.id)
                : _signOff(context, t, sheet),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _SheetHeader(
              vessel: vessel,
              template: template,
              sheet: sheet,
              done: done,
              total: total,
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: template.items.length,
                itemBuilder: (context, i) => _ItemRow(
                  item: template.items[i],
                  template: template,
                  sheet: sheet,
                  slots: slots,
                  isArabic: isArabic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOff(
      BuildContext context, AppLocalizations t, ChecklistRun sheet) async {
    final provider = context.read<ChecklistProvider>();
    final user = context.read<AuthProvider>().currentUser;
    final controller = TextEditingController(
        text: sheet.chiefEngineer.isNotEmpty
            ? sheet.chiefEngineer
            : (user?.displayName ?? ''));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.checklistSignOffTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.checklistSignOffHint,
                style: Theme.of(dialogContext).textTheme.bodySmall),
            Gaps.h12,
            TextField(
              controller: controller,
              decoration:
                  InputDecoration(labelText: t.checklistChiefEngineer),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.checklistSubmit),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.submit(sheet.id, controller.text.trim());
    }
    controller.dispose();
  }

}

class _SheetHeader extends StatelessWidget {
  final Vessel vessel;
  final ChecklistTemplate template;
  final ChecklistRun sheet;
  final int done;
  final int total;

  const _SheetHeader({
    required this.vessel,
    required this.template,
    required this.sheet,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final ratio = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${vessel.name} · ${DateFormat.yMMMM(locale).format(DateTime(sheet.year, sheet.month))}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(template.code,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.slate400)),
            ],
          ),
          Gaps.h8,
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.slate200,
              color: ratio >= 1 ? AppColors.statusActive : AppColors.amber400,
            ),
          ),
          Gaps.h4,
          Row(
            children: [
              Expanded(
                child: Text(t.checklistProgress(done, total),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.slate400)),
              ),
              if (sheet.isSubmitted)
                Flexible(
                  child: Text(
                    t.checklistSubmittedOn(
                      DateFormat.yMMMd(locale).format(sheet.submittedAt!),
                      sheet.chiefEngineer,
                    ),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.statusActive),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ChecklistTemplateItem item;
  final ChecklistTemplate template;
  final ChecklistRun sheet;
  final int slots;
  final bool isArabic;

  const _ItemRow({
    required this.item,
    required this.template,
    required this.sheet,
    required this.slots,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = context.read<ChecklistProvider>();
    final remark = sheet.remarks[item.key] ?? '';
    final dates = sheet.dates[item.key] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${item.no}.',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.slate400)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isArabic ? item.ar : item.en,
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(isArabic ? item.en : item.ar,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.slate400)),
                      if (item.interval != null) ...[
                        Gaps.h4,
                        Text(
                          item.interval == ChecklistInterval.weekly
                              ? t.checklistIntervalWeekly
                              : t.checklistIntervalMonthly,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.slate400),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Gaps.h8,
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: slots,
                separatorBuilder: (_, __) => Gaps.w4,
                itemBuilder: (context, slot) => _SlotChip(
                  label: _slotLabel(t, slot),
                  result: sheet.resultFor(item.key, slot),
                  onTap: (result) => provider.setSlot(
                    runId: sheet.id,
                    itemKey: item.key,
                    slot: slot,
                    result: result,
                  ),
                ),
              ),
            ),
            if (remark.isNotEmpty) ...[
              Gaps.h4,
              Text('${t.checklistRemarks}: $remark',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            Row(
              children: [
                // The date a check was done is entered per month, exactly as
                // the engineer writes it on the paper sheet.
                TextButton.icon(
                  icon: const Icon(Icons.event_outlined, size: 15),
                  label: Text(dates.isEmpty
                      ? t.checklistColDate
                      : '${t.checklistColDate}: $dates'),
                  onPressed: () => _editText(
                    context,
                    title: t.checklistColDate,
                    current: dates,
                    hint: t.checklistDatesHint,
                    onSave: (v) => provider.setDate(sheet.id, item.key, v),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.edit_note, size: 15),
                  label: Text(t.checklistRemarks),
                  onPressed: () => _editText(
                    context,
                    title: t.checklistRemarks,
                    current: remark,
                    onSave: (v) => provider.setRemark(sheet.id, item.key, v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _slotLabel(AppLocalizations t, int slot) => switch (template.grid) {
        ChecklistGrid.yesNo => t.checklistDone,
        ChecklistGrid.weeksOfMonth => t.checklistWeekShort(slot + 1),
        ChecklistGrid.daysOfMonth => '${slot + 1}',
      };

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String current,
    String? hint,
    required Future<void> Function(String) onSave,
  }) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: current);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          minLines: 1,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (saved == true) {
      await onSave(controller.text);
    }
    controller.dispose();
  }
}

/// A single tick slot. Tapping cycles nothing — it sets "done"; long-press
/// offers N/A and failed, because those are the rare answers and a quick tap
/// should always mean the common one.
class _SlotChip extends StatelessWidget {
  final String label;
  final SlotResult result;
  final ValueChanged<SlotResult> onTap;

  const _SlotChip(
      {required this.label, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final (color, icon) = switch (result) {
      SlotResult.done => (AppColors.statusActive, Icons.check),
      SlotResult.notApplicable => (AppColors.slate400, Icons.remove),
      SlotResult.failed => (AppColors.statusExpired, Icons.priority_high),
      SlotResult.pending => (AppColors.slate400, null),
    };

    return Semantics(
      label: '$label: ${switch (result) {
        SlotResult.done => t.checklistDone,
        SlotResult.notApplicable => t.checklistNotApplicable,
        SlotResult.failed => t.checklistFailed,
        SlotResult.pending => t.checklistPending,
      }}',
      button: true,
      child: InkWell(
        onTap: () => onTap(SlotResult.done),
        onLongPress: () => _pickOther(context, t),
        borderRadius: AppRadius.smAll,
        child: Container(
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: result == SlotResult.pending
                ? Colors.transparent
                : color.withValues(alpha: 0.16),
            borderRadius: AppRadius.smAll,
            border: Border.all(
                color: result == SlotResult.pending
                    ? AppColors.slate200
                    : color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
              ],
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: result == SlotResult.pending
                          ? AppColors.slate400
                          : color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickOther(BuildContext context, AppLocalizations t) async {
    final choice = await showModalBottomSheet<SlotResult>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check, color: AppColors.statusActive),
              title: Text(t.checklistDone),
              onTap: () => Navigator.of(sheetContext).pop(SlotResult.done),
            ),
            ListTile(
              leading: const Icon(Icons.remove, color: AppColors.slate400),
              title: Text(t.checklistNotApplicable),
              onTap: () =>
                  Navigator.of(sheetContext).pop(SlotResult.notApplicable),
            ),
            ListTile(
              leading: const Icon(Icons.priority_high,
                  color: AppColors.statusExpired),
              title: Text(t.checklistFailed),
              onTap: () => Navigator.of(sheetContext).pop(SlotResult.failed),
            ),
          ],
        ),
      ),
    );
    if (choice != null) onTap(choice);
  }
}
