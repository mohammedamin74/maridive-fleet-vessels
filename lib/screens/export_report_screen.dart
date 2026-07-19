import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/crew_certificate.dart';
import '../models/crew_member.dart';
import '../models/defect.dart';
import '../models/port_requirement.dart';
import '../models/requisition.dart';
import '../models/tank.dart';
import '../models/vessel.dart';
import '../models/vessel_certificate.dart';
import '../services/report_service.dart';
import '../state/certification_provider.dart';
import '../state/crew_provider.dart';
import '../state/daily_tasks_provider.dart';
import '../state/port_call_provider.dart';
import '../state/port_requirement_provider.dart';
import '../state/tank_data_provider.dart';
import 'port_requirements_screen.dart' show requirementCategoryLabel;
import 'report_preview_screen.dart';

/// One selectable module in the unified export (Request 7).
enum ExportModule {
  tanks,
  defects,
  requisitions,
  portCalls,
  portRequirements,
  crew,
  dailyTasks,
  certificates,
}

enum ExportFormat { pdf, csv }

class ExportReportScreen extends StatefulWidget {
  final Vessel vessel;
  const ExportReportScreen({super.key, required this.vessel});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  final Set<ExportModule> _selected = {...ExportModule.values};
  ExportFormat _format = ExportFormat.pdf;
  bool _busy = false;

  Vessel get vessel => widget.vessel;

