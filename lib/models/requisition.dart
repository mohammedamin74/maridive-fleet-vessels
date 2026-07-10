enum RequisitionPriority { low, normal, urgent }

/// Approval chain followed by fulfillment: pending -> hodApproval ->
/// technicalSupApproval -> approved -> ordered -> received (or rejected
/// at any point before approved).
enum RequisitionStatus {
  pending,
  hodApproval,
  technicalSupApproval,
  approved,
  ordered,
  received,
  rejected,
}

enum RequisitionDepartment { engine, deck, steward }

class Requisition {
  final String id;
  final String vesselId;
  final String requisitionNumber;
  final String itemName;
  final String partNumber;
  final String oemManufacturer;
  final double quantity;
  final double quantityInStock;
  final String unit;
  final double unitPrice;
  final RequisitionDepartment department;
  final RequisitionPriority priority;
  final RequisitionStatus status;
  final DateTime? requiredDeliveryDate;
  final String notes;
  final List<String> photosBase64;
  final DateTime requestedAt;

  const Requisition({
    required this.id,
    required this.vesselId,
    required this.requisitionNumber,
    required this.itemName,
    required this.partNumber,
    required this.oemManufacturer,
    required this.quantity,
    required this.quantityInStock,
    required this.unit,
    required this.unitPrice,
    required this.department,
    required this.priority,
    required this.status,
    required this.requiredDeliveryDate,
    required this.notes,
    required this.photosBase64,
    required this.requestedAt,
  });

  Requisition copyWith(
          {RequisitionStatus? status, List<String>? photosBase64}) =>
      Requisition(
        id: id,
        vesselId: vesselId,
        requisitionNumber: requisitionNumber,
        itemName: itemName,
        partNumber: partNumber,
        oemManufacturer: oemManufacturer,
        quantity: quantity,
        quantityInStock: quantityInStock,
        unit: unit,
        unitPrice: unitPrice,
        department: department,
        priority: priority,
        status: status ?? this.status,
        requiredDeliveryDate: requiredDeliveryDate,
        notes: notes,
        photosBase64: photosBase64 ?? this.photosBase64,
        requestedAt: requestedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'requisitionNumber': requisitionNumber,
        'itemName': itemName,
        'partNumber': partNumber,
        'oemManufacturer': oemManufacturer,
        'quantity': quantity,
        'quantityInStock': quantityInStock,
        'unit': unit,
        'unitPrice': unitPrice,
        'department': department.name,
        'priority': priority.name,
        'status': status.name,
        'requiredDeliveryDate': requiredDeliveryDate?.toIso8601String(),
        'notes': notes,
        'photosBase64': photosBase64,
        'requestedAt': requestedAt.toIso8601String(),
      };

  factory Requisition.fromMap(Map<dynamic, dynamic> map) => Requisition(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        requisitionNumber: (map['requisitionNumber'] as String?) ?? '',
        itemName: map['itemName'] as String,
        partNumber: (map['partNumber'] as String?) ?? '',
        oemManufacturer: (map['oemManufacturer'] as String?) ?? '',
        quantity: (map['quantity'] as num).toDouble(),
        quantityInStock: (map['quantityInStock'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] as String,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
        department: RequisitionDepartment.values
            .byName((map['department'] as String?) ?? 'deck'),
        priority: RequisitionPriority.values.byName(map['priority'] as String),
        status: RequisitionStatus.values.byName(map['status'] as String),
        requiredDeliveryDate: map['requiredDeliveryDate'] != null
            ? DateTime.parse(map['requiredDeliveryDate'] as String)
            : null,
        notes: (map['notes'] as String?) ?? '',
        photosBase64: ((map['photosBase64'] as List?) ?? []).cast<String>(),
        requestedAt: DateTime.parse(map['requestedAt'] as String),
      );
}
