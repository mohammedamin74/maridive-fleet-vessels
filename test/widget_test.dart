// Model serialization round-trips. These guard the contract that matters
// most across cloud sync AND AI extraction: `fromMap` must accept exactly
// the key names `toMap` writes — the same key names the AI extraction
// schemas (supabase/functions/extract KINDS registry) are built around.
import 'package:flutter_test/flutter_test.dart';

import 'package:maridive_fleet_vessels/models/crew_member.dart';
import 'package:maridive_fleet_vessels/models/daily_task.dart';
import 'package:maridive_fleet_vessels/models/defect.dart';
import 'package:maridive_fleet_vessels/models/handover_report.dart';
import 'package:maridive_fleet_vessels/models/maintenance_record.dart';
import 'package:maridive_fleet_vessels/models/port_call.dart';
import 'package:maridive_fleet_vessels/models/port_requirement.dart';
import 'package:maridive_fleet_vessels/models/requisition.dart';
import 'package:maridive_fleet_vessels/models/tank_reading.dart';
import 'package:maridive_fleet_vessels/models/urgent_notification.dart';
import 'package:maridive_fleet_vessels/models/vessel_certificate.dart';
import 'package:maridive_fleet_vessels/models/vessel_note.dart';

void main() {
  final when = DateTime.utc(2026, 7, 15, 12);

  test('TankReading round-trips through toMap/fromMap', () {
    final r = TankReading(
      vesselId: 'v1',
      tankId: 't1',
      levelM3: 12.5,
      temperatureC: 31.0,
      timestamp: when,
    );
    final back = TankReading.fromMap(r.toMap());
    expect(back.tankId, 't1');
    expect(back.levelM3, 12.5);
    expect(back.temperatureC, 31.0);
    expect(back.timestamp, when);
  });

  test('VesselNote round-trips', () {
    final n = VesselNote(id: 'n1', vesselId: 'v1', text: 'ETA 06:00', timestamp: when);
    final back = VesselNote.fromMap(n.toMap());
    expect(back.text, 'ETA 06:00');
    expect(back.timestamp, when);
  });

  test('MaintenanceRecord round-trips including status enum', () {
    final m = MaintenanceRecord(
      id: 'm1',
      vesselId: 'v1',
      title: 'ME LO purifier overhaul',
      description: 'Renew bowl seals',
      performedBy: '2/E',
      dueDate: when,
      status: MaintenanceStatus.inProgress,
      attachments: const [],
      createdAt: when,
    );
    final back = MaintenanceRecord.fromMap(m.toMap());
    expect(back.status, MaintenanceStatus.inProgress);
    expect(back.title, 'ME LO purifier overhaul');
  });

  test('PortCall round-trips including checklist and bunkers', () {
    final p = PortCall(
      id: 'p1',
      vesselId: 'v1',
      portName: 'Alexandria',
      arrivalEta: when,
      agentName: 'Agent Co',
      agentContact: '+20 100 000 0000',
      bunkersMgoRequired: 50,
      bunkersHfoRequired: 0,
      freshWaterRequired: 20,
      provisionsRequired: 'Fresh vegetables',
      sludgeDisposalRequired: true,
      sludgeQuantity: 3.5,
      customsChecklist: const [],
      status: PortCallStatus.upcoming,
      createdAt: when,
    );
    final back = PortCall.fromMap(p.toMap());
    expect(back.portName, 'Alexandria');
    expect(back.sludgeDisposalRequired, true);
    expect(back.bunkersMgoRequired, 50);
  });

  test('PortRequirement round-trips including category enum', () {
    final r = PortRequirement(
      id: 'r1',
      vesselId: 'v1',
      title: 'Crew List',
      portName: 'Damietta',
      category: RequirementCategory.customs,
      createdAt: when,
    );
    final back = PortRequirement.fromMap(r.toMap());
    expect(back.category, RequirementCategory.customs);
    expect(back.portName, 'Damietta');
  });

  test('VesselCertificate round-trips and computes reminder status', () {
    final c = VesselCertificate(
      id: 'c1',
      vesselId: 'v1',
      documentName: 'Safety Equipment Certificate',
      issuingAuthority: 'Class NK',
      issueDate: DateTime.utc(2025, 1, 1),
      expiryDate: DateTime.now().add(const Duration(days: 10)),
    );
    final back = VesselCertificate.fromMap(c.toMap());
    expect(back.documentName, 'Safety Equipment Certificate');
    expect(back.reminderStatus, CertReminderStatus.red);
  });

  test('CrewMember round-trips; sign-off preserved', () {
    final m = CrewMember(
      id: 'cm1',
      vesselId: 'v1',
      name: 'A. Hassan',
      rank: 'Chief Officer',
      nationality: 'Egyptian',
      status: CrewStatus.previous,
      signOnDate: DateTime.utc(2026, 1, 10),
      signOffDate: when,
      createdAt: when,
    );
    final back = CrewMember.fromMap(m.toMap());
    expect(back.status, CrewStatus.previous);
    expect(back.signOffDate, when);
  });

  test('DailyTask round-trips; overdue derived not stored', () {
    final t = DailyTask(
      id: 'd1',
      vesselId: 'v1',
      category: TaskCategory.safetyEquipmentChecks,
      title: 'Check lifeboat engine',
      assignedTo: '3/O',
      frequency: TaskFrequency.weekly,
      scheduledTime: DateTime.now().subtract(const Duration(hours: 2)),
      status: TaskStatus.pending,
      checklistItems: const [],
      attachments: const [],
      createdAt: when,
    );
    final back = DailyTask.fromMap(t.toMap());
    expect(back.category, TaskCategory.safetyEquipmentChecks);
    expect(back.isOverdue, true);
  });

  test('UrgentNotification round-trips including action fields', () {
    final n = UrgentNotification(
      id: 'u1',
      vesselId: 'v1',
      alertType: AlertType.engineFailure,
      location: 'Engine room',
      description: 'ME turbocharger surge',
      timestamp: when,
      escalationStatus: EscalationStatus.acknowledged,
      isAction: true,
      assignee: 'C/E',
      actionStatus: ActionStatus.inProgress,
      dueDate: when.add(const Duration(days: 2)),
    );
    final back = UrgentNotification.fromMap(n.toMap());
    expect(back.alertType, AlertType.engineFailure);
    expect(back.isAction, true);
    expect(back.actionStatus, ActionStatus.inProgress);
  });

  test('Defect and Requisition models expose the AI extraction field names',
      () {
    // The extract edge function's schemas promise these exact keys; if a
    // rename ever happens on the Dart side this test flags the drift.
    final defectMap = Defect.fromMap(const {
      'id': 'x',
      'vesselId': 'v1',
      'title': 'Bilge pump fault',
      'description': 'No suction',
      'location': 'engineRoom',
      'priority': 'high',
      'assignedOfficer': '2/E',
      'requiredSpareParts': 'Mechanical seal',
      'status': 'open',
      'reportedAt': '2026-07-15T12:00:00Z',
    }).toMap();
    expect(defectMap['location'], 'engineRoom');
    expect(defectMap['priority'], 'high');

    final reqMap = Requisition.fromMap(const {
      'id': 'x',
      'vesselId': 'v1',
      'itemName': 'Impeller',
      'partNumber': '337178001',
      'quantity': 2,
      'unit': 'PC',
      'department': 'engine',
      'priority': 'normal',
      'status': 'pending',
      'requestedAt': '2026-07-15T12:00:00Z',
    }).toMap();
    expect(reqMap['itemName'], 'Impeller');
    expect(reqMap['partNumber'], '337178001');
  });

  test('HandoverReport round-trips through map with AI field names', () {
    final map = HandoverReport.fromMap(const {
      'id': 'x',
      'vesselId': 'v1',
      'outgoingOfficer': 'C/O Ahmed',
      'incomingOfficer': 'C/O Karim',
      'rank': 'Chief Officer',
      'handoverDate': '2026-07-16T08:00:00Z',
      'safety': 'All LSA/FFA in order.',
      'machinery': 'ME normal. DG2 on standby.',
      'pendingDefects': '- Bilge pump fault (high)',
      'bunkersAndTanks': '- FO 1P: 120.0 / 200.0 m3 (60%)',
      'certificatesExpiring': '- Safe Manning: 2026-09-01',
      'remarks': 'Port call Benghazi on 20th.',
      'status': 'issued',
      'acknowledgedBy': '',
      'createdAt': '2026-07-16T07:00:00Z',
    }).toMap();
    expect(map['outgoingOfficer'], 'C/O Ahmed');
    expect(map['incomingOfficer'], 'C/O Karim');
    expect(map['status'], 'issued');
    expect(map['pendingDefects'], contains('Bilge pump'));

    // Status defaults to draft for records missing it (older writes).
    final draft = HandoverReport.fromMap(const {
      'id': 'y',
      'vesselId': 'v1',
      'handoverDate': '2026-07-16T08:00:00Z',
      'createdAt': '2026-07-16T07:00:00Z',
    });
    expect(draft.status, HandoverStatus.draft);
    expect(draft.attachments, isEmpty);
  });
}
