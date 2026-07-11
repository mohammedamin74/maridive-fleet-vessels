import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'state/app_state.dart';
import 'state/certification_provider.dart';
import 'state/daily_tasks_provider.dart';
import 'state/maintenance_provider.dart';
import 'state/port_call_provider.dart';
import 'state/tank_data_provider.dart';
import 'state/urgent_notification_provider.dart';
import 'state/vessel_profile_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final settingsBox = await Hive.openBox('settings');
  final readingsBox = await Hive.openBox('tank_readings');
  final notesBox = await Hive.openBox('vessel_notes');
  final defectsBox = await Hive.openBox('defects');
  final requisitionsBox = await Hive.openBox('requisitions');
  final portCallsBox = await Hive.openBox('port_calls');
  final vesselCertsBox = await Hive.openBox('vessel_certs');
  final crewCertsBox = await Hive.openBox('crew_certs');
  final urgentNotificationsBox = await Hive.openBox('urgent_notifications');
  final dailyTasksBox = await Hive.openBox('daily_tasks');
  final maintenanceBox = await Hive.openBox('maintenance_records');
  final vesselProfilesBox = await Hive.openBox('vessel_profiles');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AppState(settingsBox: settingsBox)),
        ChangeNotifierProvider(
          create: (_) => TankDataProvider(
            readingsBox: readingsBox,
            notesBox: notesBox,
            defectsBox: defectsBox,
            requisitionsBox: requisitionsBox,
          ),
        ),
        ChangeNotifierProvider(
            create: (_) => PortCallProvider(box: portCallsBox)),
        ChangeNotifierProvider(
          create: (_) => CertificationProvider(
              vesselCertsBox: vesselCertsBox, crewCertsBox: crewCertsBox),
        ),
        ChangeNotifierProvider(
            create: (_) =>
                UrgentNotificationProvider(box: urgentNotificationsBox)),
        ChangeNotifierProvider(
            create: (_) => DailyTasksProvider(box: dailyTasksBox)),
        ChangeNotifierProvider(
            create: (_) => MaintenanceProvider(box: maintenanceBox)),
        ChangeNotifierProvider(
            create: (_) => VesselProfileProvider(box: vesselProfilesBox)),
      ],
      child: const MaridiveFleetApp(),
    ),
  );
}
