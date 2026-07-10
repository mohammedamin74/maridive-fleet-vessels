import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/tank.dart';
import '../models/tank_reading.dart';
import '../models/vessel.dart';
import '../models/vessel_note.dart';
import 'alert_thresholds.dart';

class TankAlert {
  final Vessel vessel;
  final Tank tank;
  final double percent;
  final TankLevelStatus status;

  const TankAlert({
    required this.vessel,
    required this.tank,
    required this.percent,
    required this.status,
  });
}

/// Wraps the Hive-backed readings/notes boxes and derives live tank levels.
/// Tank current levels are NOT stored on the static [Tank] catalog — they
/// are always the most recent [TankReading] for that vessel+tank pair, so
/// there is one source of truth for "current level" and "history".
class TankDataProvider extends ChangeNotifier {
  final Box readingsBox;
  final Box notesBox;

  TankDataProvider({required this.readingsBox, required this.notesBox});

  List<TankReading> readingsFor(String vesselId, String tankId) {
    final list = readingsBox.values
        .map((e) => TankReading.fromMap(e as Map))
        .where((r) => r.vesselId == vesselId && r.tankId == tankId)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  bool hasReading(String vesselId, String tankId) =>
      readingsBox.values.any((e) {
        final m = e as Map;
        return m['vesselId'] == vesselId && m['tankId'] == tankId;
      });

  double currentLevel(String vesselId, String tankId) {
    final readings = readingsFor(vesselId, tankId);
    return readings.isEmpty ? 0 : readings.first.levelM3;
  }

  double percentFor(String vesselId, Tank tank) {
    final current = currentLevel(vesselId, tank.id);
    if (tank.capacityM3 <= 0) return 0;
    return (current / tank.capacityM3).clamp(0, 1);
  }

  TankLevelStatus statusFor(String vesselId, Tank tank) {
    return levelStatusFor(
      hasReading: hasReading(vesselId, tank.id),
      percent: percentFor(vesselId, tank),
    );
  }

  Future<void> addReading(String vesselId, String tankId, double levelM3) async {
    final reading = TankReading(
      vesselId: vesselId,
      tankId: tankId,
      levelM3: levelM3,
      timestamp: DateTime.now(),
    );
    await readingsBox.put(reading.storageKey, reading.toMap());
    notifyListeners();
  }

  double avgFuelPercent(Vessel vessel) {
    final fuelTanks = vessel.tanksOf(TankCategory.fuelOil);
    if (fuelTanks.isEmpty) return 0;
    final total = fuelTanks.fold<double>(0, (sum, t) => sum + percentFor(vessel.id, t));
    return total / fuelTanks.length;
  }

  List<TankAlert> alertsFor(List<Vessel> vessels) {
    final alerts = <TankAlert>[];
    for (final vessel in vessels) {
      for (final tank in vessel.tanks) {
        final status = statusFor(vessel.id, tank);
        if (status == TankLevelStatus.critical || status == TankLevelStatus.warning) {
          alerts.add(TankAlert(
            vessel: vessel,
            tank: tank,
            percent: percentFor(vessel.id, tank),
            status: status,
          ));
        }
      }
    }
    alerts.sort((a, b) => a.percent.compareTo(b.percent));
    return alerts;
  }

  List<VesselNote> notesFor(String vesselId) {
    final list = notesBox.values
        .map((e) => VesselNote.fromMap(e as Map))
        .where((n) => n.vesselId == vesselId)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> addNote(String vesselId, String text) async {
    final note = VesselNote(
      id: '${vesselId}_${DateTime.now().microsecondsSinceEpoch}',
      vesselId: vesselId,
      text: text,
      timestamp: DateTime.now(),
    );
    await notesBox.put(note.id, note.toMap());
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    await notesBox.delete(noteId);
    notifyListeners();
  }
}
