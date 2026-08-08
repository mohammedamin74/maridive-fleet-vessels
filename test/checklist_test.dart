// The checklist templates are transcriptions of controlled office forms, so
// these tests guard the transcription itself (counts, codes, bilingual text)
// as much as the logic — a silently dropped item would mean the vessel stops
// checking a piece of critical equipment.
import 'package:flutter_test/flutter_test.dart';

import 'package:maridive_fleet_vessels/data/checklist_templates.dart';
import 'package:maridive_fleet_vessels/models/checklist_run.dart';
import 'package:maridive_fleet_vessels/models/checklist_template.dart';
import 'package:maridive_fleet_vessels/models/fleet_intelligence.dart';
import 'package:maridive_fleet_vessels/services/clock.dart';
import 'package:maridive_fleet_vessels/services/risk_engine.dart';

void main() {
  group('transcribed forms', () {
    test('every form keeps its office code and full item count', () {
      expect(ChecklistTemplates.criticalEquipment.code, 'FLT-FM-009');
      expect(ChecklistTemplates.criticalEquipment.items, hasLength(29));

      expect(ChecklistTemplates.weeklyRoutine.code, 'TCH.FM.009+A1');
      expect(ChecklistTemplates.weeklyRoutine.items, hasLength(58));

      expect(ChecklistTemplates.dailyRoutine.code, 'EN.FM.008');
      expect(ChecklistTemplates.dailyRoutine.items, hasLength(27));
    });

    test('every item carries both languages', () {
      for (final template in [
        ChecklistTemplates.criticalEquipment,
        ChecklistTemplates.weeklyRoutine,
        ChecklistTemplates.dailyRoutine,
      ]) {
        for (final item in template.items) {
          expect(item.en.trim(), isNotEmpty,
              reason: '${template.code} item ${item.no} has no English text');
          expect(item.ar.trim(), isNotEmpty,
              reason: '${template.code} item ${item.no} has no Arabic text');
        }
      }
    });

    test('critical equipment items state how often they are due', () {
      for (final item in ChecklistTemplates.criticalEquipment.items) {
        expect(item.interval, isNotNull, reason: 'item ${item.no}');
      }
      // Both intervals are actually in use — a form that lost all its weekly
      // or all its monthly items would still pass the checks above.
      final intervals =
          ChecklistTemplates.criticalEquipment.items.map((i) => i.interval);
      expect(intervals, contains(ChecklistInterval.weekly));
      expect(intervals, contains(ChecklistInterval.monthly));
    });

    test('item keys are unique so results cannot collide', () {
      for (final template in ChecklistTemplates.all) {
        final keys = template.items.map((i) => i.key).toSet();
        expect(keys, hasLength(template.items.length),
            reason: '${template.code} has duplicate item keys');
      }
    });
  });

  group('slot counts', () {
    test('grids map to the right number of slots', () {
      expect(ChecklistTemplates.criticalEquipment.slotCount(2026, 6), 1);
      expect(ChecklistTemplates.weeklyRoutine.slotCount(2026, 6), 4);
      // Day grids follow the real length of the month, leap years included.
      expect(ChecklistTemplates.dailyRoutine.slotCount(2026, 6), 30);
      expect(ChecklistTemplates.dailyRoutine.slotCount(2026, 7), 31);
      expect(ChecklistTemplates.dailyRoutine.slotCount(2024, 2), 29);
      expect(ChecklistTemplates.dailyRoutine.slotCount(2026, 2), 28);
    });
  });

  group('run', () {
    ChecklistRun run({Map<String, Map<int, SlotResult>> results = const {}}) =>
        ChecklistRun(
          id: 'r1',
          vesselId: 'v1',
          templateCode: 'FLT-FM-009',
          year: 2026,
          month: 8,
          results: results,
          createdAt: DateTime(2026, 8, 1),
        );

    test('N/A counts as answered, pending does not', () {
      final sheet = run(results: {
        'i1': {0: SlotResult.done},
        'i2': {0: SlotResult.notApplicable},
        'i3': {0: SlotResult.pending},
      });
      final (done, total) = sheet.progress(29, 1);
      expect(done, 2);
      expect(total, 29);
    });

    test('results survive a round trip through the cloud map', () {
      final sheet = run(results: {
        'i1': {0: SlotResult.done, 3: SlotResult.failed},
        'i2': {2: SlotResult.notApplicable},
      }).copyWith(remarks: {'i1': 'Renewed seal'});

      final restored = ChecklistRun.fromMap(sheet.toMap());
      expect(restored.resultFor('i1', 0), SlotResult.done);
      expect(restored.resultFor('i1', 3), SlotResult.failed);
      expect(restored.resultFor('i2', 2), SlotResult.notApplicable);
      expect(restored.resultFor('i2', 0), SlotResult.pending);
      expect(restored.remarks['i1'], 'Renewed seal');
    });

    test('the dates a check was done live on the run, not the form', () {
      // Dates differ every month, so the template must not carry them and
      // two months of the same form must be able to hold different ones.
      final august = run().copyWith(dates: {'i1': '4-11-18-25'});
      expect(august.dates['i1'], '4-11-18-25');
      expect(ChecklistRun.fromMap(august.toMap()).dates['i1'], '4-11-18-25');
      expect(run().dates, isEmpty);
    });

    test('reopening a signed sheet clears the signature stamp', () {
      final signed = run().copyWith(
          chiefEngineer: 'Ezzat Farouk', submittedAt: DateTime(2026, 8, 30));
      expect(signed.isSubmitted, isTrue);
      expect(signed.copyWith(clearSubmitted: true).isSubmitted, isFalse);
    });
  });

  group('risk rule', () {
    tearDown(resetClock);

    List<RiskEvent> analyzeOn(int day, {ChecklistRun? sheet}) {
      setClockForTesting(() => DateTime(2026, 8, day, 12));
      return RiskEngine.analyze(VesselRiskInput(
        vesselId: 'v1',
        criticalChecklist: sheet,
        criticalChecklistItemCount: 29,
      ));
    }

    test('an untouched sheet early in the month is not yet a risk', () {
      expect(analyzeOn(5), isEmpty);
    });

    test('no sheet started late in the month is flagged', () {
      final risks = analyzeOn(25);
      expect(risks.single.kind, RiskKind.checklistMissing);
      expect(risks.single.severity, RiskSeverity.medium);
    });

    test('a mostly blank sheet late in the month is high severity', () {
      final sheet = ChecklistRun(
        id: 'r1',
        vesselId: 'v1',
        templateCode: 'FLT-FM-009',
        year: 2026,
        month: 8,
        results: {'i1': {0: SlotResult.done}},
        createdAt: DateTime(2026, 8, 1),
      );
      final risks = analyzeOn(25, sheet: sheet);
      expect(risks.single.kind, RiskKind.checklistIncomplete);
      expect(risks.single.severity, RiskSeverity.high);
      expect(risks.single.count, 28);
    });

    test('a fully completed sheet raises nothing', () {
      final sheet = ChecklistRun(
        id: 'r1',
        vesselId: 'v1',
        templateCode: 'FLT-FM-009',
        year: 2026,
        month: 8,
        results: {
          for (var i = 1; i <= 29; i++) 'i$i': {0: SlotResult.done}
        },
        createdAt: DateTime(2026, 8, 1),
      );
      expect(analyzeOn(28, sheet: sheet), isEmpty);
    });
  });
}