  String _moduleLabel(AppLocalizations t, ExportModule m) {
    switch (m) {
      case ExportModule.tanks:
        return t.tankSystems;
      case ExportModule.defects:
        return t.defects;
      case ExportModule.requisitions:
        return t.requisitions;
      case ExportModule.portCalls:
        return t.portCalls;
      case ExportModule.portRequirements:
        return t.portRequirements;
      case ExportModule.crew:
        return t.crew;
      case ExportModule.dailyTasks:
        return t.dailyTasks;
      case ExportModule.certificates:
        return t.certification;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('${t.exportReport} — ${vessel.name}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.selectSections,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...ExportModule.values.map((m) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _selected.contains(m),
                title: Text(_moduleLabel(t, m)),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(m);
                  } else {
                    _selected.remove(m);
                  }
                }),
              )),
          const SizedBox(height: 12),
          Text(t.exportFormat,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ExportFormat>(
            segments: [
              ButtonSegment(
                  value: ExportFormat.pdf, label: Text(t.exportFormatPdf)),
              ButtonSegment(
                  value: ExportFormat.csv, label: Text(t.exportFormatCsv)),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selected.isEmpty || _busy ? null : () => _review(),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(t.reviewReport),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty || _busy ? null : () => _generate(t),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download_outlined),
                  label: Text(t.generateReport),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _review() {
    final t = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReportPreviewScreen(vessel: vessel, sections: _buildSections(t)),
      ),
    );
  }

  Future<void> _generate(AppLocalizations t) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sections = _buildSections(t);
      if (_format == ExportFormat.pdf) {
        await ReportService.exportUnifiedPdf(
            vessel: vessel, sections: sections);
      } else {
        await ReportService.exportUnifiedCsv(
            vessel: vessel, sections: sections);
      }
      messenger.showSnackBar(SnackBar(content: Text(t.fileSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.downloadFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<ReportSection> _buildSections(AppLocalizations t) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(locale);
    final tankData = context.read<TankDataProvider>();
    final sections = <ReportSection>[];

    String qty(double q) =>
        q.toStringAsFixed(q == q.roundToDouble() ? 0 : 1);
    String files(int n) => n == 0 ? '—' : '$n';

    if (_selected.contains(ExportModule.tanks)) {
      sections.add(ReportSection(
        t.tankSystems,
        [t.tankLabel, t.categoryLabel, 'm³', '${t.capacity} m³', t.levelLabel],
        vessel.tanks.map((tank) {
          final current = tankData.currentLevel(vessel.id, tank.id);
          final percent = tankData.percentFor(vessel.id, tank);
          return [
            tank.name,
            _tankCategoryLabel(t, tank.category),
            qty(current),
            qty(tank.capacityM3),
            '${(percent * 100).round()}%',
          ];
        }).toList(),
      ));
    }

    if (_selected.contains(ExportModule.defects)) {
      sections.add(ReportSection(
        t.defects,
        [t.defectTitleLabel, t.locationLabel, t.priorityLabel, t.status, t.reportedOn, t.attachmentsLabel],
        tankData.defectsFor(vessel.id).map((d) {
          return [
            d.title,
            _defectLocation(t, d.location),
            _defectPriority(t, d.priority),
            _defectStatus(t, d.status),
            dateFmt.format(d.reportedAt),
            files(d.attachments.length),
          ];
        }).toList(),
      ));
    }

    if (_selected.contains(ExportModule.requisitions)) {
      sections.add(ReportSection(
        t.requisitions,
        [t.itemNameLabel, t.quantityLabel, t.unitLabel, t.departmentLabel, t.priorityLabel, t.status],
        tankData.requisitionsFor(vessel.id).map((r) {
          return [
            r.itemName,
            qty(r.quantity),
            r.unit,
            _department(t, r.department),
            _reqPriority(t, r.priority),
            _reqStatus(t, r.status),
          ];
        }).toList(),
      ));
    }

    if (_selected.contains(ExportModule.portCalls)) {
      sections.add(ReportSection(
        t.portCalls,
        [t.portNameLabel, t.arrivalEtaLabel, t.status],
        context.read<PortCallProvider>().forVessel(vessel.id).map((p) {
          return [
            p.portName,
            dateFmt.format(p.arrivalEta),
            p.status.name,
          ];
        }).toList(),
      ));
    }

    if (_selected.contains(ExportModule.portRequirements)) {
      sections.add(ReportSection(
        t.portRequirements,
        [t.requirementTitleLabel, t.reqCategoryLabel, t.portNameLabel, t.status, t.attachmentsLabel],
        context.read<PortRequirementProvider>().forVessel(vessel.id).map((r) {
          return [
            r.title,
            requirementCategoryLabel(t, r.category),
            r.portName,
            r.status == RequirementStatus.ready
                ? t.reqStatusReady
                : t.reqStatusPendingLabel,
            files(r.attachments.length),
          ];
        }).toList(),
      ));
    }

    if (_selected.contains(ExportModule.crew)) {
      final crew = context.read<CrewProvider>();
      final members = [
        ...crew.current(vessel.id),
        ...crew.previous(vessel.id),
      ];
      sections.add(ReportSection(
        t.crew,
        [t.crewNameLabel, t.rankLabel, t.nationalityLabel, t.status, t.signOnDateLabel, t.signOffDateLabel],
        members.map((m) {
          return [
            m.name,
            m.rank,
            m.nationality,
            m.status == CrewStatus.current ? t.currentCrew : t.previousCrew,
            dateFmt.format(m.signOnDate),
            m.signOffDate != null ? dateFmt.format(m.signOffDate!) : '—',
          ];
        }).toList(),
      ));
    }

    if (_selected.contains(ExportModule.dailyTasks)) {
      sections.add(ReportSection(
        t.dailyTasks,
        [t.taskTitleLabel, t.taskCategoryLabel, t.status],
        context.read<DailyTasksProvider>().forVessel(vessel.id).map((task) {
          return [
            task.title,
            task.category.name,
            task.isOverdue ? t.taskStatusOverdue : task.status.name,
          ];
        }).toList(),
      ));
    }

    if (_selected.contains(ExportModule.certificates)) {
      final certs = context.read<CertificationProvider>();
      sections.add(ReportSection(
        t.vesselCerts,
        [t.documentNameLabel, t.issuingAuthorityLabel, t.issueDateLabel, t.expiryDateLabel, t.status],
        certs.vesselCertsFor(vessel.id).map((c) {
          return [
            c.documentName,
            c.issuingAuthority,
            dateFmt.format(c.issueDate),
            dateFmt.format(c.expiryDate),
            c.reminderStatus == CertReminderStatus.expired
                ? t.certExpired
                : t.certStatusValid,
          ];
        }).toList(),
      ));
      sections.add(ReportSection(
        t.crewCerts,
        [t.officerNameLabel, t.rankLabel, t.certTypeLabel, t.issueDateLabel, t.expiryDateLabel, t.status],
        certs.crewCertsFor(vessel.id).map((c) {
          return [
            c.officerName,
            c.rank,
            _certType(t, c.certType),
            dateFmt.format(c.issueDate),
            dateFmt.format(c.expiryDate),
            c.reminderStatus == CertReminderStatus.expired
                ? t.certExpired
                : t.certStatusValid,
          ];
        }).toList(),
      ));
    }

    return sections;
  }

  // --- localized enum labels ---

  String _certType(AppLocalizations t, CrewCertType c) {
    switch (c) {
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

  String _tankCategoryLabel(AppLocalizations t, TankCategory c) {
    switch (c) {
      case TankCategory.fuelOil:
        return t.categoryFuelOil;
      case TankCategory.brineMud:
        return t.categoryBrineMud;
      case TankCategory.lubeHydraulic:
        return t.categoryLubeHydraulic;
      case TankCategory.other:
        return t.categoryOther;
    }
  }

  String _defectLocation(AppLocalizations t, DefectLocation l) {
    switch (l) {
      case DefectLocation.engineRoom:
        return t.locationEngineRoom;
      case DefectLocation.deck:
        return t.locationDeck;
      case DefectLocation.bridge:
        return t.locationBridge;
      case DefectLocation.accommodation:
        return t.locationAccommodation;
      case DefectLocation.galley:
        return t.locationGalley;
      case DefectLocation.other:
        return t.locationOther;
    }
  }

  String _defectPriority(AppLocalizations t, DefectPriority p) {
    switch (p) {
      case DefectPriority.low:
        return t.priorityLow;
      case DefectPriority.medium:
        return t.priorityMedium;
      case DefectPriority.high:
        return t.priorityHigh;
      case DefectPriority.critical:
        return t.severityCritical;
    }
  }

  String _defectStatus(AppLocalizations t, DefectStatus s) {
    switch (s) {
      case DefectStatus.open:
        return t.statusOpenDefect;
      case DefectStatus.inProgress:
        return t.statusInProgress;
      case DefectStatus.closed:
        return t.statusClosedDefect;
    }
  }

  String _department(AppLocalizations t, RequisitionDepartment d) {
    switch (d) {
      case RequisitionDepartment.engine:
        return t.departmentEngine;
      case RequisitionDepartment.deck:
        return t.departmentDeck;
      case RequisitionDepartment.steward:
        return t.departmentSteward;
    }
  }

  String _reqPriority(AppLocalizations t, RequisitionPriority p) {
    switch (p) {
      case RequisitionPriority.low:
        return t.priorityLow;
      case RequisitionPriority.normal:
        return t.priorityNormal;
      case RequisitionPriority.urgent:
        return t.priorityUrgent;
    }
  }

  String _reqStatus(AppLocalizations t, RequisitionStatus s) {
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
}
