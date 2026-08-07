import 'attachment.dart';

/// The cash meeting is a rolling ledger: every purchase line stays `pending`
/// until a meeting approves it, however many meetings that takes — mirroring
/// the office's "still not approved" worksheet tab. There is no per-meeting
/// snapshot entity; [decidedAt] records when the decision was taken.
enum CashItemStatus { pending, approved }

/// Currencies actually used across the fleet's purchase orders. Values are
/// normalized on entry ("EURO"/"eur" -> eur) so subtotals can group reliably;
/// amounts in different currencies are never summed together.
enum CashCurrency { eur, usd, gbp, other }

CashCurrency parseCashCurrency(String raw) {
  final v = raw.trim().toLowerCase();
  if (v.startsWith('eur')) return CashCurrency.eur;
  if (v.startsWith('usd') || v == r'$' || v.startsWith('dollar')) {
    return CashCurrency.usd;
  }
  if (v.startsWith('gbp') || v.startsWith('pound') || v == '£') {
    return CashCurrency.gbp;
  }
  return CashCurrency.other;
}

extension CashCurrencyLabel on CashCurrency {
  String get label {
    switch (this) {
      case CashCurrency.eur:
        return 'EUR';
      case CashCurrency.usd:
        return 'USD';
      case CashCurrency.gbp:
        return 'GBP';
      case CashCurrency.other:
        return '—';
    }
  }
}

/// One purchase line on the cash meeting sheet. Columns mirror the office's
/// Excel exactly: Operation/DD | Vessel | Request Description | Cost |
/// Currency | Supplier | PO. The PR number is kept as its own field when it
/// can be parsed out of the description; linkage to the Requisitions module
/// is opportunistic, never required.
class CashItem {
  final String id;
  final String vesselId;
  final String operation;
  final String description;
  final String prNumber;
  final double cost;
  final CashCurrency currency;
  final String supplier;
  final String poNumber;
  final CashItemStatus status;
  final DateTime? decidedAt;
  final String notes;
  final List<Attachment> attachments;
  final DateTime createdAt;

  const CashItem({
    required this.id,
    required this.vesselId,
    required this.operation,
    required this.description,
    required this.prNumber,
    required this.cost,
    required this.currency,
    required this.supplier,
    required this.poNumber,
    required this.status,
    required this.decidedAt,
    required this.notes,
    required this.attachments,
    required this.createdAt,
  });

  CashItem copyWith({
    String? vesselId,
    String? operation,
    String? description,
    String? prNumber,
    double? cost,
    CashCurrency? currency,
    String? supplier,
    String? poNumber,
    CashItemStatus? status,
    DateTime? decidedAt,
    String? notes,
    List<Attachment>? attachments,
  }) =>
      CashItem(
        id: id,
        vesselId: vesselId ?? this.vesselId,
        operation: operation ?? this.operation,
        description: description ?? this.description,
        prNumber: prNumber ?? this.prNumber,
        cost: cost ?? this.cost,
        currency: currency ?? this.currency,
        supplier: supplier ?? this.supplier,
        poNumber: poNumber ?? this.poNumber,
        status: status ?? this.status,
        decidedAt: decidedAt ?? this.decidedAt,
        notes: notes ?? this.notes,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'operation': operation,
        'description': description,
        'prNumber': prNumber,
        'cost': cost,
        'currency': currency.name,
        'supplier': supplier,
        'poNumber': poNumber,
        'status': status.name,
        'decidedAt': decidedAt?.toIso8601String(),
        'notes': notes,
        'attachments': Attachment.listToMap(attachments),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CashItem.fromMap(Map<dynamic, dynamic> map) => CashItem(
        id: map['id'] as String,
        vesselId: (map['vesselId'] as String?) ?? '',
        operation: (map['operation'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        prNumber: (map['prNumber'] as String?) ?? '',
        cost: (map['cost'] as num?)?.toDouble() ?? 0,
        currency: CashCurrency.values.asNameMap()[map['currency']] ??
            CashCurrency.other,
        supplier: (map['supplier'] as String?) ?? '',
        poNumber: (map['poNumber'] as String?) ?? '',
        status: CashItemStatus.values.asNameMap()[map['status']] ??
            CashItemStatus.pending,
        decidedAt: map['decidedAt'] != null
            ? DateTime.tryParse(map['decidedAt'] as String)
            : null,
        notes: (map['notes'] as String?) ?? '',
        attachments: Attachment.listFromMap(map),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );
}
