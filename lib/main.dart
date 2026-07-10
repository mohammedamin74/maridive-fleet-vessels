import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'state/app_state.dart';
import 'state/tank_data_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final settingsBox = await Hive.openBox('settings');
  final readingsBox = await Hive.openBox('tank_readings');
  final notesBox = await Hive.openBox('vessel_notes');
  final defectsBox = await Hive.openBox('defects');
  final requisitionsBox = await Hive.openBox('requisitions');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(settingsBox: settingsBox)),
        ChangeNotifierProvider(
          create: (_) => TankDataProvider(
            readingsBox: readingsBox,
            notesBox: notesBox,
            defectsBox: defectsBox,
            requisitionsBox: requisitionsBox,
          ),
        ),
      ],
      child: const MaridiveFleetApp(),
    ),
  );
}
