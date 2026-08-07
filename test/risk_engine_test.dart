// The risk engine and health score are the two pieces of the Smart Fleet
// layer a superintendent will act on, so both are pinned here against a
// fixed clock: the severity boundaries, the "critical can never hide in an
// average" cap, and the rule that an explanation always adds up to the
// points actually lost.
import 'package:flutter_test/flutter_test.dart';

import 'package:maridive_fleet_vessels/models/defect.dart';
import 'package:maridive_fleet_vessels/models/fleet_intelligence.dart';
import 'package:maridive_fleet_vessels/models/maintenance_record.dart';
import 'package:maridive_fleet_vessels/models/port_requirement.dart';
import 'package:maridive_fleet_vessels/models/requisition.dart';
import 'package:maridive_fleet_vessels/models/vessel_certificate.dart';
import 'package:maridive_fleet_vessels/services/clock.dart';
import 'package:maridive_fleet_vessels/services/risk_engine.dart';
import 'package:maridive_fleet_vessels/services/vessel_health_service.dart';

void main() {
  final fixedNow = DateTime(2026, 8, 8, 12);
  setUp(() => setClockForTesting(() => fixedNow));
  tearDown(resetClock);

  Defect defect({
    String id = 'd1',
    String title = 'Main engine leak',
    DefectPriority priority = DefectPriority.medium,
    DefectStatus status = DefectStatus.open,
    int ageDays = 1,
    String officer = 'C/E',
  }) =>
      Defect(
        id: id,
        vesselId: 'v1',
        title: title,
        description: '',
        location: DefectLocation.engineRoom,
        priority: priority,
        status: status,
        assignedOfficer: officer,
        requiredSpareParts: '',
        actionTaken: '',
        attachments: const [],
        reportedAt: fixedNow.subtract(Duration(days: ageDays)),
      );

  VesselCertificate cert(int daysLeft, {String id = 'c1'}) => VesselCertificate(
        id: id,
        vesselId: 'v1',
        documentName: 'Safety Cert',
        issuingAuthority: 'Class',
        issueDate: fixedNow.subtract(const Duration(days: 365)),
        expiryDate: fixedNow.add(Duration(days: daysLeft)),
      );

  List<RiskEvent> analyze({
    List<Defect> defects = const [],
    List<VesselCertificate> certs = const [],
    List<MaintenanceRecord> maintenance = const [],
    List<Requisition> requisitions = const [],
    List<PortRequirement> requirements = const [],
  }) =>
      RiskEngine.analyze(VesselRiskInput(
        vesselId: 'v1',
        defects: defects,
        vesselCerts: certs,
        maintenance: maintenance,
        requisitions: requisitions,
        portRequirements: requirements,
      ));

  group('defect rules', () {
    test('an open critical defect is a CRITICAL risk', () {
      final risks =
          analyze(defects: [defect(priority: DefectPriority.critical)]);
      expect(risks.single.kind, RiskKind.defectCriticalOpen);
      expect(risks.single.severity, RiskSeverity.critical);
      expect(risks.single.sourceId, 'd1');
    });

    test('a closed critical defect raises no risk', () {
      final risks = analyze(defects: [
        defect(priority: DefectPriority.critical, status: DefectStatus.closed)
      ]);
      expect(risks, isEmpty);
    });

    test('a low-priority defect only becomes a risk once it goes stale', () {
      expect(
        analyze(defects: [defect(priority: DefectPriority.low, ageDays: 29)]),
        isEmpty,
      );
      final stale =
          analyze(defects: [defect(priority: DefectPriority.low, ageDays: 30)]);
      expect(stale.single.kind, RiskKind.defectStale);
      expect(stale.single.days, 30);
    });

    test('three defects with the same title flag a pattern, not a cause', () {
      final risks = analyze(defects: [
        defect(id: 'a', status: DefectStatus.closed),
        defect(id: 'b', status: DefectStatus.closed),
        defect(id: 'c', status: DefectStatus.closed),
      ]);
      final recurring =
          risks.where((r) => r.kind == RiskKind.defectRecurring).toList();
      expect(recurring.single.count, 3);
      expect(recurring.single.severity, RiskSeverity.medium);
    });

    test('an unassigned high defect adds an INFO data-quality risk', () {
      final risks = analyze(
          defects: [defect(priority: DefectPriority.high, officer: '  ')]);
      expect(
        risks.map((r) => r.kind),
        containsAll([RiskKind.defectHighOpen, RiskKind.dataMissingInfo]),
      );
      final info =
          risks.firstWhere((r) => r.kind == RiskKind.dataMissingInfo);
      expect(info.severity, RiskSeverity.info);
      expect(info.category, RiskCategory.dataQuality);
    });
  });

  group('certificate windows', () {
    test('expiry tiers match the specified day windows', () {
      expect(analyze(certs: [cert(-1)]).single.severity, RiskSeverity.critical);
      expect(analyze(certs: [cert(7)]).single.severity, RiskSeverity.critical);
      expect(analyze(certs: [cert(8)]).single.severity, RiskSeverity.high);
      expect(analyze(certs: [cert(30)]).single.severity, RiskSeverity.high);
      expect(analyze(certs: [cert(31)]).single.severity, RiskSeverity.medium);
      expect(analyze(certs: [cert(60)]).single.severity, RiskSeverity.medium);
      expect(analyze(certs: [cert(61)]).single.severity, RiskSeverity.low);
      expect(analyze(certs: [cert(90)]).single.severity, RiskSeverity.low);
      expect(analyze(certs: [cert(91)]), isEmpty);
    });

    test('an expired certificate is reported as expired, not expiring', () {
      expect(analyze(certs: [cert(-5)]).single.kind, RiskKind.certExpired);
      expect(analyze(certs: [cert(5)]).single.kind, RiskKind.certExpiring);
    });
  });

  group('port readiness', () {
    PortRequirement req(RequirementStatus status, String id) => PortRequirement(
          id: id,
          vesselId: 'v1',
          title: 'Crew list',
          status: status,
          createdAt: fixedNow,
        );

    test('percentage reflects ready vs total', () {
      final input = VesselRiskInput(vesselId: 'v1', portRequirements: [
        req(RequirementStatus.ready, 'a'),
        req(RequirementStatus.ready, 'b'),
        req(RequirementStatus.pending, 'c'),
        req(RequirementStatus.pending, 'd'),
      ]);
      expect(RiskEngine.portReadinessPercent(input), 50);
    });

    test('no requirements means no data, not 100 percent', () {
      expect(
        RiskEngine.portReadinessPercent(const VesselRiskInput(vesselId: 'v1')),
        isNull,
      );
    });
  });

  group('health score', () {
    test('a vessel with no risks scores 100 and needs no explanation', () {
      final health =
          VesselHealthService.calculate(vesselId: 'v1', risks: const []);
      expect(health.score, 100);
      expect(health.band, HealthBand.good);
      expect(health.deductions, isEmpty);
    });

    test('a single critical risk caps the score below the healthy band', () {
      final risks =
          analyze(defects: [defect(priority: DefectPriority.critical)]);
      final health =
          VesselHealthService.calculate(vesselId: 'v1', risks: risks);
      expect(health.score, lessThanOrEqualTo(VesselHealthService.criticalCap));
      expect(health.band, isNot(HealthBand.good));
    });

    test('the explanation accounts for exactly the points lost', () {
      final risks = analyze(
        defects: [defect(priority: DefectPriority.high)],
        certs: [cert(20)],
      );
      final health =
          VesselHealthService.calculate(vesselId: 'v1', risks: risks);
      final explained =
          health.deductions.fold<int>(0, (sum, d) => sum + d.points);
      expect(explained, 100 - health.score);
      expect(health.deductions, isNotEmpty);
    });

    test('INFO risks are reported but cost no points', () {
      final risks = analyze(
          defects: [defect(priority: DefectPriority.low, officer: '')]);
      expect(risks.every((r) => r.severity == RiskSeverity.info), isTrue);
      final health =
          VesselHealthService.calculate(vesselId: 'v1', risks: risks);
      expect(health.score, 100);
    });

    test('component weights sum to 100', () {
      final total = VesselHealthService.weights.values
          .fold<int>(0, (sum, w) => sum + w);
      expect(total, 100);
    });
  });
}
