import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Maridive Fleet Vessels'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offshore Support Vessels · Libya'**
  String get dashboardSubtitle;

  /// No description provided for @fleetOverview.
  ///
  /// In en, this message translates to:
  /// **'Fleet Overview'**
  String get fleetOverview;

  /// No description provided for @totalVessels.
  ///
  /// In en, this message translates to:
  /// **'Vessels'**
  String get totalVessels;

  /// No description provided for @activeVessels.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeVessels;

  /// No description provided for @inPort.
  ///
  /// In en, this message translates to:
  /// **'In Port'**
  String get inPort;

  /// No description provided for @underMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get underMaintenance;

  /// No description provided for @avgFuelLevel.
  ///
  /// In en, this message translates to:
  /// **'Avg. Fuel'**
  String get avgFuelLevel;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusStandby.
  ///
  /// In en, this message translates to:
  /// **'Standby'**
  String get statusStandby;

  /// No description provided for @statusInPort.
  ///
  /// In en, this message translates to:
  /// **'In Port'**
  String get statusInPort;

  /// No description provided for @statusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get statusMaintenance;

  /// No description provided for @searchVessels.
  ///
  /// In en, this message translates to:
  /// **'Search vessels...'**
  String get searchVessels;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No vessels match your search'**
  String get noResults;

  /// No description provided for @vesselDetails.
  ///
  /// In en, this message translates to:
  /// **'Vessel Details'**
  String get vesselDetails;

  /// No description provided for @imoNumber.
  ///
  /// In en, this message translates to:
  /// **'IMO Number'**
  String get imoNumber;

  /// No description provided for @vesselType.
  ///
  /// In en, this message translates to:
  /// **'Vessel Type'**
  String get vesselType;

  /// No description provided for @homePort.
  ///
  /// In en, this message translates to:
  /// **'Home Port'**
  String get homePort;

  /// No description provided for @crewOnBoard.
  ///
  /// In en, this message translates to:
  /// **'Crew on Board'**
  String get crewOnBoard;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @tankSystems.
  ///
  /// In en, this message translates to:
  /// **'Tank Systems'**
  String get tankSystems;

  /// No description provided for @categoryFuelOil.
  ///
  /// In en, this message translates to:
  /// **'Fuel Oil Tanks'**
  String get categoryFuelOil;

  /// No description provided for @categoryBrineMud.
  ///
  /// In en, this message translates to:
  /// **'Brine / Mud Tanks'**
  String get categoryBrineMud;

  /// No description provided for @categoryLubeHydraulic.
  ///
  /// In en, this message translates to:
  /// **'Lube & Hydraulic Oil'**
  String get categoryLubeHydraulic;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other Tanks'**
  String get categoryOther;

  /// No description provided for @categorySoundingTables.
  ///
  /// In en, this message translates to:
  /// **'Sounding Tables'**
  String get categorySoundingTables;

  /// No description provided for @tanksInCategory.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 tank} other{{count} tanks}}'**
  String tanksInCategory(int count);

  /// No description provided for @selectTank.
  ///
  /// In en, this message translates to:
  /// **'Select Tank'**
  String get selectTank;

  /// No description provided for @tankLevel.
  ///
  /// In en, this message translates to:
  /// **'Tank Level'**
  String get tankLevel;

  /// No description provided for @tankPercent.
  ///
  /// In en, this message translates to:
  /// **'Tank Percent'**
  String get tankPercent;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @currentVolume.
  ///
  /// In en, this message translates to:
  /// **'Current Volume'**
  String get currentVolume;

  /// No description provided for @pumpCalculator.
  ///
  /// In en, this message translates to:
  /// **'Pump-Out Calculator'**
  String get pumpCalculator;

  /// No description provided for @quantityToPumpOut.
  ///
  /// In en, this message translates to:
  /// **'Quantity to Pump Out'**
  String get quantityToPumpOut;

  /// No description provided for @stopPumpingAtLevel.
  ///
  /// In en, this message translates to:
  /// **'Stop Pumping at Level'**
  String get stopPumpingAtLevel;

  /// No description provided for @remainingAfterPumping.
  ///
  /// In en, this message translates to:
  /// **'Remaining After Pumping'**
  String get remainingAfterPumping;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @enterAValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get enterAValue;

  /// No description provided for @soundingTableTitle.
  ///
  /// In en, this message translates to:
  /// **'{tank} — Sounding Table'**
  String soundingTableTitle(String tank);

  /// No description provided for @levelCm.
  ///
  /// In en, this message translates to:
  /// **'Level (cm)'**
  String get levelCm;

  /// No description provided for @volumeM3.
  ///
  /// In en, this message translates to:
  /// **'Volume (m³)'**
  String get volumeM3;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Maridive Fleet Vessels helps crews and shore staff monitor fuel, mud, lube and hydraulic tank levels across the fleet of offshore support vessels operating in Libya.'**
  String get aboutBody;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @gallons.
  ///
  /// In en, this message translates to:
  /// **'IG'**
  String get gallons;

  /// No description provided for @cubicMeters.
  ///
  /// In en, this message translates to:
  /// **'m³'**
  String get cubicMeters;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get percent;

  /// No description provided for @updateLevel.
  ///
  /// In en, this message translates to:
  /// **'Update Current Level'**
  String get updateLevel;

  /// No description provided for @newReading.
  ///
  /// In en, this message translates to:
  /// **'New Reading'**
  String get newReading;

  /// No description provided for @saveReading.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveReading;

  /// No description provided for @noReadingsYet.
  ///
  /// In en, this message translates to:
  /// **'No readings yet'**
  String get noReadingsYet;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View Reading History'**
  String get viewHistory;

  /// No description provided for @readingHistory.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get readingHistory;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No readings recorded yet'**
  String get noHistory;

  /// No description provided for @criticalLevel.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get criticalLevel;

  /// No description provided for @warningLevel.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warningLevel;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 tank needs attention} other{{count} tanks need attention}}'**
  String alertsTitle(int count);

  /// No description provided for @logbook.
  ///
  /// In en, this message translates to:
  /// **'Logbook'**
  String get logbook;

  /// No description provided for @addNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addNoteHint;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No log entries yet'**
  String get noNotes;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @vesselOperations.
  ///
  /// In en, this message translates to:
  /// **'Vessel Operations'**
  String get vesselOperations;

  /// No description provided for @viewEntries.
  ///
  /// In en, this message translates to:
  /// **'View entries'**
  String get viewEntries;

  /// No description provided for @tankStatusPdf.
  ///
  /// In en, this message translates to:
  /// **'Tank status PDF'**
  String get tankStatusPdf;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @openCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 open} other{{count} open}}'**
  String openCount(int count);

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 pending} other{{count} pending}}'**
  String pendingCount(int count);

  /// No description provided for @defects.
  ///
  /// In en, this message translates to:
  /// **'Defects'**
  String get defects;

  /// No description provided for @addDefect.
  ///
  /// In en, this message translates to:
  /// **'Report Defect'**
  String get addDefect;

  /// No description provided for @defectTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get defectTitleLabel;

  /// No description provided for @defectDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get defectDescriptionLabel;

  /// No description provided for @severityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityLabel;

  /// No description provided for @severityMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get severityMinor;

  /// No description provided for @severityMajor.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get severityMajor;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @statusOpenDefect.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpenDefect;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusClosedDefect.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosedDefect;

  /// No description provided for @noDefects.
  ///
  /// In en, this message translates to:
  /// **'No defects reported'**
  String get noDefects;

  /// No description provided for @reportedOn.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get reportedOn;

  /// No description provided for @markInProgress.
  ///
  /// In en, this message translates to:
  /// **'Mark In Progress'**
  String get markInProgress;

  /// No description provided for @markClosed.
  ///
  /// In en, this message translates to:
  /// **'Mark Closed'**
  String get markClosed;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// No description provided for @criticalDefectsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 critical defect} other{{count} critical defects}}'**
  String criticalDefectsTitle(int count);

  /// No description provided for @requisitions.
  ///
  /// In en, this message translates to:
  /// **'Requisitions'**
  String get requisitions;

  /// No description provided for @addRequisition.
  ///
  /// In en, this message translates to:
  /// **'New Requisition'**
  String get addRequisition;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemNameLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @reqStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reqStatusPending;

  /// No description provided for @reqStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get reqStatusApproved;

  /// No description provided for @reqStatusOrdered.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get reqStatusOrdered;

  /// No description provided for @reqStatusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get reqStatusReceived;

  /// No description provided for @reqStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get reqStatusRejected;

  /// No description provided for @noRequisitions.
  ///
  /// In en, this message translates to:
  /// **'No requisitions yet'**
  String get noRequisitions;

  /// No description provided for @requestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requestedOn;

  /// No description provided for @markApproved.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get markApproved;

  /// No description provided for @markOrdered.
  ///
  /// In en, this message translates to:
  /// **'Mark Ordered'**
  String get markOrdered;

  /// No description provided for @markReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark Received'**
  String get markReceived;

  /// No description provided for @markRejected.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get markRejected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
