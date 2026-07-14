// ignore: unused_import
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
  String get filterAll => 'All';

  @override
  String get fleetLabel => 'Fleet';

  @override
  String get statusOffHire => 'Off-hire';

  @override
  String get workingPort => 'Working Port';

  @override
  String get editVessel => 'Edit Vessel';

  @override
  String get vesselStatusLabel => 'Status';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get addMaintenance => 'Add Maintenance';

  @override
  String get noMaintenance => 'No maintenance records';

  @override
  String get maintenanceTitleLabel => 'Job Title';

  @override
  String get maintenanceDescLabel => 'Description';

  @override
  String get performedByLabel => 'Performed By';

  @override
  String get maintenanceDueLabel => 'Due';

  @override
  String get maintStatusPlanned => 'Planned';

  @override
  String get maintStatusInProgress => 'In Progress';

  @override
  String get maintStatusCompleted => 'Completed';

  @override
  String get specifications => 'Specifications';

  @override
  String get addSpec => 'Add Specification';

  @override
  String get noSpecs => 'No specification files';

  @override
  String get specTitleLabel => 'Document Title';

  @override
  String get signInPrompt => 'Sign in to continue';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Log In';

  @override
  String get invalidCredentials => 'Incorrect username or password';

  @override
  String get offlineAuthNote =>
      'Shared fleet account — sign in with your username.';

  @override
  String get account => 'Account';

  @override
  String get logOut => 'Log Out';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get addUser => 'Add User';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get adminRole => 'Administrator';

  @override
  String get userRole => 'User';

  @override
  String get makeAdmin => 'Administrator access';

  @override
  String get changePassword => 'Change Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get userExists => 'That username already exists';

  @override
  String get passwordChanged => 'Password updated';

  @override
  String get fieldsRequired => 'Username and password are required';

  @override
  String get noUsersYet => 'No users yet';

  @override
  String get adminOnlyAction => 'Administrator access required';

  @override
  String get actionFailed =>
      'Action failed — check your connection and try again';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
      zero: 'No files',
    );
    return '$_temp0';
  }

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
  String get aboutBody =>
      'Maridive Fleet Vessels helps crews and shore staff monitor fuel, mud, lube and hydraulic tank levels across the fleet of offshore support vessels operating in Libya.';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get refresh => 'Refresh';

  @override
  String get add => 'Add';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

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

  @override
  String get status => 'Status';

  @override
  String get tankLabel => 'Tank';

  @override
  String get categoryLabel => 'Category';

  @override
  String get levelLabel => 'Level';

  @override
  String get selectSections => 'Select sections';

  @override
  String get exportFormat => 'Export format';

  @override
  String get generateReport => 'Generate report';

  @override
  String get vesselOperations => 'Vessel Operations';

  @override
  String get viewEntries => 'View entries';

  @override
  String get tankStatusPdf => 'Tank status PDF';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String openCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
    );
    return '$_temp0';
  }

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending',
      one: '1 pending',
    );
    return '$_temp0';
  }

  @override
  String get defects => 'Defects';

  @override
  String get addDefect => 'Report Defect';

  @override
  String get defectTitleLabel => 'Title';

  @override
  String get defectDescriptionLabel => 'Description';

  @override
  String get severityLabel => 'Severity';

  @override
  String get severityMinor => 'Minor';

  @override
  String get severityMajor => 'Major';

  @override
  String get severityCritical => 'Critical';

  @override
  String get statusOpenDefect => 'Open';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusClosedDefect => 'Closed';

  @override
  String get noDefects => 'No defects reported';

  @override
  String get reportedOn => 'Reported';

  @override
  String get markInProgress => 'Mark In Progress';

  @override
  String get markClosed => 'Mark Closed';

  @override
  String get reopen => 'Reopen';

  @override
  String criticalDefectsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count critical defects',
      one: '1 critical defect',
    );
    return '$_temp0';
  }

  @override
  String get requisitions => 'Requisitions';

  @override
  String get addRequisition => 'New Requisition';

  @override
  String get itemNameLabel => 'Item Name';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get unitLabel => 'Unit';

  @override
  String get notesLabel => 'Notes (optional)';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get reqStatusPending => 'Pending';

  @override
  String get reqStatusApproved => 'Approved';

  @override
  String get reqStatusOrdered => 'Ordered';

  @override
  String get reqStatusReceived => 'Received';

  @override
  String get reqStatusRejected => 'Rejected';

  @override
  String get noRequisitions => 'No requisitions yet';

  @override
  String get requestedOn => 'Requested';

  @override
  String get markApproved => 'Approve';

  @override
  String get markOrdered => 'Mark Ordered';

  @override
  String get markReceived => 'Mark Received';

  @override
  String get markRejected => 'Reject';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationEngineRoom => 'Engine Room';

  @override
  String get locationDeck => 'Deck';

  @override
  String get locationBridge => 'Bridge';

  @override
  String get locationAccommodation => 'Accommodation';

  @override
  String get locationGalley => 'Galley';

  @override
  String get locationOther => 'Other';

  @override
  String get assignedOfficerLabel => 'Assigned Officer';

  @override
  String get requiredSparePartsLabel => 'Required Spare Parts';

  @override
  String get actionTakenLabel => 'Action Taken';

  @override
  String get partNumberLabel => 'Part Number';

  @override
  String get oemLabel => 'OEM / Manufacturer';

  @override
  String get stockLabel => 'Quantity in Stock';

  @override
  String get unitPriceLabel => 'Unit Price';

  @override
  String get departmentLabel => 'Department';

  @override
  String get departmentEngine => 'Engine';

  @override
  String get departmentDeck => 'Deck';

  @override
  String get departmentSteward => 'Steward';

  @override
  String get requiredDeliveryLabel => 'Required Delivery Date';

  @override
  String get reqStatusHod => 'HOD Approval';

  @override
  String get reqStatusTechSup => 'Technical Superintendent Approval';

  @override
  String get markHodApproval => 'Mark HOD Approved';

  @override
  String get markTechSupApproval => 'Mark Tech. Sup. Approved';

  @override
  String get temperatureLabel => 'Temperature (°C)';

  @override
  String get lastSounding => 'Last sounding';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get soundingHistory24h => 'Sounding History';

  @override
  String get overfillCritical => 'Critical (Overfill)';

  @override
  String get overfillWarning => 'Warning (Overfill)';

  @override
  String get portCalls => 'Port Calls';

  @override
  String get noPortCalls => 'No port calls scheduled';

  @override
  String get addPortCall => 'Add Port Call';

  @override
  String get portNameLabel => 'Port Name';

  @override
  String get arrivalEtaLabel => 'Arrival ETA';

  @override
  String get pilotBoardingLabel => 'Pilot Boarding Time';

  @override
  String get agentLabel => 'Agent Name';

  @override
  String get agentContactLabel => 'Agent Contact';

  @override
  String get mgoRequiredLabel => 'MGO Required (m³)';

  @override
  String get hfoRequiredLabel => 'HFO Required (m³)';

  @override
  String get freshWaterRequiredLabel => 'Fresh Water Required (m³)';

  @override
  String get provisionsRequiredLabel => 'Provisions Required';

  @override
  String get sludgeDisposalLabel => 'Sludge Disposal Required';

  @override
  String get sludgeQuantityLabel => 'Sludge Quantity (m³)';

  @override
  String get portStatusUpcoming => 'Upcoming';

  @override
  String get portStatusArrived => 'Arrived';

  @override
  String get portStatusDeparted => 'Departed';

  @override
  String get customsChecklistLabel => 'Customs & Documentation Checklist';

  @override
  String get certification => 'Certification';

  @override
  String get vesselCerts => 'Vessel Certificates';

  @override
  String get crewCerts => 'Crew Certificates';

  @override
  String get addVesselCert => 'Add Vessel Certificate';

  @override
  String get addCrewCert => 'Add Crew Certificate';

  @override
  String get documentNameLabel => 'Document Name';

  @override
  String get issuingAuthorityLabel => 'Issuing Authority';

  @override
  String get issueDateLabel => 'Issue Date';

  @override
  String get expiryDateLabel => 'Expiry Date';

  @override
  String get officerNameLabel => 'Officer Name';

  @override
  String get rankLabel => 'Rank';

  @override
  String get certTypeLabel => 'Certificate Type';

  @override
  String get certTypeCoc => 'COC';

  @override
  String get certTypeStcw => 'STCW';

  @override
  String get certTypeMedical => 'Medical';

  @override
  String get certTypeOther => 'Other';

  @override
  String get noCertificates => 'No certificates recorded';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get addFile => 'Add File';

  @override
  String get attachmentsLabel => 'Attachments';

  @override
  String get urgentNotifications => 'Urgent Notifications';

  @override
  String get noUrgentNotifications => 'No urgent notifications';

  @override
  String get addUrgentNotification => 'Raise Urgent Notification';

  @override
  String get alertTypeLabel => 'Alert Type';

  @override
  String get alertTypeFire => 'Fire';

  @override
  String get alertTypeFlooding => 'Flooding';

  @override
  String get alertTypeEngineFailure => 'Engine Failure';

  @override
  String get alertTypeRouting => 'Routing';

  @override
  String get alertTypeOther => 'Other';

  @override
  String get locationOnVesselLabel => 'Location on Vessel';

  @override
  String get escalationNotAcknowledged => 'Not Acknowledged';

  @override
  String get escalationAcknowledged => 'Acknowledged';

  @override
  String get escalationResolved => 'Resolved';

  @override
  String get markAcknowledged => 'Mark Acknowledged';

  @override
  String get markResolved => 'Mark Resolved';

  @override
  String get raiseAlert => 'Raise Alert';

  @override
  String urgentAlertsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count urgent notifications',
      one: '1 urgent notification',
    );
    return '$_temp0';
  }

  @override
  String get dailyTasks => 'Daily Tasks';

  @override
  String get noDailyTasks => 'No daily tasks yet';

  @override
  String get addDailyTask => 'Add Daily Task';

  @override
  String get taskCategoryLabel => 'Task Category';

  @override
  String get categoryEngineRoomRounds => 'Engine Room Rounds';

  @override
  String get categoryDeckRounds => 'Deck Rounds';

  @override
  String get categorySafetyEquipment => 'Safety Equipment Checks';

  @override
  String get categoryNavigationEquipment => 'Navigation Equipment Tests';

  @override
  String get categoryGalleyHygiene => 'Galley Hygiene Inspections';

  @override
  String get taskTitleLabel => 'Task Title';

  @override
  String get assignedToLabel => 'Assigned To';

  @override
  String get frequencyLabel => 'Frequency';

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyEveryWatch => 'Every Watch';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get scheduledTimeLabel => 'Scheduled Time';

  @override
  String get checklistItemsLabel => 'Checklist Items';

  @override
  String get checklistItemsHint => 'One item per line';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusOverdue => 'Overdue';

  @override
  String get commentHint => 'Comment (optional)';

  @override
  String get evidencePhotosLabel => 'Evidence Photos';

  @override
  String get markCompleted => 'Mark Completed';

  @override
  String upcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming',
      one: '1 upcoming',
    );
    return '$_temp0';
  }

  @override
  String unacknowledgedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unacknowledged',
      one: '1 unacknowledged',
    );
    return '$_temp0';
  }

  @override
  String overdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue',
      one: '1 overdue',
    );
    return '$_temp0';
  }

  @override
  String get assignToManagement => 'Assign to management';

  @override
  String get dueDateLabel => 'Due Date';

  @override
  String get setDueDate => 'Set due date';

  @override
  String get managementAction => 'Management Action';

  @override
  String get noAssignedActions => 'No assigned actions';

  @override
  String get unassignedLabel => 'Unassigned';

  @override
  String get filterActions => 'Actions';

  @override
  String get downloadFile => 'Download';

  @override
  String get previewUnavailable =>
      'Preview isn\'t available for this file type. Download it to open in another app.';

  @override
  String get fileSaved => 'File saved to your device';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get portRequirements => 'Port Requirements';

  @override
  String get portRequirementsTitle => 'Requirements Upon Arrival at Port';

  @override
  String get addRequirement => 'Add Requirement';

  @override
  String get requirementTitleLabel => 'Requirement';

  @override
  String get reqCategoryLabel => 'Category';

  @override
  String get reqCatDocuments => 'Documents';

  @override
  String get reqCatCustoms => 'Customs';

  @override
  String get reqCatHealth => 'Health & Safety';

  @override
  String get reqCatSecurity => 'Security (ISPS)';

  @override
  String get reqCatProvisions => 'Provisions & Supplies';

  @override
  String get reqCatOther => 'Other';

  @override
  String get reqStatusReady => 'Ready';

  @override
  String get reqStatusPendingLabel => 'Pending';

  @override
  String get markReady => 'Mark Ready';

  @override
  String get markPending => 'Mark Pending';

  @override
  String get noRequirements => 'No requirements yet';

  @override
  String requirementsReady(int ready, int total) {
    return '$ready/$total ready';
  }

  @override
  String get extractFromFile => 'Scan file with AI';

  @override
  String get reviewExtractedDefect => 'Review Extracted Defect';

  @override
  String get reviewExtractedRequisition => 'Review Extracted Requisition';

  @override
  String get extractingFile => 'Reading file with AI…';

  @override
  String get extractionFailed =>
      'Couldn\'t read the file automatically. Please enter the details manually.';

  @override
  String get extractionNotConfigured => 'AI extraction isn\'t set up yet.';

  @override
  String get crew => 'Crew';

  @override
  String get crewListTitle => 'Crew List';

  @override
  String get currentCrew => 'Current';

  @override
  String get previousCrew => 'Previous';

  @override
  String get addCrew => 'Add Crew Member';

  @override
  String get crewNameLabel => 'Name';

  @override
  String get nationalityLabel => 'Nationality';

  @override
  String get signOnDateLabel => 'Sign-on Date';

  @override
  String get signOffDateLabel => 'Sign-off Date';

  @override
  String get signOffCrew => 'Sign Off';

  @override
  String get reactivateCrew => 'Reactivate';

  @override
  String get noCurrentCrew => 'No current crew';

  @override
  String get noPreviousCrew => 'No previous crew';

  @override
  String crewOnboard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count onboard',
      one: '1 onboard',
      zero: 'No crew',
    );
    return '$_temp0';
  }
}
