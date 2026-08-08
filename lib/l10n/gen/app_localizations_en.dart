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
  String get networkError =>
      'Couldn\'t reach the server — check your connection and try again';

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
  String get editUser => 'Edit User';

  @override
  String get userUpdated => 'User updated';

  @override
  String get keepCurrentPasswordHint =>
      'Leave blank to keep the current password';

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
  String tankHistoryChartSemantics(int percent) {
    return 'Tank level history chart, currently $percent% of capacity';
  }

  @override
  String chartEntriesSemantics(String entries) {
    return 'Chart: $entries';
  }

  @override
  String get tankLevelSemantics => 'Tank level';

  @override
  String get navFleet => 'Fleet';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navAssistant => 'Assistant';

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
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get generateReport => 'Generate report';

  @override
  String get reviewReport => 'Review';

  @override
  String get reportNoEntries => 'No entries';

  @override
  String get generatedAtLabel => 'Generated';

  @override
  String get vesselOperations => 'Vessel Operations';

  @override
  String get viewEntries => 'View entries';

  @override
  String get bulkImport => 'Bulk Import';

  @override
  String get bulkImportSubtitle => 'AI-scan multiple files at once';

  @override
  String get addFiles => 'Add files';

  @override
  String get bulkImportEmpty =>
      'Add files to scan and route them to the right module automatically.';

  @override
  String get bulkImportErrors => 'Errors';

  @override
  String get bulkImportFilesTotal => 'Files';

  @override
  String get bulkImportFilesFailed => 'Failed';

  @override
  String get bulkImportDuplicates => 'Duplicates';

  @override
  String get bulkImportUnclassified => 'Unclassified';

  @override
  String get bulkImportAccept => 'Accept';

  @override
  String get tankStatusPdf => 'Tank status PDF';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get editRequisition => 'Edit Requisition';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDeleteTitle => 'Delete this?';

  @override
  String confirmDeleteMessage(String item) {
    return '\"$item\" will be permanently deleted. This can\'t be undone.';
  }

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
  String get editDefect => 'Edit Defect';

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
  String pendingSyncBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
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
  String get analyticsDashboard => 'Analytics Dashboard';

  @override
  String get allVessels => 'All Vessels';

  @override
  String get totalDefects => 'Total Defects';

  @override
  String get openDefectsLabel => 'Open Defects';

  @override
  String get totalRequisitions => 'Total Requisitions';

  @override
  String get pendingRequisitionsLabel => 'Pending Requisitions';

  @override
  String get defectsByStatus => 'Defects by Status';

  @override
  String get defectsByPriority => 'Defects by Priority';

  @override
  String get requisitionsByStatus => 'Requisitions by Status';

  @override
  String get requisitionsByDepartment => 'Requisitions by Department';

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
  String get lastSounding => 'Last reading';

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
  String get soundingHistory24h => 'Reading History';

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
  String get assignedToLabel => 'Assigned to';

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
  String get checklistEngineOilPressure => 'Check Main Engine Oil Pressure';

  @override
  String get checklistEngineCoolingWaterTemp =>
      'Check Main Engine Cooling Water Temperature';

  @override
  String get checklistBilgesLeaks => 'Inspect Bilges for Leaks';

  @override
  String get checklistGeneratorParams => 'Check Generator Running Parameters';

  @override
  String get checklistMooringLines => 'Inspect Mooring Lines & Fittings';

  @override
  String get checklistDeckLighting => 'Check Deck Lighting';

  @override
  String get checklistCargoEquipment =>
      'Inspect Cargo/Deck Equipment for Damage';

  @override
  String get checklistLifeboatMechanism => 'Inspect Lifeboat Release Mechanism';

  @override
  String get checklistFireExtinguisher =>
      'Check Fire Extinguisher Pressure Gauges';

  @override
  String get checklistEmergencyAlarm => 'Test Emergency Alarm System';

  @override
  String get checklistLifeJackets => 'Check Life Jacket Stock & Condition';

  @override
  String get checklistRadarArpa => 'Test Radar & ARPA';

  @override
  String get checklistGpsAccuracy => 'Check GPS/GNSS Position Accuracy';

  @override
  String get checklistSteeringGear => 'Test Steering Gear (Manual/Auto)';

  @override
  String get checklistGalleyCleanliness => 'Check Galley Cleanliness';

  @override
  String get checklistFoodStorageTemp => 'Check Food Storage Temperatures';

  @override
  String get checklistPestControl => 'Inspect Pest Control Measures';

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
  String get dueDateLabel => 'Due date';

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
  String get markPending => 'Return to pending';

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
  String get extractionQuotaExhausted =>
      'Today\'s free AI quota is used up. Please try again tomorrow.';

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

  @override
  String get aiAssistant => 'Assistant';

  @override
  String get aiAssistantSubtitle => 'Ask how to use the app';

  @override
  String get aiDisclaimer =>
      'AI answers may be wrong — verify against official procedures. No vessel data is sent.';

  @override
  String get aiInputHint => 'Ask a question...';

  @override
  String get aiGreeting =>
      'Hi! Ask me how to use any part of the app — logging readings, raising a defect, exporting a report, and more.';

  @override
  String get aiUnavailable => 'Assistant is temporarily unavailable.';

  @override
  String get aiBusy => 'Assistant is busy — try again in a moment.';

  @override
  String get aiError => 'Something went wrong. Please try again.';

  @override
  String get send => 'Send';

  @override
  String get handover => 'Crew Handover';

  @override
  String get handoverSubtitle => 'Watch & duty handover reports';

  @override
  String get addHandover => 'New Handover Report';

  @override
  String get noHandovers => 'No handover reports yet.';

  @override
  String get outgoingOfficerLabel => 'Outgoing officer';

  @override
  String get incomingOfficerLabel => 'Incoming officer';

  @override
  String get handoverDateLabel => 'Handover date';

  @override
  String get safetySectionLabel => 'Safety';

  @override
  String get machinerySectionLabel => 'Machinery & equipment';

  @override
  String get pendingDefectsLabel => 'Pending defects';

  @override
  String get bunkersTanksLabel => 'Bunkers & tanks';

  @override
  String get certsExpiringLabel => 'Certificates expiring';

  @override
  String certAlarmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count certificates expire within 30 days',
      one: '1 certificate expires within 30 days',
    );
    return '$_temp0';
  }

  @override
  String certAlarmTitleExpired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count certificates have expired',
      one: '1 certificate has expired',
    );
    return '$_temp0';
  }

  @override
  String certAlarmTitleMixed(int expiredCount, int expiringCount) {
    return '$expiredCount expired, $expiringCount expiring within 30 days';
  }

  @override
  String certDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get certExpiresToday => 'Expires today';

  @override
  String get certExpired => 'Expired';

  @override
  String get certStatusValid => 'Valid';

  @override
  String get remarksLabel => 'Remarks';

  @override
  String get generateDraft => 'Draft from vessel data';

  @override
  String get handoverStatusDraft => 'Draft';

  @override
  String get handoverStatusIssued => 'Issued';

  @override
  String get handoverStatusAcknowledged => 'Acknowledged';

  @override
  String get issueReport => 'Issue';

  @override
  String get acknowledgeReport => 'Acknowledge';

  @override
  String get acknowledgedByLabel => 'Acknowledged by';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get editReport => 'Edit';

  @override
  String get managementTitle => 'Management';

  @override
  String get managementSubtitle => 'Cash meeting & office approvals';

  @override
  String get cashMeetingTitle => 'Cash Meeting Sheet';

  @override
  String get cashMeetingSubtitle =>
      'Purchase lines with PR & PO, reviewed in the cash meeting';

  @override
  String get cashPendingTab => 'Not approved';

  @override
  String get cashApprovedTab => 'Approved';

  @override
  String get cashNoItems =>
      'No purchase lines yet. Add one or scan the meeting sheet with AI.';

  @override
  String get cashItemAdd => 'Add Purchase Line';

  @override
  String get cashItemEdit => 'Edit Purchase Line';

  @override
  String get cashItemReviewExtracted => 'Review Extracted Line';

  @override
  String get operationLabel => 'Operation / Dept.';

  @override
  String get requestDescriptionLabel => 'Request description';

  @override
  String get prNumberLabel => 'PR number';

  @override
  String get poNumberLabel => 'PO number';

  @override
  String get costLabel => 'Cost';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get supplierLabel => 'Supplier';

  @override
  String get vesselLabel => 'Vessel';

  @override
  String get allVesselsFilter => 'All vessels';

  @override
  String approvedOn(String date) {
    return 'Approved $date';
  }

  @override
  String get totalsLabel => 'Totals';

  @override
  String cashPendingBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines awaiting approval',
      one: '1 line awaiting approval',
    );
    return '$_temp0';
  }

  @override
  String get navRisk => 'Risk';

  @override
  String get navActions => 'Actions';

  @override
  String get commandCenterTitle => 'Fleet Command Center';

  @override
  String get fleetHealthTitle => 'Fleet Health';

  @override
  String get bandGood => 'Healthy';

  @override
  String get bandAttention => 'Attention required';

  @override
  String get bandHighRisk => 'High risk';

  @override
  String get bandCritical => 'Critical';

  @override
  String get vesselRankingTitle => 'Vessel ranking';

  @override
  String get priorityAttentionTitle => 'Priority attention';

  @override
  String get healthScoreLabel => 'Health score';

  @override
  String whyThisScore(int score) {
    return 'Why is this score $score?';
  }

  @override
  String get scoreBreakdownTitle => 'Score breakdown';

  @override
  String deductionLine(int points, String reason) {
    return '−$points · $reason';
  }

  @override
  String get componentScoresTitle => 'Components';

  @override
  String get noRisksDetected =>
      'No risks detected. All monitored records are within limits.';

  @override
  String calculatedAtLabel(String time) {
    return 'Calculated $time';
  }

  @override
  String get computedLocallyNote =>
      'Computed on this device from the records currently loaded.';

  @override
  String get categoryDefects => 'Defects';

  @override
  String get categoryMaintenance => 'Maintenance';

  @override
  String get categoryCertificates => 'Certificates';

  @override
  String get categoryRequisitions => 'Requisitions';

  @override
  String get categoryCrew => 'Crew';

  @override
  String get categoryPortReadiness => 'Port readiness';

  @override
  String get categoryOperational => 'Operational readiness';

  @override
  String get categoryDataQuality => 'Data quality';

  @override
  String get severityHigh => 'High';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityLow => 'Low';

  @override
  String get severityInfo => 'Information';

  @override
  String get riskTitle => 'Risk Intelligence';

  @override
  String get riskSubtitle =>
      'Detected from vessel records — every item links to its source';

  @override
  String get noRisksFleet => 'No risks detected across the fleet.';

  @override
  String get evidenceLabel => 'Evidence';

  @override
  String get recommendedActionLabel => 'Recommended action';

  @override
  String get createActionFromRisk => 'Create action';

  @override
  String get actionAlreadyExists => 'Action already open';

  @override
  String get openSourceRecord => 'Open source record';

  @override
  String riskCountBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risks',
      one: '1 risk',
    );
    return '$_temp0';
  }

  @override
  String riskDefectCriticalOpen(String subject) {
    return 'Critical defect still open: $subject';
  }

  @override
  String riskDefectHighOpen(String subject) {
    return 'High-severity defect open: $subject';
  }

  @override
  String riskDefectStale(int days, String subject) {
    return 'Defect open $days days: $subject';
  }

  @override
  String riskDefectRecurring(int count, String subject) {
    return 'Possible recurring defect ($count×): $subject — review required';
  }

  @override
  String riskCertExpired(String subject) {
    return 'Certificate expired: $subject';
  }

  @override
  String riskCertExpiring(int days, String subject) {
    return 'Certificate expires in $days days: $subject';
  }

  @override
  String riskCrewCertExpired(String subject) {
    return 'Crew certificate expired: $subject';
  }

  @override
  String riskCrewCertExpiring(int days, String subject) {
    return 'Crew certificate expires in $days days: $subject';
  }

  @override
  String riskMaintenanceOverdue(String subject) {
    return 'Maintenance overdue: $subject';
  }

  @override
  String riskMaintenanceDueSoon(int days, String subject) {
    return 'Maintenance due in $days days: $subject';
  }

  @override
  String riskRequisitionUrgentStalled(int days, String subject) {
    return 'Urgent requisition awaiting approval $days days: $subject';
  }

  @override
  String riskRequisitionDeliveryOverdue(String subject) {
    return 'Requisition past required delivery date: $subject';
  }

  @override
  String riskPortRequirementPending(String subject) {
    return 'Port requirement not ready: $subject';
  }

  @override
  String riskUrgentNotificationOpen(String subject) {
    return 'Urgent alert not acknowledged: $subject';
  }

  @override
  String riskUrgentActionOverdue(String subject) {
    return 'Assigned alert action overdue: $subject';
  }

  @override
  String riskDailyTasksOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daily tasks overdue',
      one: '1 daily task overdue',
    );
    return '$_temp0';
  }

  @override
  String riskDataMissingInfo(String subject) {
    return 'No responsible officer assigned: $subject';
  }

  @override
  String get recDefectCritical =>
      'Assign an engineer today and record the immediate action taken.';

  @override
  String get recDefectHigh =>
      'Assign a responsible officer and set a target closing date.';

  @override
  String get recDefectStale =>
      'Review status with the vessel — close it or re-plan the repair.';

  @override
  String get recDefectRecurring =>
      'Review the history with the Chief Engineer before deciding a cause.';

  @override
  String get recCertificate =>
      'Arrange renewal with the issuing authority and upload the new certificate.';

  @override
  String get recMaintenance =>
      'Confirm the job plan with the vessel and update the due date or close it.';

  @override
  String get recRequisition =>
      'Escalate the approval or confirm the delivery date with the supplier.';

  @override
  String get recPortRequirement =>
      'Complete the document before arrival and mark the requirement ready.';

  @override
  String get recUrgentNotification =>
      'Acknowledge the alert and confirm the vessel\'s immediate response.';

  @override
  String get recDailyTasks =>
      'Ask the vessel to complete or reschedule the overdue rounds.';

  @override
  String get recDataQuality =>
      'Add the missing details so the record can be tracked properly.';

  @override
  String get actionsTitle => 'Action Center';

  @override
  String get actionsMine => 'My actions';

  @override
  String get actionsFleet => 'Fleet';

  @override
  String get actionsOverdue => 'Overdue';

  @override
  String get actionsCritical => 'Critical';

  @override
  String get actionAdd => 'New action';

  @override
  String get actionEdit => 'Edit action';

  @override
  String get noActions => 'No actions here.';

  @override
  String get actionTitleLabel => 'Action';

  @override
  String get recommendationLabel => 'Recommendation';

  @override
  String get noDueDate => 'No due date';

  @override
  String get clearDueDate => 'Clear due date';

  @override
  String get priorityCritical => 'Critical';

  @override
  String get actionStatusOpen => 'Open';

  @override
  String get actionStatusInProgress => 'In progress';

  @override
  String get actionStatusWaitingVessel => 'Waiting for vessel';

  @override
  String get actionStatusWaitingOffice => 'Waiting for office';

  @override
  String get actionStatusCompleted => 'Completed';

  @override
  String get actionStatusCancelled => 'Cancelled';

  @override
  String get actionOverdueBadge => 'Overdue';

  @override
  String get actionSourceLabel => 'Source';

  @override
  String get actionCreatedFromRisk => 'Created from detected risk';

  @override
  String openActionsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open actions',
      one: '1 open action',
    );
    return '$_temp0';
  }

  @override
  String get actionsSubtitle => 'Turn risks into tracked follow-up';

  @override
  String get sourceModuleDefect => 'Defect';

  @override
  String get sourceModuleVesselCert => 'Vessel certificate';

  @override
  String get sourceModuleCrewCert => 'Crew certificate';

  @override
  String get sourceModuleMaintenance => 'Maintenance';

  @override
  String get sourceModuleRequisition => 'Requisition';

  @override
  String get sourceModulePortRequirement => 'Port requirement';

  @override
  String get sourceModuleUrgentNotification => 'Urgent alert';

  @override
  String get sourceModuleDailyTask => 'Daily task';

  @override
  String get dailyBriefingTitle => 'Daily Briefing';

  @override
  String get generateDailyBriefing => 'Daily briefing';

  @override
  String get briefingCritical => 'Critical — act now';

  @override
  String get briefingHighPriority => 'High priority — follow up today';

  @override
  String get briefingUpcoming => 'Upcoming — prepare';

  @override
  String get briefingPositive => 'No significant concern';

  @override
  String get briefingOpenActions => 'Open actions';

  @override
  String get briefingNoneInSection => 'Nothing in this section.';

  @override
  String get briefingAllClear =>
      'No critical, high or medium risks detected across the fleet.';

  @override
  String briefingHeadline(int count, int total) {
    return '$count of $total vessels need attention.';
  }

  @override
  String get copySummary => 'Copy summary';

  @override
  String get summaryCopied => 'Summary copied';

  @override
  String get aiSummaryTitle => 'AI summary';

  @override
  String get generateAiSummary => 'Generate';

  @override
  String get aiRecommendationLabel =>
      'AI recommendation — human review required';

  @override
  String get briefingAiPrompt =>
      'Give me a short superintendent briefing from this snapshot: what is critical, what to follow up today, and a numbered list of recommended next steps. Use only the snapshot.';

  @override
  String get aiModeHelp => 'How to use';

  @override
  String get aiModeFleet => 'My fleet';

  @override
  String get aiFleetDisclaimer =>
      'Answers come from a summary of your fleet records (health scores and risks). Costs, crew personal data and attachments are never sent.';

  @override
  String get aiFleetGreeting =>
      'Ask about the fleet — for example: which vessel needs attention first, or why is a vessel\'s score low?';

  @override
  String get discrepancyDetected => 'Data discrepancy detected';

  @override
  String get alreadyOnRecord => 'Already on record';

  @override
  String get existingRecordLabel => 'Existing record';

  @override
  String get discrepancyHint =>
      'Accepting creates a new record. To correct the existing one, reject this and edit it in its own module.';
}
