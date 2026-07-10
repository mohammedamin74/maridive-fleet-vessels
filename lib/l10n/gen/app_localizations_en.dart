import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Maridive Fleet Vessels';

  @override
  String get dashboardTitle => 'Fleet Dashboard';

  @override
  String get dashboardSubtitle => 'Offshore Support Vessels · Libya';

  @override
  String get fleetOverview => 'Fleet Overview';

  @override
  String get totalVessels => 'Vessels';

  @override
  String get activeVessels => 'Active';

  @override
  String get inPort => 'In Port';

  @override
  String get underMaintenance => 'Maintenance';

  @override
  String get avgFuelLevel => 'Avg. Fuel';

  @override
  String get statusActive => 'Active';

  @override
  String get statusStandby => 'Standby';

  @override
  String get statusInPort => 'In Port';

  @override
  String get statusMaintenance => 'Maintenance';

  @override
  String get searchVessels => 'Search vessels...';

  @override
  String get noResults => 'No vessels match your search';

  @override
  String get vesselDetails => 'Vessel Details';

  @override
  String get imoNumber => 'IMO Number';

  @override
  String get vesselType => 'Vessel Type';

  @override
  String get homePort => 'Home Port';

  @override
  String get crewOnBoard => 'Crew on Board';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get tankSystems => 'Tank Systems';

  @override
  String get categoryFuelOil => 'Fuel Oil Tanks';

  @override
  String get categoryBrineMud => 'Brine / Mud Tanks';

  @override
  String get categoryLubeHydraulic => 'Lube & Hydraulic Oil';

  @override
  String get categoryOther => 'Other Tanks';

  @override
  String get categorySoundingTables => 'Sounding Tables';

  @override
  String tanksInCategory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanks',
      one: '1 tank',
    );
    return '$_temp0';
  }

  @override
  String get selectTank => 'Select Tank';

  @override
  String get tankLevel => 'Tank Level';

  @override
  String get tankPercent => 'Tank Percent';

  @override
  String get capacity => 'Capacity';

  @override
  String get currentVolume => 'Current Volume';

  @override
  String get pumpCalculator => 'Pump-Out Calculator';

  @override
  String get quantityToPumpOut => 'Quantity to Pump Out';

  @override
  String get stopPumpingAtLevel => 'Stop Pumping at Level';

  @override
  String get remainingAfterPumping => 'Remaining After Pumping';

  @override
  String get calculate => 'Calculate';

  @override
  String get reset => 'Reset';

  @override
  String get enterAValue => 'Enter a value';

  @override
  String soundingTableTitle(String tank) {
    return '$tank — Sounding Table';
  }

  @override
  String get levelCm => 'Level (cm)';

  @override
  String get volumeM3 => 'Volume (m³)';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get about => 'About';

  @override
  String get aboutBody => 'Maridive Fleet Vessels helps crews and shore staff monitor fuel, mud, lube and hydraulic tank levels across the fleet of offshore support vessels operating in Libya.';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get gallons => 'IG';

  @override
  String get cubicMeters => 'm³';

  @override
  String get percent => '%';

  @override
  String get updateLevel => 'Update Current Level';

  @override
  String get newReading => 'New Reading';

  @override
  String get saveReading => 'Save';

  @override
  String get noReadingsYet => 'No readings yet';

  @override
  String get viewHistory => 'View Reading History';

  @override
  String get readingHistory => 'Reading History';

  @override
  String get noHistory => 'No readings recorded yet';

  @override
  String get criticalLevel => 'Critical';

  @override
  String get warningLevel => 'Warning';

  @override
  String get noData => 'No Data';

  @override
  String alertsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanks need attention',
      one: '1 tank needs attention',
    );
    return '$_temp0';
  }

  @override
  String get logbook => 'Logbook';

  @override
  String get addNoteHint => 'Add a note...';

  @override
  String get noNotes => 'No log entries yet';

  @override
  String get exportReport => 'Export Report';
}
