import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/supabase_config.dart';
import 'state/app_state.dart';
import 'state/auth_provider.dart';
import 'state/certification_provider.dart';
import 'state/crew_provider.dart';
import 'state/daily_tasks_provider.dart';
import 'state/maintenance_provider.dart';
import 'state/port_call_provider.dart';
import 'state/port_requirement_provider.dart';
import 'state/tank_data_provider.dart';
import 'state/urgent_notification_provider.dart';
import 'state/vessel_profile_provider.dart';
import 'state/vessel_spec_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  await Hive.initFlutter();

  // All fleet data (readings, notes, defects, requisitions, port calls,
  // certificates, alerts, daily tasks, maintenance, vessel status/IMO overrides
  // and now vessel specifications + their files) is cloud-backed via CloudStore
  // and Supabase Storage. The only remaining local box is `settings`, which
  // holds device-local prefs (language, theme).
  final settingsBox = await Hive.openBox('settings');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AppState(settingsBox: settingsBox)),
        ChangeNotifierProvider(create: (_) => TankDataProvider()),
        ChangeNotifierProvider(create: (_) => PortCallProvider()),
        ChangeNotifierProvider(create: (_) => PortRequirementProvider()),
        ChangeNotifierProvider(create: (_) => CertificationProvider()),
        ChangeNotifierProvider(create: (_) => CrewProvider()),
        ChangeNotifierProvider(create: (_) => UrgentNotificationProvider()),
        ChangeNotifierProvider(create: (_) => DailyTasksProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => VesselProfileProvider()),
        ChangeNotifierProvider(create: (_) => VesselSpecProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MaridiveFleetApp(),
    ),
  );
}
