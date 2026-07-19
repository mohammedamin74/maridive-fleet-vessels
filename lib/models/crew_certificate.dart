import 'attachment.dart';
import 'vessel_certificate.dart';
import '../services/clock.dart';

enum CrewCertType { coc, stcw, medical, other }

/// Sentinel distinguishing "leave photoBase64 unchanged" from "explicitly
/// clear it to null" in [CrewCertificate.copyWith].
const Object _unset = Object();

class CrewCertificate {
  final String id;
  final String vesselId;
  final String officerName;
  final String rank;
  final CrewCertType certType;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? photoBase64;
  final List<Attachment> attachments;

  const CrewCertificate({
    required this.id,
    required this.vesselId,
    required this.officerName,
    required this.rank,
    required this.certType,
    required this.issueDate,
    required this.expiryDate,
    this.photoBase64,
    this.attachments = const [],
  });

  CrewCertificate copyWith({
    String? officerName,
    String? rank,
    CrewCertType? certType,
    DateTime? issueDate,
    DateTime? expiryDate,
    Object? photoBase64 = _unset,
    List<Attachment>? attachments,
  }) =>
      CrewCertificate(
        id: id,
        vesselId: vesselId,
        officerName: officerName ?? this.officerName,
        rank: rank ?? this.rank,
        certType: certType ?? this.certType,
        issueDate: issueDate ?? this.issueDate,
        expiryDate: expiryDate ?? this.expiryDate,
        photoBase64:
            photoBase64 == _unset ? this.photoBase64 : photoBase64 as String?,
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
        'officerName': officerName,
        'rank': rank,
        'certType': certType.name,
        'issueDate': issueDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'photoBase64': photoBase64,
        'attachments': Attachment.listToMap(attachments),
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
        attachments: Attachment.listFromMap(map),
      );
}
