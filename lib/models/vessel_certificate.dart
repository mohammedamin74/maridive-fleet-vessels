import 'attachment.dart';
import '../services/clock.dart';

enum CertReminderStatus { green, amber, red, expired }

class VesselCertificate {
  final String id;
  final String vesselId;
  final String documentName;
  final String issuingAuthority;
  final DateTime issueDate;
  final DateTime expiryDate;
  final List<Attachment> attachments;

  const VesselCertificate({
    required this.id,
    required this.vesselId,
    required this.documentName,
    required this.issuingAuthority,
    required this.issueDate,
    required this.expiryDate,
    this.attachments = const [],
  });

  VesselCertificate copyWith({
    String? documentName,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
    List<Attachment>? attachments,
  }) =>
      VesselCertificate(
        id: id,
        vesselId: vesselId,
        documentName: documentName ?? this.documentName,
        issuingAuthority: issuingAuthority ?? this.issuingAuthority,
        issueDate: issueDate ?? this.issueDate,
        expiryDate: expiryDate ?? this.expiryDate,
        attachments: attachments ?? this.attachments,
      );

  CertReminderStatus get reminderStatus {
    final daysLeft = expiryDate.difference(clockNow()).inDays;
    if (daysLeft < 0) return CertReminderStatus.expired;
    if (daysLeft <= 30) return CertReminderStatus.red;
    if (daysLeft <= 90) return CertReminderStatus.amber;
    return CertReminderStatus.green;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'documentName': documentName,
        'issuingAuthority': issuingAuthority,
        'issueDate': issueDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'attachments': Attachment.listToMap(attachments),
      };

  factory VesselCertificate.fromMap(Map<dynamic, dynamic> map) =>
      VesselCertificate(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        documentName: map['documentName'] as String,
        issuingAuthority: (map['issuingAuthority'] as String?) ?? '',
        issueDate: DateTime.parse(map['issueDate'] as String),
        expiryDate: DateTime.parse(map['expiryDate'] as String),
        attachments: Attachment.listFromMap(map),
      );
}
