import '../models/crew_certificate.dart';
import '../models/defect.dart';
import '../models/module_item.dart';
import '../models/requisition.dart';
import '../models/vessel_certificate.dart';
import '../widgets/ai_fill.dart';

/// One field where the uploaded document and the stored record disagree.
class FieldDiff {
  /// Localization key suffix for the field label (e.g. 'expiryDate').
  final String field;
  final String existingValue;
  final String extractedValue;

  const FieldDiff({
    required this.field,
    required this.existingValue,
    required this.extractedValue,
  });
}

/// An extracted item that appears to describe a record the fleet already has.
class DiscrepancyMatch {
  /// What the existing record is called, for showing the user which one.
  final String existingLabel;
  final String existingId;
  final List<FieldDiff> diffs;

  const DiscrepancyMatch({
    required this.existingLabel,
    required this.existingId,
    required this.diffs,
  });

  /// True when the document matches a record but says something different.
  bool get hasDifferences => diffs.isNotEmpty;
}

/// Compares an AI-extracted ingestion item against the records the fleet
/// already holds, so a re-uploaded certificate is recognized as an update to
/// a known record rather than silently creating a duplicate.
///
/// Deliberately advisory: this only reports. Nothing is merged, overwritten
/// or auto-accepted — the superintendent decides, exactly as the rest of the
/// AI pipeline requires.
class DiscrepancyService {
  const DiscrepancyService._();

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  /// Two document names refer to the same certificate when one contains the
  /// other after normalization — real sheets abbreviate ("ISSC" vs
  /// "International Ship Security Certificate (ISSC)").
  static bool _sameSubject(String a, String b) {
    final x = _norm(a), y = _norm(b);
    if (x.isEmpty || y.isEmpty) return false;
    return x == y || x.contains(y) || y.contains(x);
  }

  static String _date(DateTime? d) =>
      d == null ? '' : d.toIso8601String().split('T').first;

  static void _add(List<FieldDiff> out, String field, String existing,
      String extracted) {
    // An empty extracted value means the document didn't state it, which is
    // not a disagreement — only a stated, different value counts.
    if (extracted.trim().isEmpty) return;
    if (_norm(existing) == _norm(extracted)) return;
    out.add(FieldDiff(
        field: field, existingValue: existing, extractedValue: extracted));
  }

  /// Vessel certificates: matched by document name within the same vessel.
  static DiscrepancyMatch? forVesselCert(
      ModuleItem item, List<VesselCertificate> existing) {
    final name = aiStr(item.fields, 'documentName');
    if (name.trim().isEmpty) return null;
    for (final c in existing) {
      if (!_sameSubject(c.documentName, name)) continue;
      final diffs = <FieldDiff>[];
      _add(diffs, 'expiryDate', _date(c.expiryDate),
          _date(aiDate(item.fields, 'expiryDate')));
      _add(diffs, 'issueDate', _date(c.issueDate),
          _date(aiDate(item.fields, 'issueDate')));
      _add(diffs, 'issuingAuthority', c.issuingAuthority,
          aiStr(item.fields, 'issuingAuthority'));
      return DiscrepancyMatch(
          existingLabel: c.documentName, existingId: c.id, diffs: diffs);
    }
    return null;
  }

  /// Crew certificates: matched by officer + certificate type.
  static DiscrepancyMatch? forCrewCert(
      ModuleItem item, List<CrewCertificate> existing) {
    final officer = aiStr(item.fields, 'officerName');
    if (officer.trim().isEmpty) return null;
    final type = aiStr(item.fields, 'certType');
    for (final c in existing) {
      if (!_sameSubject(c.officerName, officer)) continue;
      if (type.isNotEmpty && !_sameSubject(c.certType.name, type)) continue;
      final diffs = <FieldDiff>[];
      _add(diffs, 'expiryDate', _date(c.expiryDate),
          _date(aiDate(item.fields, 'expiryDate')));
      _add(diffs, 'issueDate', _date(c.issueDate),
          _date(aiDate(item.fields, 'issueDate')));
      _add(diffs, 'rank', c.rank, aiStr(item.fields, 'rank'));
      return DiscrepancyMatch(
          existingLabel: '${c.officerName} — ${c.certType.name.toUpperCase()}',
          existingId: c.id,
          diffs: diffs);
    }
    return null;
  }

  /// Requisitions: matched by PR number when present, otherwise item name.
  static DiscrepancyMatch? forRequisition(
      ModuleItem item, List<Requisition> existing) {
    final pr = aiStr(item.fields, 'requisitionNumber');
    final itemName = aiStr(item.fields, 'itemName');
    if (pr.trim().isEmpty && itemName.trim().isEmpty) return null;
    for (final r in existing) {
      final matched = pr.trim().isNotEmpty
          ? _sameSubject(r.requisitionNumber, pr)
          : _sameSubject(r.itemName, itemName);
      if (!matched) continue;
      final diffs = <FieldDiff>[];
      _add(diffs, 'itemName', r.itemName, itemName);
      _add(diffs, 'quantity', _num(r.quantity),
          _num(aiNum(item.fields, 'quantity')));
      _add(diffs, 'unitPrice', _num(r.unitPrice),
          _num(aiNum(item.fields, 'unitPrice')));
      return DiscrepancyMatch(
          existingLabel: r.requisitionNumber.isEmpty
              ? r.itemName
              : '${r.requisitionNumber} — ${r.itemName}',
          existingId: r.id,
          diffs: diffs);
    }
    return null;
  }

  /// Defects: matched by title within the vessel. Reported so a re-uploaded
  /// defect list doesn't quietly double every open item.
  static DiscrepancyMatch? forDefect(
      ModuleItem item, List<Defect> existing) {
    final title = aiStr(item.fields, 'title');
    if (title.trim().isEmpty) return null;
    for (final d in existing) {
      if (!_sameSubject(d.title, title)) continue;
      final diffs = <FieldDiff>[];
      _add(diffs, 'priority', d.priority.name,
          aiStr(item.fields, 'priority'));
      _add(diffs, 'status', d.status.name, aiStr(item.fields, 'status'));
      return DiscrepancyMatch(
          existingLabel: d.title, existingId: d.id, diffs: diffs);
    }
    return null;
  }

  static String _num(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  }
}
