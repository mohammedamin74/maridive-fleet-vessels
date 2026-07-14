import 'attachment.dart';

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

/// Sentinel distinguishing "leave requiredDeliveryDate unchanged" from
/// "explicitly clear it to null" in [Requisition.copyWith].
const Object _unset = Object();

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
  final List<Attachment> attachments;
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
    required this.attachments,
    required this.requestedAt,
  });

  Requisition copyWith({
    String? itemName,
    String? partNumber,
    String? oemManufacturer,
    double? quantity,
    double? quantityInStock,
    String? unit,
    double? unitPrice,
    RequisitionDepartment? department,
    RequisitionPriority? priority,
    RequisitionStatus? status,
    Object? requiredDeliveryDate = _unset,
    String? notes,
    List<Attachment>? attachments,
  }) =>
      Requisition(
        id: id,
        vesselId: vesselId,
        requisitionNumber: requisitionNumber,
        itemName: itemName ?? this.itemName,
        partNumber: partNumber ?? this.partNumber,
        oemManufacturer: oemManufacturer ?? this.oemManufacturer,
        quantity: quantity ?? this.quantity,
        quantityInStock: quantityInStock ?? this.quantityInStock,
        unit: unit ?? this.unit,
        unitPrice: unitPrice ?? this.unitPrice,
        department: department ?? this.department,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        requiredDeliveryDate: requiredDeliveryDate == _unset
            ? this.requiredDeliveryDate
            : requiredDeliveryDate as DateTime?,
        notes: notes ?? this.notes,
        attachments: attachments ?? this.attachments,
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
        'attachments': Attachment.listToMap(attachments),
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
        attachments: Attachment.listFromMap(map),
        requestedAt: DateTime.parse(map['requestedAt'] as String),
      );
}
