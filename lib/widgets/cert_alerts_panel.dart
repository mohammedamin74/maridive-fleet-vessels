import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/crew_certificate.dart';
import '../models/vessel.dart';
import '../models/vessel_certificate.dart';
import '../screens/certification_screen.dart';
import '../theme/app_colors.dart';

/// Red fleet-wide alarm banner: every vessel or crew certificate that is
/// already expired or expires within 30 days. Tapping a row opens the
/// owning vessel's certification module.
class CertAlertsPanel extends StatelessWidget {
  final List<VesselCertificate> vesselCerts;
  final List<CrewCertificate> crewCerts;
  final List<Vessel> vessels;

  const CertAlertsPanel({
    super.key,
    required this.vesselCerts,
    required this.crewCerts,
    required this.vessels,
  });

  int _daysLeft(DateTime expiry) => expiry.difference(DateTime.now()).inDays;

  String _countdown(AppLocalizations t, DateTime expiry) {
    final days = _daysLeft(expiry);
    if (days < 0) return t.certExpired;
    if (days == 0) return t.certExpiresToday;
    return t.certDaysLeft(days);
  }

  /// The header must not claim every listed certificate "expires within 30
  /// days" — some are already past their expiry date and need to say so.
  String _title(AppLocalizations t, int expiredCount, int expiringCount) {
    if (expiredCount == 0) return t.certAlarmTitle(expiringCount);
    if (expiringCount == 0) return t.certAlarmTitleExpired(expiredCount);
    return t.certAlarmTitleMixed(expiredCount, expiringCount);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final rows = <(Vessel, String, DateTime)>[];
    for (final c in vesselCerts) {
      final vessel = vessels.where((v) => v.id == c.vesselId).firstOrNull;
      if (vessel != null) rows.add((vessel, c.documentName, c.expiryDate));
    }
    for (final c in crewCerts) {
      final vessel = vessels.where((v) => v.id == c.vesselId).firstOrNull;
      if (vessel != null) {
        rows.add((vessel, '${c.officerName} — ${c.rank}', c.expiryDate));
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    rows.sort((a, b) => a.$3.compareTo(b.$3));
    final expiredCount = rows.where((r) => _daysLeft(r.$3) < 0).length;
    final expiringCount = rows.length - expiredCount;
    const alarm = AppColors.statusMaintenance;

    return Container(
      decoration: BoxDecoration(
        color: alarm.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alarm.withValues(alpha: 0.35)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: const Icon(Icons.workspace_premium_outlined, color: alarm),
          title: Text(
            _title(t, expiredCount, expiringCount),
            style: const TextStyle(
                color: alarm, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          iconColor: alarm,
          collapsedIconColor: alarm,
          children: rows.map((row) {
            final (vessel, title, expiry) = row;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 8,
                height: 8,
                decoration:
                    const BoxDecoration(color: alarm, shape: BoxShape.circle),
              ),
              title: Text(
                '$title · ${vessel.name}',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _countdown(t, expiry),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: alarm),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => CertificationScreen(vessel: vessel)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
