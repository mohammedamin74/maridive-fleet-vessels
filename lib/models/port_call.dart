import 'attachment.dart';
import 'checklist_item.dart';

enum PortCallStatus { upcoming, arrived, departed }

const List<String> defaultCustomsChecklistLabels = [
  'Crew List',
  'Cargo Manifest',
  'Health Declaration',
  'Port Clearance',
  'ISPS Declaration',
];

class PortCall {
  final String id;
  final String vesselId;
  final String portName;
  final DateTime arrivalEta;
  final DateTime? pilotBoardingTime;
  final String agentName;
  final String agentContact;
  final double bunkersMgoRequired;
  final double bunkersHfoRequired;
  final double freshWaterRequired;
  final String provisionsRequired;
  final bool sludgeDisposalRequired;
  final double sludgeQuantity;
  final List<ChecklistItem> customsChecklist;
  final PortCallStatus status;
  final List<Attachment> attachments;
  final DateTime createdAt;

  const PortCall({
    required this.id,
    required this.vesselId,
    required this.portName,
    required this.arrivalEta,
    this.pilotBoardingTime,
    required this.agentName,
    required this.agentContact,
    required this.bunkersMgoRequired,
    required this.bunkersHfoRequired,
    required this.freshWaterRequired,
    required this.provisionsRequired,
    required this.sludgeDisposalRequired,
    required this.sludgeQuantity,
    required this.customsChecklist,
    required this.status,
    this.attachments = const [],
    required this.createdAt,
  });

  PortCall copyWith(
          {PortCallStatus? status,
          List<ChecklistItem>? customsChecklist,
          List<Attachment>? attachments}) =>
      PortCall(
        id: id,
        vesselId: vesselId,
        portName: portName,
        arrivalEta: arrivalEta,
        pilotBoardingTime: pilotBoardingTime,
        agentName: agentName,
        agentContact: agentContact,
        bunkersMgoRequired: bunkersMgoRequired,
        bunkersHfoRequired: bunkersHfoRequired,
        freshWaterRequired: freshWaterRequired,
        provisionsRequired: provisionsRequired,
        sludgeDisposalRequired: sludgeDisposalRequired,
        sludgeQuantity: sludgeQuantity,
        customsChecklist: customsChecklist ?? this.customsChecklist,
        status: status ?? this.status,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'portName': portName,
        'arrivalEta': arrivalEta.toIso8601String(),
        'pilotBoardingTime': pilotBoardingTime?.toIso8601String(),
        'agentName': agentName,
        'agentContact': agentContact,
        'bunkersMgoRequired': bunkersMgoRequired,
        'bunkersHfoRequired': bunkersHfoRequired,
        'freshWaterRequired': freshWaterRequired,
        'provisionsRequired': provisionsRequired,
        'sludgeDisposalRequired': sludgeDisposalRequired,
        'sludgeQuantity': sludgeQuantity,
        'customsChecklist': customsChecklist.map((c) => c.toMap()).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PortCall.fromMap(Map<dynamic, dynamic> map) => PortCall(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        portName: map['portName'] as String,
        arrivalEta: DateTime.parse(map['arrivalEta'] as String),
        pilotBoardingTime: map['pilotBoardingTime'] != null
            ? DateTime.parse(map['pilotBoardingTime'] as String)
            : null,
        agentName: (map['agentName'] as String?) ?? '',
        agentContact: (map['agentContact'] as String?) ?? '',
        bunkersMgoRequired:
            (map['bunkersMgoRequired'] as num?)?.toDouble() ?? 0,
        bunkersHfoRequired:
            (map['bunkersHfoRequired'] as num?)?.toDouble() ?? 0,
        freshWaterRequired:
            (map['freshWaterRequired'] as num?)?.toDouble() ?? 0,
        provisionsRequired: (map['provisionsRequired'] as String?) ?? '',
        sludgeDisposalRequired:
            (map['sludgeDisposalRequired'] as bool?) ?? false,
        sludgeQuantity: (map['sludgeQuantity'] as num?)?.toDouble() ?? 0,
        customsChecklist: ((map['customsChecklist'] as List?) ?? [])
            .map((e) => ChecklistItem.fromMap(e as Map))
            .toList(),
        status: PortCallStatus.values
            .byName((map['status'] as String?) ?? 'upcoming'),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
