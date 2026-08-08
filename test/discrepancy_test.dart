// Discrepancy detection decides whether a re-uploaded document is treated as
// "you already have this" or silently duplicated, so the matching rules and
// the "a blank field is not a disagreement" rule are pinned here.
import 'package:flutter_test/flutter_test.dart';

import 'package:maridive_fleet_vessels/models/defect.dart';
import 'package:maridive_fleet_vessels/models/module_item.dart';
import 'package:maridive_fleet_vessels/models/requisition.dart';
import 'package:maridive_fleet_vessels/models/vessel_certificate.dart';
import 'package:maridive_fleet_vessels/services/discrepancy_service.dart';

void main() {
  final now = DateTime(2026, 8, 8);

  ModuleItem item(Map<String, dynamic> fields, String kind) => ModuleItem(
        id: 'i1',
        batchId: 'b1',
        sourceFileId: 'f1',
        targetKind: kind,
        fields: fields,
        confidence: 0.9,
        matchedRuleId: 'r1',
        createdAt: now,
      );

  VesselCertificate cert({
    required String name,
    required DateTime expiry,
    String authority = 'Class Society',
  }) =>
      VesselCertificate(
        id: 'c1',
        vesselId: 'v1',
        documentName: name,
        issuingAuthority: authority,
        issueDate: DateTime(2025, 1, 1),
        expiryDate: expiry,
      );

  group('vessel certificates', () {
    test('a new expiry date on a known certificate is reported', () {
      final match = DiscrepancyService.forVesselCert(
        item({
          'documentName': 'Safety Equipment Certificate',
          'expiryDate': '2027-03-01',
        }, 'vessel_certificate'),
        [cert(name: 'Safety Equipment Certificate', expiry: DateTime(2026, 9, 1))],
      );

      expect(match, isNotNull);
      expect(match!.hasDifferences, isTrue);
      final diff = match.diffs.firstWhere((d) => d.field == 'expiryDate');
      expect(diff.existingValue, '2026-09-01');
      expect(diff.extractedValue, '2027-03-01');
    });

    test('an abbreviated name still matches the full certificate name', () {
      final match = DiscrepancyService.forVesselCert(
        item({'documentName': 'ISSC'}, 'vessel_certificate'),
        [
          cert(
              name: 'International Ship Security Certificate ISSC',
              expiry: DateTime(2026, 9, 1))
        ],
      );
      expect(match, isNotNull);
    });

    test('an identical re-upload matches with no differences', () {
      final match = DiscrepancyService.forVesselCert(
        item({
          'documentName': 'Safety Equipment Certificate',
          'expiryDate': '2026-09-01',
          'issuingAuthority': 'Class Society',
        }, 'vessel_certificate'),
        [cert(name: 'Safety Equipment Certificate', expiry: DateTime(2026, 9, 1))],
      );
      expect(match, isNotNull);
      expect(match!.hasDifferences, isFalse);
    });

    test('a field the document does not state is not a disagreement', () {
      final match = DiscrepancyService.forVesselCert(
        item({'documentName': 'Safety Equipment Certificate'},
            'vessel_certificate'),
        [cert(name: 'Safety Equipment Certificate', expiry: DateTime(2026, 9, 1))],
      );
      expect(match!.diffs, isEmpty);
    });

    test('an unrelated certificate produces no match', () {
      final match = DiscrepancyService.forVesselCert(
        item({'documentName': 'Load Line Certificate'}, 'vessel_certificate'),
        [cert(name: 'Safety Equipment Certificate', expiry: DateTime(2026, 9, 1))],
      );
      expect(match, isNull);
    });
  });

  group('requisitions', () {
    Requisition req({required String number, required String name}) =>
        Requisition(
          id: 'r1',
          vesselId: 'v1',
          requisitionNumber: number,
          itemName: name,
          partNumber: '',
          oemManufacturer: '',
          quantity: 2,
          quantityInStock: 0,
          unit: 'pcs',
          unitPrice: 100,
          department: RequisitionDepartment.engine,
          priority: RequisitionPriority.normal,
          status: RequisitionStatus.pending,
          requiredDeliveryDate: null,
          notes: '',
          attachments: const [],
          requestedAt: now,
        );

    test('the PR number matches even when the item name was retyped', () {
      final match = DiscrepancyService.forRequisition(
        item({
          'requisitionNumber': 'MD ZOHR1ENG2025-255',
          'itemName': 'Fuel filter element',
          'quantity': 5,
        }, 'requisition'),
        [req(number: 'MD ZOHR1ENG2025-255', name: 'Fuel filter')],
      );

      expect(match, isNotNull);
      expect(match!.diffs.map((d) => d.field), contains('quantity'));
      final qty = match.diffs.firstWhere((d) => d.field == 'quantity');
      expect(qty.existingValue, '2');
      expect(qty.extractedValue, '5');
    });

    test('with no PR number it falls back to the item name', () {
      final match = DiscrepancyService.forRequisition(
        item({'itemName': 'Fuel filter'}, 'requisition'),
        [req(number: '', name: 'Fuel filter')],
      );
      expect(match, isNotNull);
    });
  });

  test('a defect with the same title is flagged before it is duplicated', () {
    final existing = Defect(
      id: 'd1',
      vesselId: 'v1',
      title: 'Oil Mist Detector ME out of order',
      description: '',
      location: DefectLocation.engineRoom,
      priority: DefectPriority.high,
      status: DefectStatus.open,
      assignedOfficer: 'C/E',
      requiredSpareParts: '',
      actionTaken: '',
      attachments: const [],
      reportedAt: now,
    );

    final match = DiscrepancyService.forDefect(
      item({
        'title': 'Oil Mist Detector ME out of order',
        'priority': 'critical',
      }, 'defect'),
      [existing],
    );

    expect(match, isNotNull);
    final diff = match!.diffs.firstWhere((d) => d.field == 'priority');
    expect(diff.existingValue, 'high');
    expect(diff.extractedValue, 'critical');
  });
}
