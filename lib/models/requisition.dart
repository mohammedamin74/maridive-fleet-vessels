enum RequisitionPriority { low, normal, urgent }

enum RequisitionStatus { pending, approved, ordered, received, rejected }

class Requisition {
  final String id;
  final String vesselId;
  final String itemName;
  final double quantity;
  final String unit;
  final RequisitionPriority priority;
  final RequisitionStatus status;
  final String notes;
  final DateTime requestedAt;

  const Requisition({
    required this.id,
    required this.vesselId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.priority,
    required this.status,
    required this.notes,
    required this.requestedAt,
  });

  Requisition copyWith({RequisitionStatus? status}) => Requisition(
        id: id,
        vesselId: vesselId,
        itemName: itemName,
        quantity: quantity,
        unit: unit,
        priority: priority,
        status: status ?? this.status,
        notes: notes,
        requestedAt: requestedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'itemName': itemName,
        'quantity': quantity,
        'unit': unit,
        'priority': priority.name,
        'status': status.name,
        'notes': notes,
        'requestedAt': requestedAt.toIso8601String(),
      };

  factory Requisition.fromMap(Map<dynamic, dynamic> map) => Requisition(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        itemName: map['itemName'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String,
        priority: RequisitionPriority.values.byName(map['priority'] as String),
        status: RequisitionStatus.values.byName(map['status'] as String),
        notes: (map['notes'] as String?) ?? '',
        requestedAt: DateTime.parse(map['requestedAt'] as String),
      );
}
