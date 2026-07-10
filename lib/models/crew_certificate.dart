import 'vessel_certificate.dart';

enum CrewCertType { coc, stcw, medical, other }

class CrewCertificate {
  final String id;
  final String vesselId;
  final String officerName;
  final String rank;
  final CrewCertType certType;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? photoBase64;

  const CrewCertificate({
    required this.id,
    required this.vesselId,
    required this.officerName,
    required this.rank,
    required this.certType,
    required this.issueDate,
    required this.expiryDate,
    this.photoBase64,
  });

  CertReminderStatus get reminderStatus {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 30) return CertReminderStatus.red;
    if (daysLeft <= 90) return CertReminderStatus.amber;
    return CertReminderStatus.green;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'officerName': officerName,
        'rank': rank,
        'certType': certType.name,
        'issueDate': issueDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'photoBase64': photoBase64,
      };

  factory CrewCertificate.fromMap(Map<dynamic, dynamic> map) => CrewCertificate(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        officerName: map['officerName'] as String,
        rank: (map['rank'] as String?) ?? '',
        certType:
            CrewCertType.values.byName((map['certType'] as String?) ?? 'other'),
        issueDate: DateTime.parse(map['issueDate'] as String),
        expiryDate: DateTime.parse(map['expiryDate'] as String),
        photoBase64: map['photoBase64'] as String?,
      );
}
