import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/defect.dart';
import '../models/vessel.dart';
import '../state/tank_data_provider.dart';
import '../theme/app_colors.dart';

class DefectListScreen extends StatelessWidget {
  final Vessel vessel;
  const DefectListScreen({super.key, required this.vessel});

  Color _severityColor(DefectSeverity s) {
    switch (s) {
      case DefectSeverity.minor:
        return AppColors.statusPort;
      case DefectSeverity.major:
        return AppColors.amber400;
      case DefectSeverity.critical:
        return AppColors.statusMaintenance;
    }
  }

  String _severityLabel(AppLocalizations t, DefectSeverity s) {
    switch (s) {
      case DefectSeverity.minor:
        return t.severityMinor;
      case DefectSeverity.major:
        return t.severityMajor;
      case DefectSeverity.critical:
        return t.severityCritical;
    }
  }

  String _statusLabel(AppLocalizations t, DefectStatus s) {
    switch (s) {
      case DefectStatus.open:
        return t.statusOpenDefect;
      case DefectStatus.inProgress:
        return t.statusInProgress;
      case DefectStatus.closed:
        return t.statusClosedDefect;
    }
  }

  Color _statusColor(DefectStatus s) {
    switch (s) {
      case DefectStatus.open:
        return AppColors.statusMaintenance;
      case DefectStatus.inProgress:
        return AppColors.amber400;
      case DefectStatus.closed:
        return AppColors.statusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final data = context.watch<TankDataProvider>();
    final defects = data.defectsFor(vessel.id);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.defects} — ${vessel.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDefectSheet(context, t),
          ),
        ],
      ),
      body: defects.isEmpty
          ? Center(child: Text(t.noDefects, style: Theme.of(context).textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: defects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final defect = defects[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showDefectDetailSheet(context, t, defect),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(defect.title, style: Theme.of(context).textTheme.titleMedium),
                              ),
                              _Chip(label: _severityLabel(t, defect.severity), color: _severityColor(defect.severity)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Chip(label: _statusLabel(t, defect.status), color: _statusColor(defect.status)),
                              const Spacer(),
                              Text(
                                '${t.reportedOn}: ${dateFmt.format(defect.reportedAt)}',
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

  void _showDefectDetailSheet(BuildContext context, AppLocalizations t, Defect defect) {
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
              Text(defect.title, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(defect.description, style: Theme.of(sheetContext).textTheme.bodyLarge),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (defect.status != DefectStatus.inProgress)
                    OutlinedButton(
                      onPressed: () {
                        data.updateDefectStatus(defect.id, DefectStatus.inProgress);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.markInProgress),
                    ),
                  if (defect.status != DefectStatus.closed)
                    OutlinedButton(
                      onPressed: () {
                        data.updateDefectStatus(defect.id, DefectStatus.closed);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.markClosed),
                    ),
                  if (defect.status == DefectStatus.closed)
                    OutlinedButton(
                      onPressed: () {
                        data.updateDefectStatus(defect.id, DefectStatus.open);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.reopen),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      data.deleteDefect(defect.id);
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

  void _showAddDefectSheet(BuildContext context, AppLocalizations t) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DefectSeverity severity = DefectSeverity.minor;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.addDefect, style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: t.defectTitleLabel),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: t.defectDescriptionLabel),
                  ),
                  const SizedBox(height: 14),
                  Text(t.severityLabel, style: Theme.of(sheetContext).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<DefectSeverity>(
                    segments: [
                      ButtonSegment(value: DefectSeverity.minor, label: Text(t.severityMinor)),
                      ButtonSegment(value: DefectSeverity.major, label: Text(t.severityMajor)),
                      ButtonSegment(value: DefectSeverity.critical, label: Text(t.severityCritical)),
                    ],
                    selected: {severity},
                    onSelectionChanged: (s) => setState(() => severity = s.first),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        context.read<TankDataProvider>().addDefect(
                              vesselId: vessel.id,
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              severity: severity,
                            );
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(t.save),
                    ),
                  ),
                ],
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
