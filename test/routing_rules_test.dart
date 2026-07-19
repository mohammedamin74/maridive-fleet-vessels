// Routing decides which module a batch file's extracted content lands in,
// so a wrong decision misfiles a record — these cases pin the priority
// ordering (crew-cert keywords must win over the generic certificate
// fallback) and the "never silently guess" behavior for unclassified files.
import 'package:flutter_test/flutter_test.dart';

import 'package:maridive_fleet_vessels/services/routing_rules.dart';

void main() {
  RoutingDecision routeFile(String filename, {String? screenHint, String? userAnnotation}) =>
      route(RoutingContext(
        filename: filename,
        detectedExt: filename.contains('.') ? filename.split('.').last : '',
        screenHint: screenHint,
        userAnnotation: userAnnotation,
      ));

  test('user annotation always wins, regardless of filename', () {
    final decision =
        routeFile('random_document.pdf', userAnnotation: 'defect');
    expect(decision.kind, 'defect');
    expect(decision.confidence, 1.0);
    expect(decision.ruleId, 'user_override');
  });

  test('screen hint wins over filename when no user annotation is set', () {
    final decision = routeFile('Certificate_Scan.pdf', screenHint: 'crew');
    expect(decision.kind, 'crew');
    expect(decision.ruleId, 'screen_hint');
  });

  test('crew certificate keywords win over the generic certificate fallback', () {
    expect(routeFile('STCW_Certificate_JDoe.pdf').kind, 'crew_certificate');
    expect(routeFile('Medical_Certificate.pdf').kind, 'crew_certificate');
    expect(routeFile('CoC_Master.pdf').kind, 'crew_certificate');
  });

  test('a generic certificate filename falls through to vessel_certificate', () {
    expect(routeFile('Safety_Certificate_2026.pdf').kind, 'vessel_certificate');
  });

  test('requisition keywords route correctly', () {
    expect(routeFile('Parts_List_ME.xlsx').kind, 'requisition');
    expect(routeFile('quotation_pump.pdf').kind, 'requisition');
  });

  test('tank sounding keywords route to tank_reading', () {
    expect(routeFile('Sounding_Sheet_July.xlsx').kind, 'tank_reading');
    expect(routeFile('ROB_report.pdf').kind, 'tank_reading');
  });

  test('a filename with no matching keyword is unclassified, not guessed', () {
    final decision = routeFile('IMG_20260717_114523.jpg');
    expect(decision.isClassified, isFalse);
    expect(decision.kind, isNull);
  });

  test('handover keywords route correctly', () {
    expect(routeFile('Handover_Report_ChiefEngineer.docx').kind, 'handover');
  });

  test('urgent/incident keywords route correctly', () {
    expect(routeFile('Engine_Room_Fire_Incident.pdf').kind, 'urgent_notification');
  });
}
