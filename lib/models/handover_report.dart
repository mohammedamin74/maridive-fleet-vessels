import 'attachment.dart';

/// Lifecycle of a crew handover report: written as a [draft], [issued] by the
/// outgoing officer, then [acknowledged] by the incoming officer once read.
enum HandoverStatus { draft, issued, acknowledged }

class HandoverReport {
  final String id;
  final String vesselId;
  final String outgoingOfficer;
  final String incomingOfficer;
  final String rank;
  final DateTime handoverDate;
  final String safety;
  final String machinery;
  final String pendingDefects;
  final String bunkersAndTanks;
  final String certificatesExpiring;
  final String remarks;
  final HandoverStatus status;
  final String acknowledgedBy;
  final List<Attachment> attachments;
  final DateTime createdAt;

  const HandoverReport({
    required this.id,
    required this.vesselId,
    required this.outgoingOfficer,
    required this.incomingOfficer,
    required this.rank,
    required this.handoverDate,
    required this.safety,
    required this.machinery,
    required this.pendingDefects,
    required this.bunkersAndTanks,
    required this.certificatesExpiring,
    required this.remarks,
    required this.status,
    this.acknowledgedBy = '',
    this.attachments = const [],
    required this.createdAt,
  });

  HandoverReport copyWith({
    String? outgoingOfficer,
    String? incomingOfficer,
    String? rank,
    DateTime? handoverDate,
    String? safety,
    String? machinery,
    String? pendingDefects,
    String? bunkersAndTanks,
    String? certificatesExpiring,
    String? remarks,
    HandoverStatus? status,
    String? acknowledgedBy,
    List<Attachment>? attachments,
  }) =>
      HandoverReport(
        id: id,
        vesselId: vesselId,
        outgoingOfficer: outgoingOfficer ?? this.outgoingOfficer,
        incomingOfficer: incomingOfficer ?? this.incomingOfficer,
        rank: rank ?? this.rank,
        handoverDate: handoverDate ?? this.handoverDate,
        safety: safety ?? this.safety,
        machinery: machinery ?? this.machinery,
        pendingDefects: pendingDefects ?? this.pendingDefects,
        bunkersAndTanks: bunkersAndTanks ?? this.bunkersAndTanks,
        certificatesExpiring: certificatesExpiring ?? this.certificatesExpiring,
        remarks: remarks ?? this.remarks,
        status: status ?? this.status,
        acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'outgoingOfficer': outgoingOfficer,
        'incomingOfficer': incomingOfficer,
        'rank': rank,
        'handoverDate': handoverDate.toIso8601String(),
        'safety': safety,
        'machinery': machinery,
        'pendingDefects': pendingDefects,
        'bunkersAndTanks': bunkersAndTanks,
        'certificatesExpiring': certificatesExpiring,
        'remarks': remarks,
        'status': status.name,
        'acknowledgedBy': acknowledgedBy,
        'attachments': Attachment.listToMap(attachments),
        'createdAt': createdAt.toIso8601String(),
      };

  factory HandoverReport.fromMap(Map<dynamic, dynamic> map) => HandoverReport(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        outgoingOfficer: (map['outgoingOfficer'] as String?) ?? '',
        incomingOfficer: (map['incomingOfficer'] as String?) ?? '',
        rank: (map['rank'] as String?) ?? '',
        handoverDate: DateTime.parse(map['handoverDate'] as String),
        safety: (map['safety'] as String?) ?? '',
        machinery: (map['machinery'] as String?) ?? '',
        pendingDefects: (map['pendingDefects'] as String?) ?? '',
        bunkersAndTanks: (map['bunkersAndTanks'] as String?) ?? '',
        certificatesExpiring: (map['certificatesExpiring'] as String?) ?? '',
        remarks: (map['remarks'] as String?) ?? '',
        status: HandoverStatus.values
            .byName((map['status'] as String?) ?? 'draft'),
        acknowledgedBy: (map['acknowledgedBy'] as String?) ?? '',
        attachments: Attachment.listFromMap(map),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
