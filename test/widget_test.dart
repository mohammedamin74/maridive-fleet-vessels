import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:maridive_fleet_vessels/app.dart';
import 'package:maridive_fleet_vessels/state/app_state.dart';
import 'package:maridive_fleet_vessels/state/certification_provider.dart';
import 'package:maridive_fleet_vessels/state/daily_tasks_provider.dart';
import 'package:maridive_fleet_vessels/state/port_call_provider.dart';
import 'package:maridive_fleet_vessels/state/tank_data_provider.dart';
import 'package:maridive_fleet_vessels/state/urgent_notification_provider.dart';

void main() {
  late Box settingsBox;
  late Box readingsBox;
  late Box notesBox;
  late Box defectsBox;
  late Box requisitionsBox;
  late Box portCallsBox;
  late Box vesselCertsBox;
  late Box crewCertsBox;
  late Box urgentNotificationsBox;
  late Box dailyTasksBox;

  setUp(() async {
    Hive.init('./.dart_tool/hive_test');
    final ts = DateTime.now().microsecondsSinceEpoch;
    settingsBox = await Hive.openBox('test_settings_$ts');
    readingsBox = await Hive.openBox('test_readings_$ts');
    notesBox = await Hive.openBox('test_notes_$ts');
    defectsBox = await Hive.openBox('test_defects_$ts');
    requisitionsBox = await Hive.openBox('test_requisitions_$ts');
    portCallsBox = await Hive.openBox('test_port_calls_$ts');
    vesselCertsBox = await Hive.openBox('test_vessel_certs_$ts');
    crewCertsBox = await Hive.openBox('test_crew_certs_$ts');
    urgentNotificationsBox = await Hive.openBox('test_urgent_notifications_$ts');
    dailyTasksBox = await Hive.openBox('test_daily_tasks_$ts');
  });

  testWidgets('Dashboard shows fleet title and vessel cards', (WidgetTester tester) async {
    await tester.pumpWidget(
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
          ChangeNotifierProvider(create: (_) => PortCallProvider(box: portCallsBox)),
          ChangeNotifierProvider(
            create: (_) => CertificationProvider(vesselCertsBox: vesselCertsBox, crewCertsBox: crewCertsBox),
          ),
          ChangeNotifierProvider(create: (_) => UrgentNotificationProvider(box: urgentNotificationsBox)),
          ChangeNotifierProvider(create: (_) => DailyTasksProvider(box: dailyTasksBox)),
        ],
        child: const MaridiveFleetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fleet Dashboard'), findsOneWidget);
    expect(find.textContaining('Maridive'), findsWidgets);
  });
}
