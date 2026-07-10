import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/crew_certificate.dart';
import '../models/vessel_certificate.dart';

class CertificationProvider extends ChangeNotifier {
  final Box vesselCertsBox;
  final Box crewCertsBox;

  CertificationProvider(
      {required this.vesselCertsBox, required this.crewCertsBox});

  List<VesselCertificate> vesselCertsFor(String vesselId) {
    final list = vesselCertsBox.values
        .map((e) => VesselCertificate.fromMap(e as Map))
        .where((c) => c.vesselId == vesselId)
        .toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  List<CrewCertificate> crewCertsFor(String vesselId) {
    final list = crewCertsBox.values
        .map((e) => CrewCertificate.fromMap(e as Map))
        .where((c) => c.vesselId == vesselId)
        .toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  List<VesselCertificate> expiringVesselCerts(List<String> vesselIds) {
    final list = vesselCertsBox.values
        .map((e) => VesselCertificate.fromMap(e as Map))
        .where((c) =>
            vesselIds.contains(c.vesselId) &&
            c.reminderStatus != CertReminderStatus.green)
        .toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  List<CrewCertificate> expiringCrewCerts(List<String> vesselIds) {
    final list = crewCertsBox.values
        .map((e) => CrewCertificate.fromMap(e as Map))
        .where((c) =>
            vesselIds.contains(c.vesselId) &&
            c.reminderStatus != CertReminderStatus.green)
        .toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  Future<void> addVesselCert({
    required String vesselId,
    required String documentName,
    required String issuingAuthority,
    required DateTime issueDate,
    required DateTime expiryDate,
  }) async {
    final cert = VesselCertificate(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      documentName: documentName,
      issuingAuthority: issuingAuthority,
      issueDate: issueDate,
      expiryDate: expiryDate,
    );
    await vesselCertsBox.put(cert.id, cert.toMap());
    notifyListeners();
  }

  Future<void> deleteVesselCert(String id) async {
    await vesselCertsBox.delete(id);
    notifyListeners();
  }

  Future<void> addCrewCert({
    required String vesselId,
    required String officerName,
    required String rank,
    required CrewCertType certType,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? photoBase64,
  }) async {
    final cert = CrewCertificate(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      officerName: officerName,
      rank: rank,
      certType: certType,
      issueDate: issueDate,
      expiryDate: expiryDate,
      photoBase64: photoBase64,
    );
    await crewCertsBox.put(cert.id, cert.toMap());
    notifyListeners();
  }

  Future<void> deleteCrewCert(String id) async {
    await crewCertsBox.delete(id);
    notifyListeners();
  }
}
