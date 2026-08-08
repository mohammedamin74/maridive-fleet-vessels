// The daily briefing decides what a superintendent sees first, and the AI
// context decides what leaves the device. Both are pinned here: severity
// routing into the right section, a quiet vessel being reported as verified
// quiet, and the snapshot carrying no crew, cost or record-id data.
import 'package:flutter_test/flutter_test.dart';

import 'package:maridive_fleet_vessels/models/fleet_intelligence.dart';
import 'package:maridive_fleet_vessels/models/superintendent_action.dart';
import 'package:maridive_fleet_vessels/models/vessel.dart';
import 'package:maridive_fleet_vessels/services/briefing_service.dart';
import 'package:maridive_fleet_vessels/services/clock.dart';
import 'package:maridive_fleet_vessels/services/fleet_intel.dart';
import 'package:maridive_fleet_vessels/services/vessel_health_service.dart';

void main() {
  final fixedNow = DateTime(2026, 8, 8, 12);
  setUp(() => setClockForTesting(() => fixedNow));
  tearDown(resetClock);

  RiskEvent risk(RiskSeverity severity,
          {String vesselId = 'v1', String subject = 'Main engine'}) =>
      RiskEvent(
        vesselId: vesselId,
        kind: RiskKind.defectCriticalOpen,
        category: RiskCategory.defects,
        severity: severity,
        subject: subject,
        sourceType: 'defect',
        sourceId: 'd-$vesselId-${severity.name}',
      );

  Vessel vessel(String id, String name) => Vessel(
        id: id,
        name: name,
        photoAsset: '',
        type: 'AHTS',
        imo: 'N/A',
        homePort: 'Alexandria',
        workingPort: 'Tripoli',
        crew: 50,
        status: VesselStatus.active,
        tanks: const [],
      );

  VesselIntel intelFor(String id, String name, List<RiskEvent> risks) =>
      VesselIntel(
        vessel: vessel(id, name),
        risks: risks,
        health: VesselHealthService.calculate(vesselId: id, risks: risks),
        portReadinessPercent: null,
      );

  SuperintendentAction action({
    required String id,
    DateTime? dueDate,
    ActionPriority priority = ActionPriority.medium,
  }) =>
      SuperintendentAction(
        id: id,
        vesselId: 'v1',
        title: 'Follow up $id',
        priority: priority,
        dueDate: dueDate,
        createdAt: fixedNow,
      );

  test('risks are routed into the section matching their severity', () {
    final intel = FleetIntel([
      intelFor('v1', 'Maridive 701', [
        risk(RiskSeverity.critical, subject: 'Critical item'),
        risk(RiskSeverity.high, subject: 'High item'),
        risk(RiskSeverity.medium, subject: 'Medium item'),
        risk(RiskSeverity.low, subject: 'Low item'),
      ]),
    ]);

    final b = BriefingService.build(intel: intel, openActions: const []);

    expect(b.critical.single.risk!.subject, 'Critical item');
    expect(b.highPriority.single.risk!.subject, 'High item');
    expect(b.upcoming.map((i) => i.risk!.subject),
        containsAll(['Medium item', 'Low item']));
    expect(b.isAllClear, isFalse);
  });

  test('a vessel with nothing above low is reported as verified quiet', () {
    final intel = FleetIntel([
      intelFor('v1', 'Maridive 701', [risk(RiskSeverity.critical)]),
      intelFor('v2', 'Maridive 704', [risk(RiskSeverity.low, vesselId: 'v2')]),
      intelFor('v3', 'Maridive 601', const []),
    ]);

    final b = BriefingService.build(intel: intel, openActions: const []);

    expect(b.positive, containsAll(['704', '601']));
    expect(b.positive, isNot(contains('701')));
  });

  test('an empty fleet briefing reads as all clear, not as no data', () {
    final intel = FleetIntel([intelFor('v1', 'Maridive 701', const [])]);
    final b = BriefingService.build(intel: intel, openActions: const []);
    expect(b.isAllClear, isTrue);
    expect(b.healthyCount, 1);
  });

  test('overdue actions are counted and listed before the rest', () {
    final intel = FleetIntel([intelFor('v1', 'Maridive 701', const [])]);
    final b = BriefingService.build(intel: intel, openActions: [
      action(id: 'later', dueDate: fixedNow.add(const Duration(days: 5))),
      action(id: 'overdue', dueDate: fixedNow.subtract(const Duration(days: 2))),
    ]);

    expect(b.overdueActionCount, 1);
    expect(b.openActions.first.action!.id, 'overdue');
  });

  group('AI context', () {
    test('carries scores and risks but no ids, costs or personal data', () {
      final intel = FleetIntel([
        intelFor('v1', 'Maridive 701', [risk(RiskSeverity.critical)]),
      ]);
      final ctx = BriefingService.aiContext(
          intel: intel, openActions: [action(id: 'a1')]);

      final vessels = ctx['vessels'] as List;
      final first = vessels.single as Map;
      expect(first['name'], 'Maridive 701');
      expect(first['healthScore'], isA<int>());

      final riskEntry = (first['risks'] as List).single as Map;
      expect(riskEntry.keys, containsAll(['severity', 'category', 'rule']));
      // Nothing that could identify a record or a person leaves the device.
      expect(riskEntry.containsKey('sourceId'), isFalse);

      final encoded = ctx.toString();
      expect(encoded.contains('d-v1-critical'), isFalse);
      expect(encoded.contains('cost'), isFalse);
    });

    test('long subjects are truncated so the snapshot stays small', () {
      final long = 'x' * 200;
      final intel = FleetIntel([
        intelFor('v1', 'Maridive 701',
            [risk(RiskSeverity.high, subject: long)]),
      ]);
      final ctx =
          BriefingService.aiContext(intel: intel, openActions: const []);
      final subject = (((ctx['vessels'] as List).single as Map)['risks']
          as List)
          .single as Map;
      expect((subject['subject'] as String).length, lessThan(100));
    });
  });
}
