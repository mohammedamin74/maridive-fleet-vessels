import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/vessel.dart';

/// Stores user edits to otherwise-static vessel fields (operational status
/// and IMO number) keyed by vessel id, and applies them on top of the
/// catalog [Vessel] via [resolve]. This lets a vessel be switched to
/// off-hire, or given an IMO number manually, without mutating the fixed
/// fleet data.
class VesselProfileProvider extends ChangeNotifier {
  final Box box;
  VesselProfileProvider({required this.box});

  Vessel resolve(Vessel v) {
    final raw = box.get(v.id);
    if (raw == null) return v;
    final m = raw as Map;
    final statusName = m['status'] as String?;
    final imo = m['imo'] as String?;
    return v.copyWith(
      status: statusName != null
          ? VesselStatus.values.byName(statusName)
          : null,
      imo: (imo != null && imo.trim().isNotEmpty) ? imo.trim() : null,
    );
  }

  Future<void> setStatus(String vesselId, VesselStatus status) async {
    final m = Map<String, dynamic>.from((box.get(vesselId) as Map?) ?? {});
    m['status'] = status.name;
    await box.put(vesselId, m);
    notifyListeners();
  }

  Future<void> setImo(String vesselId, String imo) async {
    final m = Map<String, dynamic>.from((box.get(vesselId) as Map?) ?? {});
    m['imo'] = imo.trim();
    await box.put(vesselId, m);
    notifyListeners();
  }
}
