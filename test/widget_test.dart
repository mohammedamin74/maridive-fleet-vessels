import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:maridive_fleet_vessels/app.dart';
import 'package:maridive_fleet_vessels/state/app_state.dart';
import 'package:maridive_fleet_vessels/state/tank_data_provider.dart';

void main() {
  late Box settingsBox;
  late Box readingsBox;
  late Box notesBox;

  setUp(() async {
    Hive.init('./.dart_tool/hive_test');
    settingsBox = await Hive.openBox('test_settings_${DateTime.now().microsecondsSinceEpoch}');
    readingsBox = await Hive.openBox('test_readings_${DateTime.now().microsecondsSinceEpoch}');
    notesBox = await Hive.openBox('test_notes_${DateTime.now().microsecondsSinceEpoch}');
  });

  testWidgets('Dashboard shows fleet title and vessel cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState(settingsBox: settingsBox)),
          ChangeNotifierProvider(
            create: (_) => TankDataProvider(readingsBox: readingsBox, notesBox: notesBox),
          ),
        ],
        child: const MaridiveFleetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fleet Dashboard'), findsOneWidget);
    expect(find.textContaining('Maridive'), findsWidgets);
  });
}
