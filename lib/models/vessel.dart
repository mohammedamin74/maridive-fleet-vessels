import 'tank.dart';

enum VesselStatus { active, standby, port, maintenance }

class Vessel {
  final String id;
  final String name;
  final String type;
  final String imo;
  final String homePort;
  final int crew;
  final VesselStatus status;
  final List<Tank> tanks;

  const Vessel({
    required this.id,
    required this.name,
    required this.type,
    required this.imo,
    required this.homePort,
    required this.crew,
    required this.status,
    required this.tanks,
  });

  List<Tank> tanksOf(TankCategory category) =>
      tanks.where((t) => t.category == category).toList();

  String get statusKey {
    switch (status) {
      case VesselStatus.active:
        return 'active';
      case VesselStatus.standby:
        return 'standby';
      case VesselStatus.port:
        return 'port';
      case VesselStatus.maintenance:
        return 'maintenance';
    }
  }
}
