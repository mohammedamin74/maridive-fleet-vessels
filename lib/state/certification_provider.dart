import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment.dart';
import '../models/crew_certificate.dart';
import '../models/vessel_certificate.dart';
import '../services/cloud_store.dart';
import '../services/supabase_config.dart';

/// Cloud-backed vessel + crew certificates. Both datasets live in their own
/// shared Supabase table; an in-memory cache of each is loaded on login (and
/// refreshed after writes) so the whole fleet shares one source of truth.
class CertificationProvider extends ChangeNotifier {
  final CloudStore _vesselCerts = const CloudStore('vessel_certs');
  final CloudStore _crewCerts = const CloudStore('crew_certs');

  List<VesselCertificate> _vesselCache = [];
  List<CrewCertificate> _crewCache = [];

  CertificationProvider() {
    _loadAll();
    SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.tokenRefreshed:
          _loadAll();
          break;
        case AuthChangeEvent.signedOut:
          _vesselCache = [];
          _crewCache = [];
          notifyListeners();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        _vesselCerts.fetchAll(),
        _crewCerts.fetchAll(),
      ]);
      _vesselCache = results[0].map(VesselCertificate.fromMap).toList();
      _crewCache = results[1].map(CrewCertificate.fromMap).toList();
      notifyListeners();
    } catch (_) {
      // Offline or not signed in yet — keep whatever is cached.
    }
  }

  Future<void> refresh() => _loadAll();

  List<VesselCertificate> vesselCertsFor(String vesselId) {
    final list = _vesselCache.where((c) => c.vesselId == vesselId).toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  List<CrewCertificate> crewCertsFor(String vesselId) {
    final list = _crewCache.where((c) => c.vesselId == vesselId).toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  List<VesselCertificate> expiringVesselCerts(List<String> vesselIds) {
    final list = _vesselCache
        .where((c) =>
            vesselIds.contains(c.vesselId) &&
            c.reminderStatus != CertReminderStatus.green)
        .toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  List<CrewCertificate> expiringCrewCerts(List<String> vesselIds) {
    final list = _crewCache
        .where((c) =>
            vesselIds.contains(c.vesselId) &&
            c.reminderStatus != CertReminderStatus.green)
        .toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  /// Certificates inside the 30-day alarm window (or already expired) —
  /// these raise the red dashboard alarm, unlike the wider amber reminder.
  List<VesselCertificate> alarmVesselCerts(List<String> vesselIds) {
    final list = _vesselCache
        .where((c) =>
            vesselIds.contains(c.vesselId) &&
            (c.reminderStatus == CertReminderStatus.red ||
                c.reminderStatus == CertReminderStatus.expired))
        .toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  List<CrewCertificate> alarmCrewCerts(List<String> vesselIds) {
    final list = _crewCache
        .where((c) =>
            vesselIds.contains(c.vesselId) &&
            (c.reminderStatus == CertReminderStatus.red ||
                c.reminderStatus == CertReminderStatus.expired))
        .toList();
    list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  // --- Vessel certificates ---

  Future<void> _saveVesselCert(VesselCertificate cert) async {
    final idx = _vesselCache.indexWhere((c) => c.id == cert.id);
    if (idx >= 0) {
      _vesselCache[idx] = cert;
    } else {
      _vesselCache = [..._vesselCache, cert];
    }
    notifyListeners();
    await _vesselCerts.put(cert.id, cert.vesselId, cert.toMap());
  }

  VesselCertificate? _vesselCertById(String id) {
    for (final c in _vesselCache) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> addVesselCert({
    required String vesselId,
    required String documentName,
    required String issuingAuthority,
    required DateTime issueDate,
    required DateTime expiryDate,
    List<Attachment> attachments = const [],
  }) async {
    await _saveVesselCert(VesselCertificate(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      documentName: documentName,
      issuingAuthority: issuingAuthority,
      issueDate: issueDate,
      expiryDate: expiryDate,
      attachments: attachments,
    ));
  }

  Future<void> updateVesselCert({
    required String id,
    required String documentName,
    required String issuingAuthority,
    required DateTime issueDate,
    required DateTime expiryDate,
  }) async {
    final cert = _vesselCertById(id);
    if (cert == null) return;
    await _saveVesselCert(cert.copyWith(
      documentName: documentName,
      issuingAuthority: issuingAuthority,
      issueDate: issueDate,
      expiryDate: expiryDate,
    ));
  }

  Future<void> addVesselCertAttachment(String id, Attachment attachment) async {
    final cert = _vesselCertById(id);
    if (cert == null) return;
    await _saveVesselCert(
        cert.copyWith(attachments: [...cert.attachments, attachment]));
  }

  Future<void> removeVesselCertAttachment(String id, int index) async {
    final cert = _vesselCertById(id);
    if (cert == null) return;
    final files = [...cert.attachments]..removeAt(index);
    await _saveVesselCert(cert.copyWith(attachments: files));
  }

  Future<void> deleteVesselCert(String id) async {
    _vesselCache.removeWhere((c) => c.id == id);
    notifyListeners();
    await _vesselCerts.remove(id);
  }

  // --- Crew certificates ---

  Future<void> _saveCrewCert(CrewCertificate cert) async {
    final idx = _crewCache.indexWhere((c) => c.id == cert.id);
    if (idx >= 0) {
      _crewCache[idx] = cert;
    } else {
      _crewCache = [..._crewCache, cert];
    }
    notifyListeners();
    await _crewCerts.put(cert.id, cert.vesselId, cert.toMap());
  }

  CrewCertificate? _crewCertById(String id) {
    for (final c in _crewCache) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> addCrewCert({
    required String vesselId,
    required String officerName,
    required String rank,
    required CrewCertType certType,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? photoBase64,
    List<Attachment> attachments = const [],
  }) async {
    await _saveCrewCert(CrewCertificate(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      officerName: officerName,
      rank: rank,
      certType: certType,
      issueDate: issueDate,
      expiryDate: expiryDate,
      photoBase64: photoBase64,
      attachments: attachments,
    ));
  }

  Future<void> updateCrewCert({
    required String id,
    required String officerName,
    required String rank,
    required CrewCertType certType,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? photoBase64,
  }) async {
    final cert = _crewCertById(id);
    if (cert == null) return;
    await _saveCrewCert(cert.copyWith(
      officerName: officerName,
      rank: rank,
      certType: certType,
      issueDate: issueDate,
      expiryDate: expiryDate,
      photoBase64: photoBase64,
    ));
  }

  Future<void> addCrewCertAttachment(String id, Attachment attachment) async {
    final cert = _crewCertById(id);
    if (cert == null) return;
    await _saveCrewCert(
        cert.copyWith(attachments: [...cert.attachments, attachment]));
  }

  Future<void> removeCrewCertAttachment(String id, int index) async {
    final cert = _crewCertById(id);
    if (cert == null) return;
    final files = [...cert.attachments]..removeAt(index);
    await _saveCrewCert(cert.copyWith(attachments: files));
  }

  Future<void> deleteCrewCert(String id) async {
    _crewCache.removeWhere((c) => c.id == id);
    notifyListeners();
    await _crewCerts.remove(id);
  }
}
