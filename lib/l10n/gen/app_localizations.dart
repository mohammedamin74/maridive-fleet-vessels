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

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @fleetLabel.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get fleetLabel;

  /// No description provided for @statusOffHire.
  ///
  /// In en, this message translates to:
  /// **'Off-hire'**
  String get statusOffHire;

  /// No description provided for @workingPort.
  ///
  /// In en, this message translates to:
  /// **'Working Port'**
  String get workingPort;

  /// No description provided for @editVessel.
  ///
  /// In en, this message translates to:
  /// **'Edit Vessel'**
  String get editVessel;

  /// No description provided for @vesselStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get vesselStatusLabel;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @addMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Add Maintenance'**
  String get addMaintenance;

  /// No description provided for @noMaintenance.
  ///
  /// In en, this message translates to:
  /// **'No maintenance records'**
  String get noMaintenance;

  /// No description provided for @maintenanceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get maintenanceTitleLabel;

  /// No description provided for @maintenanceDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get maintenanceDescLabel;

  /// No description provided for @performedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Performed By'**
  String get performedByLabel;

  /// No description provided for @maintenanceDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get maintenanceDueLabel;

  /// No description provided for @maintStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get maintStatusPlanned;

  /// No description provided for @maintStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get maintStatusInProgress;

  /// No description provided for @maintStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get maintStatusCompleted;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @addSpec.
  ///
  /// In en, this message translates to:
  /// **'Add Specification'**
  String get addSpec;

  /// No description provided for @noSpecs.
  ///
  /// In en, this message translates to:
  /// **'No specification files'**
  String get noSpecs;

  /// No description provided for @specTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Document Title'**
  String get specTitleLabel;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInPrompt;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or password'**
  String get invalidCredentials;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server — check your connection and try again'**
  String get networkError;

  /// No description provided for @offlineAuthNote.
  ///
  /// In en, this message translates to:
  /// **'Shared fleet account — sign in with your username.'**
  String get offlineAuthNote;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminRole;

  /// No description provided for @userRole.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userRole;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator access'**
  String get makeAdmin;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @userExists.
  ///
  /// In en, this message translates to:
  /// **'That username already exists'**
  String get userExists;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordChanged;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get userUpdated;

  /// No description provided for @keepCurrentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the current password'**
  String get keepCurrentPasswordHint;

  /// No description provided for @fieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Username and password are required'**
  String get fieldsRequired;

  /// No description provided for @noUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No users yet'**
  String get noUsersYet;

  /// No description provided for @adminOnlyAction.
  ///
  /// In en, this message translates to:
  /// **'Administrator access required'**
  String get adminOnlyAction;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed — check your connection and try again'**
  String get actionFailed;

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No files} one{1 file} other{{count} files}}'**
  String filesCount(int count);

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

  /// No description provided for @tankHistoryChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tank level history chart, currently {percent}% of capacity'**
  String tankHistoryChartSemantics(int percent);

  /// No description provided for @chartEntriesSemantics.
  ///
  /// In en, this message translates to:
  /// **'Chart: {entries}'**
  String chartEntriesSemantics(String entries);

  /// No description provided for @tankLevelSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tank level'**
  String get tankLevelSemantics;

  /// No description provided for @navFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get navFleet;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

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

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

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

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @tankLabel.
  ///
  /// In en, this message translates to:
  /// **'Tank'**
  String get tankLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// No description provided for @selectSections.
  ///
  /// In en, this message translates to:
  /// **'Select sections'**
  String get selectSections;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export format'**
  String get exportFormat;

  /// No description provided for @exportFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get exportFormatPdf;

  /// No description provided for @exportFormatCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get exportFormatCsv;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get generateReport;

  /// No description provided for @reviewReport.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewReport;

  /// No description provided for @reportNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get reportNoEntries;

  /// No description provided for @generatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get generatedAtLabel;

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

  /// No description provided for @bulkImport.
  ///
  /// In en, this message translates to:
  /// **'Bulk Import'**
  String get bulkImport;

  /// No description provided for @bulkImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-scan multiple files at once'**
  String get bulkImportSubtitle;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get addFiles;

  /// No description provided for @bulkImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add files to scan and route them to the right module automatically.'**
  String get bulkImportEmpty;

  /// No description provided for @bulkImportErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get bulkImportErrors;

  /// No description provided for @bulkImportFilesTotal.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get bulkImportFilesTotal;

  /// No description provided for @bulkImportFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get bulkImportFilesFailed;

  /// No description provided for @bulkImportDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get bulkImportDuplicates;

  /// No description provided for @bulkImportUnclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get bulkImportUnclassified;

  /// No description provided for @bulkImportAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get bulkImportAccept;

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

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editRequisition.
  ///
  /// In en, this message translates to:
  /// **'Edit Requisition'**
  String get editRequisition;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{item}\" will be permanently deleted. This can\'t be undone.'**
  String confirmDeleteMessage(String item);

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

  /// No description provided for @editDefect.
  ///
  /// In en, this message translates to:
  /// **'Edit Defect'**
  String get editDefect;

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

  /// No description provided for @pendingSyncBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String pendingSyncBanner(int count);

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

  /// No description provided for @analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analyticsDashboard;

  /// No description provided for @allVessels.
  ///
  /// In en, this message translates to:
  /// **'All Vessels'**
  String get allVessels;

  /// No description provided for @totalDefects.
  ///
  /// In en, this message translates to:
  /// **'Total Defects'**
  String get totalDefects;

  /// No description provided for @openDefectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open Defects'**
  String get openDefectsLabel;

  /// No description provided for @totalRequisitions.
  ///
  /// In en, this message translates to:
  /// **'Total Requisitions'**
  String get totalRequisitions;

  /// No description provided for @pendingRequisitionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending Requisitions'**
  String get pendingRequisitionsLabel;

  /// No description provided for @defectsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Defects by Status'**
  String get defectsByStatus;

  /// No description provided for @defectsByPriority.
  ///
  /// In en, this message translates to:
  /// **'Defects by Priority'**
  String get defectsByPriority;

  /// No description provided for @requisitionsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Requisitions by Status'**
  String get requisitionsByStatus;

  /// No description provided for @requisitionsByDepartment.
  ///
  /// In en, this message translates to:
  /// **'Requisitions by Department'**
  String get requisitionsByDepartment;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @locationEngineRoom.
  ///
  /// In en, this message translates to:
  /// **'Engine Room'**
  String get locationEngineRoom;

  /// No description provided for @locationDeck.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get locationDeck;

  /// No description provided for @locationBridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get locationBridge;

  /// No description provided for @locationAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get locationAccommodation;

  /// No description provided for @locationGalley.
  ///
  /// In en, this message translates to:
  /// **'Galley'**
  String get locationGalley;

  /// No description provided for @locationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get locationOther;

  /// No description provided for @assignedOfficerLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned Officer'**
  String get assignedOfficerLabel;

  /// No description provided for @requiredSparePartsLabel.
  ///
  /// In en, this message translates to:
  /// **'Required Spare Parts'**
  String get requiredSparePartsLabel;

  /// No description provided for @actionTakenLabel.
  ///
  /// In en, this message translates to:
  /// **'Action Taken'**
  String get actionTakenLabel;

  /// No description provided for @partNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Part Number'**
  String get partNumberLabel;

  /// No description provided for @oemLabel.
  ///
  /// In en, this message translates to:
  /// **'OEM / Manufacturer'**
  String get oemLabel;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity in Stock'**
  String get stockLabel;

  /// No description provided for @unitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPriceLabel;

  /// No description provided for @departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// No description provided for @departmentEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get departmentEngine;

  /// No description provided for @departmentDeck.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get departmentDeck;

  /// No description provided for @departmentSteward.
  ///
  /// In en, this message translates to:
  /// **'Steward'**
  String get departmentSteward;

  /// No description provided for @requiredDeliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Required Delivery Date'**
  String get requiredDeliveryLabel;

  /// No description provided for @reqStatusHod.
  ///
  /// In en, this message translates to:
  /// **'HOD Approval'**
  String get reqStatusHod;

  /// No description provided for @reqStatusTechSup.
  ///
  /// In en, this message translates to:
  /// **'Technical Superintendent Approval'**
  String get reqStatusTechSup;

  /// No description provided for @markHodApproval.
  ///
  /// In en, this message translates to:
  /// **'Mark HOD Approved'**
  String get markHodApproval;

  /// No description provided for @markTechSupApproval.
  ///
  /// In en, this message translates to:
  /// **'Mark Tech. Sup. Approved'**
  String get markTechSupApproval;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperatureLabel;

  /// No description provided for @lastSounding.
  ///
  /// In en, this message translates to:
  /// **'Last reading'**
  String get lastSounding;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @soundingHistory24h.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get soundingHistory24h;

  /// No description provided for @overfillCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical (Overfill)'**
  String get overfillCritical;

  /// No description provided for @overfillWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning (Overfill)'**
  String get overfillWarning;

  /// No description provided for @portCalls.
  ///
  /// In en, this message translates to:
  /// **'Port Calls'**
  String get portCalls;

  /// No description provided for @noPortCalls.
  ///
  /// In en, this message translates to:
  /// **'No port calls scheduled'**
  String get noPortCalls;

  /// No description provided for @addPortCall.
  ///
  /// In en, this message translates to:
  /// **'Add Port Call'**
  String get addPortCall;

  /// No description provided for @portNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Port Name'**
  String get portNameLabel;

  /// No description provided for @arrivalEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrival ETA'**
  String get arrivalEtaLabel;

  /// No description provided for @pilotBoardingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pilot Boarding Time'**
  String get pilotBoardingLabel;

  /// No description provided for @agentLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent Name'**
  String get agentLabel;

  /// No description provided for @agentContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent Contact'**
  String get agentContactLabel;

  /// No description provided for @mgoRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'MGO Required (m³)'**
  String get mgoRequiredLabel;

  /// No description provided for @hfoRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'HFO Required (m³)'**
  String get hfoRequiredLabel;

  /// No description provided for @freshWaterRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Fresh Water Required (m³)'**
  String get freshWaterRequiredLabel;

  /// No description provided for @provisionsRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Provisions Required'**
  String get provisionsRequiredLabel;

  /// No description provided for @sludgeDisposalLabel.
  ///
  /// In en, this message translates to:
  /// **'Sludge Disposal Required'**
  String get sludgeDisposalLabel;

  /// No description provided for @sludgeQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Sludge Quantity (m³)'**
  String get sludgeQuantityLabel;

  /// No description provided for @portStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get portStatusUpcoming;

  /// No description provided for @portStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get portStatusArrived;

  /// No description provided for @portStatusDeparted.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get portStatusDeparted;

  /// No description provided for @customsChecklistLabel.
  ///
  /// In en, this message translates to:
  /// **'Customs & Documentation Checklist'**
  String get customsChecklistLabel;

  /// No description provided for @certification.
  ///
  /// In en, this message translates to:
  /// **'Certification'**
  String get certification;

  /// No description provided for @vesselCerts.
  ///
  /// In en, this message translates to:
  /// **'Vessel Certificates'**
  String get vesselCerts;

  /// No description provided for @crewCerts.
  ///
  /// In en, this message translates to:
  /// **'Crew Certificates'**
  String get crewCerts;

  /// No description provided for @addVesselCert.
  ///
  /// In en, this message translates to:
  /// **'Add Vessel Certificate'**
  String get addVesselCert;

  /// No description provided for @addCrewCert.
  ///
  /// In en, this message translates to:
  /// **'Add Crew Certificate'**
  String get addCrewCert;

  /// No description provided for @documentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Document Name'**
  String get documentNameLabel;

  /// No description provided for @issuingAuthorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Issuing Authority'**
  String get issuingAuthorityLabel;

  /// No description provided for @issueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get issueDateLabel;

  /// No description provided for @expiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDateLabel;

  /// No description provided for @officerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Officer Name'**
  String get officerNameLabel;

  /// No description provided for @rankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rankLabel;

  /// No description provided for @certTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate Type'**
  String get certTypeLabel;

  /// No description provided for @certTypeCoc.
  ///
  /// In en, this message translates to:
  /// **'COC'**
  String get certTypeCoc;

  /// No description provided for @certTypeStcw.
  ///
  /// In en, this message translates to:
  /// **'STCW'**
  String get certTypeStcw;

  /// No description provided for @certTypeMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get certTypeMedical;

  /// No description provided for @certTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get certTypeOther;

  /// No description provided for @noCertificates.
  ///
  /// In en, this message translates to:
  /// **'No certificates recorded'**
  String get noCertificates;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @addFile.
  ///
  /// In en, this message translates to:
  /// **'Add File'**
  String get addFile;

  /// No description provided for @attachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsLabel;

  /// No description provided for @urgentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Urgent Notifications'**
  String get urgentNotifications;

  /// No description provided for @noUrgentNotifications.
  ///
  /// In en, this message translates to:
  /// **'No urgent notifications'**
  String get noUrgentNotifications;

  /// No description provided for @addUrgentNotification.
  ///
  /// In en, this message translates to:
  /// **'Raise Urgent Notification'**
  String get addUrgentNotification;

  /// No description provided for @alertTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert Type'**
  String get alertTypeLabel;

  /// No description provided for @alertTypeFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get alertTypeFire;

  /// No description provided for @alertTypeFlooding.
  ///
  /// In en, this message translates to:
  /// **'Flooding'**
  String get alertTypeFlooding;

  /// No description provided for @alertTypeEngineFailure.
  ///
  /// In en, this message translates to:
  /// **'Engine Failure'**
  String get alertTypeEngineFailure;

  /// No description provided for @alertTypeRouting.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get alertTypeRouting;

  /// No description provided for @alertTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get alertTypeOther;

  /// No description provided for @locationOnVesselLabel.
  ///
  /// In en, this message translates to:
  /// **'Location on Vessel'**
  String get locationOnVesselLabel;

  /// No description provided for @escalationNotAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Not Acknowledged'**
  String get escalationNotAcknowledged;

  /// No description provided for @escalationAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get escalationAcknowledged;

  /// No description provided for @escalationResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get escalationResolved;

  /// No description provided for @markAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Mark Acknowledged'**
  String get markAcknowledged;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark Resolved'**
  String get markResolved;

  /// No description provided for @raiseAlert.
  ///
  /// In en, this message translates to:
  /// **'Raise Alert'**
  String get raiseAlert;

  /// No description provided for @urgentAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 urgent notification} other{{count} urgent notifications}}'**
  String urgentAlertsTitle(int count);

  /// No description provided for @dailyTasks.
  ///
  /// In en, this message translates to:
  /// **'Daily Tasks'**
  String get dailyTasks;

  /// No description provided for @noDailyTasks.
  ///
  /// In en, this message translates to:
  /// **'No daily tasks yet'**
  String get noDailyTasks;

  /// No description provided for @addDailyTask.
  ///
  /// In en, this message translates to:
  /// **'Add Daily Task'**
  String get addDailyTask;

  /// No description provided for @taskCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Task Category'**
  String get taskCategoryLabel;

  /// No description provided for @categoryEngineRoomRounds.
  ///
  /// In en, this message translates to:
  /// **'Engine Room Rounds'**
  String get categoryEngineRoomRounds;

  /// No description provided for @categoryDeckRounds.
  ///
  /// In en, this message translates to:
  /// **'Deck Rounds'**
  String get categoryDeckRounds;

  /// No description provided for @categorySafetyEquipment.
  ///
  /// In en, this message translates to:
  /// **'Safety Equipment Checks'**
  String get categorySafetyEquipment;

  /// No description provided for @categoryNavigationEquipment.
  ///
  /// In en, this message translates to:
  /// **'Navigation Equipment Tests'**
  String get categoryNavigationEquipment;

  /// No description provided for @categoryGalleyHygiene.
  ///
  /// In en, this message translates to:
  /// **'Galley Hygiene Inspections'**
  String get categoryGalleyHygiene;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitleLabel;

  /// No description provided for @assignedToLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedToLabel;

  /// No description provided for @frequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyLabel;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyEveryWatch.
  ///
  /// In en, this message translates to:
  /// **'Every Watch'**
  String get frequencyEveryWatch;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @scheduledTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Time'**
  String get scheduledTimeLabel;

  /// No description provided for @checklistItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Checklist Items'**
  String get checklistItemsLabel;

  /// No description provided for @checklistItemsHint.
  ///
  /// In en, this message translates to:
  /// **'One item per line'**
  String get checklistItemsHint;

  /// No description provided for @checklistEngineOilPressure.
  ///
  /// In en, this message translates to:
  /// **'Check Main Engine Oil Pressure'**
  String get checklistEngineOilPressure;

  /// No description provided for @checklistEngineCoolingWaterTemp.
  ///
  /// In en, this message translates to:
  /// **'Check Main Engine Cooling Water Temperature'**
  String get checklistEngineCoolingWaterTemp;

  /// No description provided for @checklistBilgesLeaks.
  ///
  /// In en, this message translates to:
  /// **'Inspect Bilges for Leaks'**
  String get checklistBilgesLeaks;

  /// No description provided for @checklistGeneratorParams.
  ///
  /// In en, this message translates to:
  /// **'Check Generator Running Parameters'**
  String get checklistGeneratorParams;

  /// No description provided for @checklistMooringLines.
  ///
  /// In en, this message translates to:
  /// **'Inspect Mooring Lines & Fittings'**
  String get checklistMooringLines;

  /// No description provided for @checklistDeckLighting.
  ///
  /// In en, this message translates to:
  /// **'Check Deck Lighting'**
  String get checklistDeckLighting;

  /// No description provided for @checklistCargoEquipment.
  ///
  /// In en, this message translates to:
  /// **'Inspect Cargo/Deck Equipment for Damage'**
  String get checklistCargoEquipment;

  /// No description provided for @checklistLifeboatMechanism.
  ///
  /// In en, this message translates to:
  /// **'Inspect Lifeboat Release Mechanism'**
  String get checklistLifeboatMechanism;

  /// No description provided for @checklistFireExtinguisher.
  ///
  /// In en, this message translates to:
  /// **'Check Fire Extinguisher Pressure Gauges'**
  String get checklistFireExtinguisher;

  /// No description provided for @checklistEmergencyAlarm.
  ///
  /// In en, this message translates to:
  /// **'Test Emergency Alarm System'**
  String get checklistEmergencyAlarm;

  /// No description provided for @checklistLifeJackets.
  ///
  /// In en, this message translates to:
  /// **'Check Life Jacket Stock & Condition'**
  String get checklistLifeJackets;

  /// No description provided for @checklistRadarArpa.
  ///
  /// In en, this message translates to:
  /// **'Test Radar & ARPA'**
  String get checklistRadarArpa;

  /// No description provided for @checklistGpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Check GPS/GNSS Position Accuracy'**
  String get checklistGpsAccuracy;

  /// No description provided for @checklistSteeringGear.
  ///
  /// In en, this message translates to:
  /// **'Test Steering Gear (Manual/Auto)'**
  String get checklistSteeringGear;

  /// No description provided for @checklistGalleyCleanliness.
  ///
  /// In en, this message translates to:
  /// **'Check Galley Cleanliness'**
  String get checklistGalleyCleanliness;

  /// No description provided for @checklistFoodStorageTemp.
  ///
  /// In en, this message translates to:
  /// **'Check Food Storage Temperatures'**
  String get checklistFoodStorageTemp;

  /// No description provided for @checklistPestControl.
  ///
  /// In en, this message translates to:
  /// **'Inspect Pest Control Measures'**
  String get checklistPestControl;

  /// No description provided for @taskStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get taskStatusPending;

  /// No description provided for @taskStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// No description provided for @taskStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskStatusOverdue;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentHint;

  /// No description provided for @evidencePhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence Photos'**
  String get evidencePhotosLabel;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get markCompleted;

  /// No description provided for @upcomingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 upcoming} other{{count} upcoming}}'**
  String upcomingCount(int count);

  /// No description provided for @unacknowledgedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 unacknowledged} other{{count} unacknowledged}}'**
  String unacknowledgedCount(int count);

  /// No description provided for @overdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 overdue} other{{count} overdue}}'**
  String overdueCount(int count);

  /// No description provided for @assignToManagement.
  ///
  /// In en, this message translates to:
  /// **'Assign to management'**
  String get assignToManagement;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDateLabel;

  /// No description provided for @setDueDate.
  ///
  /// In en, this message translates to:
  /// **'Set due date'**
  String get setDueDate;

  /// No description provided for @managementAction.
  ///
  /// In en, this message translates to:
  /// **'Management Action'**
  String get managementAction;

  /// No description provided for @noAssignedActions.
  ///
  /// In en, this message translates to:
  /// **'No assigned actions'**
  String get noAssignedActions;

  /// No description provided for @unassignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassignedLabel;

  /// No description provided for @filterActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get filterActions;

  /// No description provided for @downloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadFile;

  /// No description provided for @previewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview isn\'t available for this file type. Download it to open in another app.'**
  String get previewUnavailable;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved to your device'**
  String get fileSaved;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @portRequirements.
  ///
  /// In en, this message translates to:
  /// **'Port Requirements'**
  String get portRequirements;

  /// No description provided for @portRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requirements Upon Arrival at Port'**
  String get portRequirementsTitle;

  /// No description provided for @addRequirement.
  ///
  /// In en, this message translates to:
  /// **'Add Requirement'**
  String get addRequirement;

  /// No description provided for @requirementTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Requirement'**
  String get requirementTitleLabel;

  /// No description provided for @reqCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reqCategoryLabel;

  /// No description provided for @reqCatDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get reqCatDocuments;

  /// No description provided for @reqCatCustoms.
  ///
  /// In en, this message translates to:
  /// **'Customs'**
  String get reqCatCustoms;

  /// No description provided for @reqCatHealth.
  ///
  /// In en, this message translates to:
  /// **'Health & Safety'**
  String get reqCatHealth;

  /// No description provided for @reqCatSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security (ISPS)'**
  String get reqCatSecurity;

  /// No description provided for @reqCatProvisions.
  ///
  /// In en, this message translates to:
  /// **'Provisions & Supplies'**
  String get reqCatProvisions;

  /// No description provided for @reqCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reqCatOther;

  /// No description provided for @reqStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get reqStatusReady;

  /// No description provided for @reqStatusPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reqStatusPendingLabel;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Mark Ready'**
  String get markReady;

  /// No description provided for @markPending.
  ///
  /// In en, this message translates to:
  /// **'Return to pending'**
  String get markPending;

  /// No description provided for @noRequirements.
  ///
  /// In en, this message translates to:
  /// **'No requirements yet'**
  String get noRequirements;

  /// No description provided for @requirementsReady.
  ///
  /// In en, this message translates to:
  /// **'{ready}/{total} ready'**
  String requirementsReady(int ready, int total);

  /// No description provided for @extractFromFile.
  ///
  /// In en, this message translates to:
  /// **'Scan file with AI'**
  String get extractFromFile;

  /// No description provided for @reviewExtractedDefect.
  ///
  /// In en, this message translates to:
  /// **'Review Extracted Defect'**
  String get reviewExtractedDefect;

  /// No description provided for @reviewExtractedRequisition.
  ///
  /// In en, this message translates to:
  /// **'Review Extracted Requisition'**
  String get reviewExtractedRequisition;

  /// No description provided for @extractingFile.
  ///
  /// In en, this message translates to:
  /// **'Reading file with AI…'**
  String get extractingFile;

  /// No description provided for @extractionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the file automatically. Please enter the details manually.'**
  String get extractionFailed;

  /// No description provided for @extractionNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI extraction isn\'t set up yet.'**
  String get extractionNotConfigured;

  /// No description provided for @extractionQuotaExhausted.
  ///
  /// In en, this message translates to:
  /// **'Today\'s free AI quota is used up. Please try again tomorrow.'**
  String get extractionQuotaExhausted;

  /// No description provided for @crew.
  ///
  /// In en, this message translates to:
  /// **'Crew'**
  String get crew;

  /// No description provided for @crewListTitle.
  ///
  /// In en, this message translates to:
  /// **'Crew List'**
  String get crewListTitle;

  /// No description provided for @currentCrew.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentCrew;

  /// No description provided for @previousCrew.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousCrew;

  /// No description provided for @addCrew.
  ///
  /// In en, this message translates to:
  /// **'Add Crew Member'**
  String get addCrew;

  /// No description provided for @crewNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get crewNameLabel;

  /// No description provided for @nationalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationalityLabel;

  /// No description provided for @signOnDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign-on Date'**
  String get signOnDateLabel;

  /// No description provided for @signOffDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign-off Date'**
  String get signOffDateLabel;

  /// No description provided for @signOffCrew.
  ///
  /// In en, this message translates to:
  /// **'Sign Off'**
  String get signOffCrew;

  /// No description provided for @reactivateCrew.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivateCrew;

  /// No description provided for @noCurrentCrew.
  ///
  /// In en, this message translates to:
  /// **'No current crew'**
  String get noCurrentCrew;

  /// No description provided for @noPreviousCrew.
  ///
  /// In en, this message translates to:
  /// **'No previous crew'**
  String get noPreviousCrew;

  /// No description provided for @crewOnboard.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No crew} one{1 onboard} other{{count} onboard}}'**
  String crewOnboard(int count);

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get aiAssistant;

  /// No description provided for @aiAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask how to use the app'**
  String get aiAssistantSubtitle;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI answers may be wrong — verify against official procedures. No vessel data is sent.'**
  String get aiDisclaimer;

  /// No description provided for @aiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a question...'**
  String get aiInputHint;

  /// No description provided for @aiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! Ask me how to use any part of the app — logging readings, raising a defect, exporting a report, and more.'**
  String get aiGreeting;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Assistant is temporarily unavailable.'**
  String get aiUnavailable;

  /// No description provided for @aiBusy.
  ///
  /// In en, this message translates to:
  /// **'Assistant is busy — try again in a moment.'**
  String get aiBusy;

  /// No description provided for @aiError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get aiError;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @handover.
  ///
  /// In en, this message translates to:
  /// **'Crew Handover'**
  String get handover;

  /// No description provided for @handoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch & duty handover reports'**
  String get handoverSubtitle;

  /// No description provided for @addHandover.
  ///
  /// In en, this message translates to:
  /// **'New Handover Report'**
  String get addHandover;

  /// No description provided for @noHandovers.
  ///
  /// In en, this message translates to:
  /// **'No handover reports yet.'**
  String get noHandovers;

  /// No description provided for @outgoingOfficerLabel.
  ///
  /// In en, this message translates to:
  /// **'Outgoing officer'**
  String get outgoingOfficerLabel;

  /// No description provided for @incomingOfficerLabel.
  ///
  /// In en, this message translates to:
  /// **'Incoming officer'**
  String get incomingOfficerLabel;

  /// No description provided for @handoverDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Handover date'**
  String get handoverDateLabel;

  /// No description provided for @safetySectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safetySectionLabel;

  /// No description provided for @machinerySectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Machinery & equipment'**
  String get machinerySectionLabel;

  /// No description provided for @pendingDefectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending defects'**
  String get pendingDefectsLabel;

  /// No description provided for @bunkersTanksLabel.
  ///
  /// In en, this message translates to:
  /// **'Bunkers & tanks'**
  String get bunkersTanksLabel;

  /// No description provided for @certsExpiringLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificates expiring'**
  String get certsExpiringLabel;

  /// No description provided for @certAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 certificate expires within 30 days} other{{count} certificates expire within 30 days}}'**
  String certAlarmTitle(int count);

  /// No description provided for @certAlarmTitleExpired.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 certificate has expired} other{{count} certificates have expired}}'**
  String certAlarmTitleExpired(int count);

  /// No description provided for @certAlarmTitleMixed.
  ///
  /// In en, this message translates to:
  /// **'{expiredCount} expired, {expiringCount} expiring within 30 days'**
  String certAlarmTitleMixed(int expiredCount, int expiringCount);

  /// No description provided for @certDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{1 day left} other{{days} days left}}'**
  String certDaysLeft(int days);

  /// No description provided for @certExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get certExpiresToday;

  /// No description provided for @certExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get certExpired;

  /// No description provided for @certStatusValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get certStatusValid;

  /// No description provided for @remarksLabel.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarksLabel;

  /// No description provided for @generateDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft from vessel data'**
  String get generateDraft;

  /// No description provided for @handoverStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get handoverStatusDraft;

  /// No description provided for @handoverStatusIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get handoverStatusIssued;

  /// No description provided for @handoverStatusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get handoverStatusAcknowledged;

  /// No description provided for @issueReport.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueReport;

  /// No description provided for @acknowledgeReport.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledgeReport;

  /// No description provided for @acknowledgedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged by'**
  String get acknowledgedByLabel;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @editReport.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editReport;

  /// No description provided for @managementTitle.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get managementTitle;

  /// No description provided for @managementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cash meeting & office approvals'**
  String get managementSubtitle;

  /// No description provided for @cashMeetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Meeting Sheet'**
  String get cashMeetingTitle;

  /// No description provided for @cashMeetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase lines with PR & PO, reviewed in the cash meeting'**
  String get cashMeetingSubtitle;

  /// No description provided for @cashPendingTab.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get cashPendingTab;

  /// No description provided for @cashApprovedTab.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get cashApprovedTab;

  /// No description provided for @cashNoItems.
  ///
  /// In en, this message translates to:
  /// **'No purchase lines yet. Add one or scan the meeting sheet with AI.'**
  String get cashNoItems;

  /// No description provided for @cashItemAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Purchase Line'**
  String get cashItemAdd;

  /// No description provided for @cashItemEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Purchase Line'**
  String get cashItemEdit;

  /// No description provided for @cashItemReviewExtracted.
  ///
  /// In en, this message translates to:
  /// **'Review Extracted Line'**
  String get cashItemReviewExtracted;

  /// No description provided for @operationLabel.
  ///
  /// In en, this message translates to:
  /// **'Operation / Dept.'**
  String get operationLabel;

  /// No description provided for @requestDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Request description'**
  String get requestDescriptionLabel;

  /// No description provided for @prNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'PR number'**
  String get prNumberLabel;

  /// No description provided for @poNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'PO number'**
  String get poNumberLabel;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @supplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierLabel;

  /// No description provided for @vesselLabel.
  ///
  /// In en, this message translates to:
  /// **'Vessel'**
  String get vesselLabel;

  /// No description provided for @allVesselsFilter.
  ///
  /// In en, this message translates to:
  /// **'All vessels'**
  String get allVesselsFilter;

  /// No description provided for @approvedOn.
  ///
  /// In en, this message translates to:
  /// **'Approved {date}'**
  String approvedOn(String date);

  /// No description provided for @totalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get totalsLabel;

  /// No description provided for @cashPendingBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 line awaiting approval} other{{count} lines awaiting approval}}'**
  String cashPendingBadge(int count);

  /// No description provided for @navRisk.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get navRisk;

  /// No description provided for @navActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get navActions;

  /// No description provided for @commandCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet Command Center'**
  String get commandCenterTitle;

  /// No description provided for @fleetHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet Health'**
  String get fleetHealthTitle;

  /// No description provided for @bandGood.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get bandGood;

  /// No description provided for @bandAttention.
  ///
  /// In en, this message translates to:
  /// **'Attention required'**
  String get bandAttention;

  /// No description provided for @bandHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get bandHighRisk;

  /// No description provided for @bandCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get bandCritical;

  /// No description provided for @vesselRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Vessel ranking'**
  String get vesselRankingTitle;

  /// No description provided for @priorityAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Priority attention'**
  String get priorityAttentionTitle;

  /// No description provided for @healthScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Health score'**
  String get healthScoreLabel;

  /// No description provided for @whyThisScore.
  ///
  /// In en, this message translates to:
  /// **'Why is this score {score}?'**
  String whyThisScore(int score);

  /// No description provided for @scoreBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Score breakdown'**
  String get scoreBreakdownTitle;

  /// No description provided for @deductionLine.
  ///
  /// In en, this message translates to:
  /// **'−{points} · {reason}'**
  String deductionLine(int points, String reason);

  /// No description provided for @componentScoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get componentScoresTitle;

  /// No description provided for @noRisksDetected.
  ///
  /// In en, this message translates to:
  /// **'No risks detected. All monitored records are within limits.'**
  String get noRisksDetected;

  /// No description provided for @calculatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculated {time}'**
  String calculatedAtLabel(String time);

  /// No description provided for @computedLocallyNote.
  ///
  /// In en, this message translates to:
  /// **'Computed on this device from the records currently loaded.'**
  String get computedLocallyNote;

  /// No description provided for @categoryDefects.
  ///
  /// In en, this message translates to:
  /// **'Defects'**
  String get categoryDefects;

  /// No description provided for @categoryMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get categoryMaintenance;

  /// No description provided for @categoryCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get categoryCertificates;

  /// No description provided for @categoryRequisitions.
  ///
  /// In en, this message translates to:
  /// **'Requisitions'**
  String get categoryRequisitions;

  /// No description provided for @categoryCrew.
  ///
  /// In en, this message translates to:
  /// **'Crew'**
  String get categoryCrew;

  /// No description provided for @categoryPortReadiness.
  ///
  /// In en, this message translates to:
  /// **'Port readiness'**
  String get categoryPortReadiness;

  /// No description provided for @categoryOperational.
  ///
  /// In en, this message translates to:
  /// **'Operational readiness'**
  String get categoryOperational;

  /// No description provided for @categoryDataQuality.
  ///
  /// In en, this message translates to:
  /// **'Data quality'**
  String get categoryDataQuality;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHigh;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMedium;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLow;

  /// No description provided for @severityInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get severityInfo;

  /// No description provided for @riskTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk Intelligence'**
  String get riskTitle;

  /// No description provided for @riskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detected from vessel records — every item links to its source'**
  String get riskSubtitle;

  /// No description provided for @noRisksFleet.
  ///
  /// In en, this message translates to:
  /// **'No risks detected across the fleet.'**
  String get noRisksFleet;

  /// No description provided for @evidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get evidenceLabel;

  /// No description provided for @recommendedActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended action'**
  String get recommendedActionLabel;

  /// No description provided for @createActionFromRisk.
  ///
  /// In en, this message translates to:
  /// **'Create action'**
  String get createActionFromRisk;

  /// No description provided for @actionAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Action already open'**
  String get actionAlreadyExists;

  /// No description provided for @openSourceRecord.
  ///
  /// In en, this message translates to:
  /// **'Open source record'**
  String get openSourceRecord;

  /// No description provided for @riskCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 risk} other{{count} risks}}'**
  String riskCountBadge(int count);

  /// No description provided for @riskDefectCriticalOpen.
  ///
  /// In en, this message translates to:
  /// **'Critical defect still open: {subject}'**
  String riskDefectCriticalOpen(String subject);

  /// No description provided for @riskDefectHighOpen.
  ///
  /// In en, this message translates to:
  /// **'High-severity defect open: {subject}'**
  String riskDefectHighOpen(String subject);

  /// No description provided for @riskDefectStale.
  ///
  /// In en, this message translates to:
  /// **'Defect open {days} days: {subject}'**
  String riskDefectStale(int days, String subject);

  /// No description provided for @riskDefectRecurring.
  ///
  /// In en, this message translates to:
  /// **'Possible recurring defect ({count}×): {subject} — review required'**
  String riskDefectRecurring(int count, String subject);

  /// No description provided for @riskCertExpired.
  ///
  /// In en, this message translates to:
  /// **'Certificate expired: {subject}'**
  String riskCertExpired(String subject);

  /// No description provided for @riskCertExpiring.
  ///
  /// In en, this message translates to:
  /// **'Certificate expires in {days} days: {subject}'**
  String riskCertExpiring(int days, String subject);

  /// No description provided for @riskCrewCertExpired.
  ///
  /// In en, this message translates to:
  /// **'Crew certificate expired: {subject}'**
  String riskCrewCertExpired(String subject);

  /// No description provided for @riskCrewCertExpiring.
  ///
  /// In en, this message translates to:
  /// **'Crew certificate expires in {days} days: {subject}'**
  String riskCrewCertExpiring(int days, String subject);

  /// No description provided for @riskMaintenanceOverdue.
  ///
  /// In en, this message translates to:
  /// **'Maintenance overdue: {subject}'**
  String riskMaintenanceOverdue(String subject);

  /// No description provided for @riskMaintenanceDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Maintenance due in {days} days: {subject}'**
  String riskMaintenanceDueSoon(int days, String subject);

  /// No description provided for @riskRequisitionUrgentStalled.
  ///
  /// In en, this message translates to:
  /// **'Urgent requisition awaiting approval {days} days: {subject}'**
  String riskRequisitionUrgentStalled(int days, String subject);

  /// No description provided for @riskRequisitionDeliveryOverdue.
  ///
  /// In en, this message translates to:
  /// **'Requisition past required delivery date: {subject}'**
  String riskRequisitionDeliveryOverdue(String subject);

  /// No description provided for @riskPortRequirementPending.
  ///
  /// In en, this message translates to:
  /// **'Port requirement not ready: {subject}'**
  String riskPortRequirementPending(String subject);

  /// No description provided for @riskUrgentNotificationOpen.
  ///
  /// In en, this message translates to:
  /// **'Urgent alert not acknowledged: {subject}'**
  String riskUrgentNotificationOpen(String subject);

  /// No description provided for @riskUrgentActionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Assigned alert action overdue: {subject}'**
  String riskUrgentActionOverdue(String subject);

  /// No description provided for @riskDailyTasksOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 daily task overdue} other{{count} daily tasks overdue}}'**
  String riskDailyTasksOverdue(int count);

  /// No description provided for @riskDataMissingInfo.
  ///
  /// In en, this message translates to:
  /// **'No responsible officer assigned: {subject}'**
  String riskDataMissingInfo(String subject);

  /// No description provided for @recDefectCritical.
  ///
  /// In en, this message translates to:
  /// **'Assign an engineer today and record the immediate action taken.'**
  String get recDefectCritical;

  /// No description provided for @recDefectHigh.
  ///
  /// In en, this message translates to:
  /// **'Assign a responsible officer and set a target closing date.'**
  String get recDefectHigh;

  /// No description provided for @recDefectStale.
  ///
  /// In en, this message translates to:
  /// **'Review status with the vessel — close it or re-plan the repair.'**
  String get recDefectStale;

  /// No description provided for @recDefectRecurring.
  ///
  /// In en, this message translates to:
  /// **'Review the history with the Chief Engineer before deciding a cause.'**
  String get recDefectRecurring;

  /// No description provided for @recCertificate.
  ///
  /// In en, this message translates to:
  /// **'Arrange renewal with the issuing authority and upload the new certificate.'**
  String get recCertificate;

  /// No description provided for @recMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Confirm the job plan with the vessel and update the due date or close it.'**
  String get recMaintenance;

  /// No description provided for @recRequisition.
  ///
  /// In en, this message translates to:
  /// **'Escalate the approval or confirm the delivery date with the supplier.'**
  String get recRequisition;

  /// No description provided for @recPortRequirement.
  ///
  /// In en, this message translates to:
  /// **'Complete the document before arrival and mark the requirement ready.'**
  String get recPortRequirement;

  /// No description provided for @recUrgentNotification.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge the alert and confirm the vessel\'s immediate response.'**
  String get recUrgentNotification;

  /// No description provided for @recDailyTasks.
  ///
  /// In en, this message translates to:
  /// **'Ask the vessel to complete or reschedule the overdue rounds.'**
  String get recDailyTasks;

  /// No description provided for @recDataQuality.
  ///
  /// In en, this message translates to:
  /// **'Add the missing details so the record can be tracked properly.'**
  String get recDataQuality;

  /// No description provided for @actionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Action Center'**
  String get actionsTitle;

  /// No description provided for @actionsMine.
  ///
  /// In en, this message translates to:
  /// **'My actions'**
  String get actionsMine;

  /// No description provided for @actionsFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get actionsFleet;

  /// No description provided for @actionsOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get actionsOverdue;

  /// No description provided for @actionsCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get actionsCritical;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'New action'**
  String get actionAdd;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit action'**
  String get actionEdit;

  /// No description provided for @noActions.
  ///
  /// In en, this message translates to:
  /// **'No actions here.'**
  String get noActions;

  /// No description provided for @actionTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionTitleLabel;

  /// No description provided for @recommendationLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get recommendationLabel;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @clearDueDate.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get clearDueDate;

  /// No description provided for @priorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get priorityCritical;

  /// No description provided for @actionStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionStatusOpen;

  /// No description provided for @actionStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get actionStatusInProgress;

  /// No description provided for @actionStatusWaitingVessel.
  ///
  /// In en, this message translates to:
  /// **'Waiting for vessel'**
  String get actionStatusWaitingVessel;

  /// No description provided for @actionStatusWaitingOffice.
  ///
  /// In en, this message translates to:
  /// **'Waiting for office'**
  String get actionStatusWaitingOffice;

  /// No description provided for @actionStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get actionStatusCompleted;

  /// No description provided for @actionStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get actionStatusCancelled;

  /// No description provided for @actionOverdueBadge.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get actionOverdueBadge;

  /// No description provided for @actionSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get actionSourceLabel;

  /// No description provided for @actionCreatedFromRisk.
  ///
  /// In en, this message translates to:
  /// **'Created from detected risk'**
  String get actionCreatedFromRisk;

  /// No description provided for @openActionsBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 open action} other{{count} open actions}}'**
  String openActionsBadge(int count);

  /// No description provided for @actionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn risks into tracked follow-up'**
  String get actionsSubtitle;

  /// No description provided for @sourceModuleDefect.
  ///
  /// In en, this message translates to:
  /// **'Defect'**
  String get sourceModuleDefect;

  /// No description provided for @sourceModuleVesselCert.
  ///
  /// In en, this message translates to:
  /// **'Vessel certificate'**
  String get sourceModuleVesselCert;

  /// No description provided for @sourceModuleCrewCert.
  ///
  /// In en, this message translates to:
  /// **'Crew certificate'**
  String get sourceModuleCrewCert;

  /// No description provided for @sourceModuleMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get sourceModuleMaintenance;

  /// No description provided for @sourceModuleRequisition.
  ///
  /// In en, this message translates to:
  /// **'Requisition'**
  String get sourceModuleRequisition;

  /// No description provided for @sourceModulePortRequirement.
  ///
  /// In en, this message translates to:
  /// **'Port requirement'**
  String get sourceModulePortRequirement;

  /// No description provided for @sourceModuleUrgentNotification.
  ///
  /// In en, this message translates to:
  /// **'Urgent alert'**
  String get sourceModuleUrgentNotification;

  /// No description provided for @sourceModuleDailyTask.
  ///
  /// In en, this message translates to:
  /// **'Daily task'**
  String get sourceModuleDailyTask;

  /// No description provided for @dailyBriefingTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Briefing'**
  String get dailyBriefingTitle;

  /// No description provided for @generateDailyBriefing.
  ///
  /// In en, this message translates to:
  /// **'Daily briefing'**
  String get generateDailyBriefing;

  /// No description provided for @briefingCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical — act now'**
  String get briefingCritical;

  /// No description provided for @briefingHighPriority.
  ///
  /// In en, this message translates to:
  /// **'High priority — follow up today'**
  String get briefingHighPriority;

  /// No description provided for @briefingUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming — prepare'**
  String get briefingUpcoming;

  /// No description provided for @briefingPositive.
  ///
  /// In en, this message translates to:
  /// **'No significant concern'**
  String get briefingPositive;

  /// No description provided for @briefingOpenActions.
  ///
  /// In en, this message translates to:
  /// **'Open actions'**
  String get briefingOpenActions;

  /// No description provided for @briefingNoneInSection.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this section.'**
  String get briefingNoneInSection;

  /// No description provided for @briefingAllClear.
  ///
  /// In en, this message translates to:
  /// **'No critical, high or medium risks detected across the fleet.'**
  String get briefingAllClear;

  /// No description provided for @briefingHeadline.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} vessels need attention.'**
  String briefingHeadline(int count, int total);

  /// No description provided for @copySummary.
  ///
  /// In en, this message translates to:
  /// **'Copy summary'**
  String get copySummary;

  /// No description provided for @summaryCopied.
  ///
  /// In en, this message translates to:
  /// **'Summary copied'**
  String get summaryCopied;

  /// No description provided for @aiSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'AI summary'**
  String get aiSummaryTitle;

  /// No description provided for @generateAiSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generateAiSummary;

  /// No description provided for @aiRecommendationLabel.
  ///
  /// In en, this message translates to:
  /// **'AI recommendation — human review required'**
  String get aiRecommendationLabel;

  /// No description provided for @briefingAiPrompt.
  ///
  /// In en, this message translates to:
  /// **'Give me a short superintendent briefing from this snapshot: what is critical, what to follow up today, and a numbered list of recommended next steps. Use only the snapshot.'**
  String get briefingAiPrompt;

  /// No description provided for @aiModeHelp.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get aiModeHelp;

  /// No description provided for @aiModeFleet.
  ///
  /// In en, this message translates to:
  /// **'My fleet'**
  String get aiModeFleet;

  /// No description provided for @aiFleetDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Answers come from a summary of your fleet records (health scores and risks). Costs, crew personal data and attachments are never sent.'**
  String get aiFleetDisclaimer;

  /// No description provided for @aiFleetGreeting.
  ///
  /// In en, this message translates to:
  /// **'Ask about the fleet — for example: which vessel needs attention first, or why is a vessel\'s score low?'**
  String get aiFleetGreeting;
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
