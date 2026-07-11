import 'tank.dart';

enum VesselStatus { active, standby, port, maintenance, offHire }

class Vessel {
  final String id;
  final String name;
  final String type;
  final String imo;
  final String homePort;
  final String workingPort;
  final int crew;
  final VesselStatus status;
  final String photoAsset;
  final List<Tank> tanks;

  const Vessel({
    required this.id,
    required this.name,
    required this.type,
    required this.imo,
    required this.homePort,
    this.workingPort = '',
    required this.crew,
    required this.status,
    this.photoAsset = '',
    required this.tanks,
  });

  Vessel copyWith({
    String? imo,
    String? homePort,
    String? workingPort,
    VesselStatus? status,
  }) =>
      Vessel(
        id: id,
        name: name,
        type: type,
        imo: imo ?? this.imo,
        homePort: homePort ?? this.homePort,
        workingPort: workingPort ?? this.workingPort,
        crew: crew,
        status: status ?? this.status,
        photoAsset: photoAsset,
        tanks: tanks,
      );

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
      case VesselStatus.offHire:
        return 'offHire';
    }
  }
}
