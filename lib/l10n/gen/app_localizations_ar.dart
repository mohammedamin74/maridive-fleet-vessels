// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أسطول ماريديف';

  @override
  String get dashboardTitle => 'لوحة تحكم الأسطول';

  @override
  String get dashboardSubtitle => 'سفن الدعم البحري · ليبيا';

  @override
  String get fleetOverview => 'نظرة عامة على الأسطول';

  @override
  String get totalVessels => 'السفن';

  @override
  String get activeVessels => 'نشطة';

  @override
  String get inPort => 'في الميناء';

  @override
  String get underMaintenance => 'صيانة';

  @override
  String get avgFuelLevel => 'متوسط الوقود';

  @override
  String get statusActive => 'نشطة';

  @override
  String get statusStandby => 'احتياط';

  @override
  String get statusInPort => 'في الميناء';

  @override
  String get statusMaintenance => 'صيانة';

  @override
  String get searchVessels => 'البحث عن سفينة...';

  @override
  String get noResults => 'لا توجد سفن مطابقة لبحثك';

  @override
  String get filterAll => 'الكل';

  @override
  String get fleetLabel => 'الأسطول';

  @override
  String get statusOffHire => 'خارج الخدمة';

  @override
  String get workingPort => 'ميناء العمل';

  @override
  String get editVessel => 'تعديل السفينة';

  @override
  String get vesselStatusLabel => 'الحالة';

  @override
  String get maintenance => 'الصيانة';

  @override
  String get addMaintenance => 'إضافة صيانة';

  @override
  String get noMaintenance => 'لا توجد سجلات صيانة';

  @override
  String get maintenanceTitleLabel => 'عنوان العمل';

  @override
  String get maintenanceDescLabel => 'الوصف';

  @override
  String get performedByLabel => 'نُفّذ بواسطة';

  @override
  String get maintenanceDueLabel => 'الاستحقاق';

  @override
  String get maintStatusPlanned => 'مخطط';

  @override
  String get maintStatusInProgress => 'قيد التنفيذ';

  @override
  String get maintStatusCompleted => 'مكتمل';

  @override
  String get vesselDetails => 'تفاصيل السفينة';

  @override
  String get imoNumber => 'رقم IMO';

  @override
  String get vesselType => 'نوع السفينة';

  @override
  String get homePort => 'الميناء الرئيسي';

  @override
  String get crewOnBoard => 'الطاقم على متن السفينة';

  @override
  String get lastUpdated => 'آخر تحديث';

  @override
  String get tankSystems => 'أنظمة الخزانات';

  @override
  String get categoryFuelOil => 'خزانات وقود الديزل';

  @override
  String get categoryBrineMud => 'خزانات المحلول الملحي / الطين';

  @override
  String get categoryLubeHydraulic => 'زيت التشحيم والهيدروليك';

  @override
  String get categoryOther => 'خزانات أخرى';

  @override
  String get categorySoundingTables => 'جداول السبر';

  @override
  String tanksInCategory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خزان',
      many: '$count خزانًا',
      few: '$count خزانات',
      two: 'خزانان',
      one: 'خزان واحد',
      zero: 'لا خزانات',
    );
    return '$_temp0';
  }

  @override
  String get selectTank => 'اختر الخزان';

  @override
  String get tankLevel => 'مستوى الخزان';

  @override
  String get tankPercent => 'نسبة الخزان';

  @override
  String get capacity => 'السعة';

  @override
  String get currentVolume => 'الحجم الحالي';

  @override
  String get pumpCalculator => 'حاسبة الضخ';

  @override
  String get quantityToPumpOut => 'الكمية المراد ضخها';

  @override
  String get stopPumpingAtLevel => 'إيقاف الضخ عند المستوى';

  @override
  String get remainingAfterPumping => 'المتبقي بعد الضخ';

  @override
  String get calculate => 'احسب';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get enterAValue => 'أدخل قيمة';

  @override
  String soundingTableTitle(String tank) {
    return '$tank — جدول السبر';
  }

  @override
  String get levelCm => 'المستوى (سم)';

  @override
  String get volumeM3 => 'الحجم (م³)';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get theme => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get about => 'حول التطبيق';

  @override
  String get aboutBody =>
      'يساعد تطبيق أسطول ماريديف الطواقم وموظفي الشاطئ على مراقبة مستويات خزانات الوقود والطين والتشحيم والهيدروليك عبر أسطول سفن الدعم البحري العاملة في ليبيا.';

  @override
  String get back => 'رجوع';

  @override
  String get close => 'إغلاق';

  @override
  String get gallons => 'غالون';

  @override
  String get cubicMeters => 'م³';

  @override
  String get percent => '٪';

  @override
  String get updateLevel => 'تحديث المستوى الحالي';

  @override
  String get newReading => 'قراءة جديدة';

  @override
  String get saveReading => 'حفظ';

  @override
  String get noReadingsYet => 'لا توجد قراءات بعد';

  @override
  String get viewHistory => 'عرض سجل القراءات';

  @override
  String get readingHistory => 'سجل القراءات';

  @override
  String get noHistory => 'لم يتم تسجيل أي قراءات بعد';

  @override
  String get criticalLevel => 'حرج';

  @override
  String get warningLevel => 'تحذير';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String alertsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خزان يحتاج انتباه',
      many: '$count خزانًا يحتاج انتباه',
      few: '$count خزانات تحتاج انتباه',
      two: 'خزانان يحتاجان انتباه',
      one: 'خزان واحد يحتاج انتباه',
      zero: 'لا توجد خزانات تحتاج انتباه',
    );
    return '$_temp0';
  }

  @override
  String get logbook => 'سجل السفينة';

  @override
  String get addNoteHint => 'أضف ملاحظة...';

  @override
  String get noNotes => 'لا توجد ملاحظات بعد';

  @override
  String get exportReport => 'تصدير التقرير';

  @override
  String get vesselOperations => 'عمليات السفينة';

  @override
  String get viewEntries => 'عرض السجلات';

  @override
  String get tankStatusPdf => 'تقرير حالة الخزانات PDF';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String openCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مفتوحة',
      many: '$count مفتوحة',
      few: '$count مفتوحة',
      two: '٢ مفتوحة',
      one: '١ مفتوح',
      zero: 'لا توجد مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count معلقة',
      many: '$count معلقة',
      few: '$count معلقة',
      two: '٢ معلقة',
      one: '١ معلق',
      zero: 'لا توجد معلقة',
    );
    return '$_temp0';
  }

  @override
  String get defects => 'الأعطال';

  @override
  String get addDefect => 'الإبلاغ عن عطل';

  @override
  String get defectTitleLabel => 'العنوان';

  @override
  String get defectDescriptionLabel => 'الوصف';

  @override
  String get severityLabel => 'الخطورة';

  @override
  String get severityMinor => 'بسيط';

  @override
  String get severityMajor => 'كبير';

  @override
  String get severityCritical => 'حرج';

  @override
  String get statusOpenDefect => 'مفتوح';

  @override
  String get statusInProgress => 'قيد المعالجة';

  @override
  String get statusClosedDefect => 'مغلق';

  @override
  String get noDefects => 'لا توجد أعطال مسجلة';

  @override
  String get reportedOn => 'تاريخ الإبلاغ';

  @override
  String get markInProgress => 'قيد المعالجة';

  @override
  String get markClosed => 'إغلاق';

  @override
  String get reopen => 'إعادة فتح';

  @override
  String criticalDefectsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عطل حرج',
      many: '$count عطلاً حرجًا',
      few: '$count أعطال حرجة',
      two: 'عطلان حرجان',
      one: 'عطل حرج واحد',
      zero: 'لا توجد أعطال حرجة',
    );
    return '$_temp0';
  }

  @override
  String get requisitions => 'طلبات التوريد';

  @override
  String get addRequisition => 'طلب توريد جديد';

  @override
  String get itemNameLabel => 'اسم الصنف';

  @override
  String get quantityLabel => 'الكمية';

  @override
  String get unitLabel => 'الوحدة';

  @override
  String get notesLabel => 'ملاحظات (اختياري)';

  @override
  String get priorityLabel => 'الأولوية';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityNormal => 'عادية';

  @override
  String get priorityUrgent => 'عاجلة';

  @override
  String get reqStatusPending => 'قيد الانتظار';

  @override
  String get reqStatusApproved => 'معتمد';

  @override
  String get reqStatusOrdered => 'تم الطلب';

  @override
  String get reqStatusReceived => 'تم الاستلام';

  @override
  String get reqStatusRejected => 'مرفوض';

  @override
  String get noRequisitions => 'لا توجد طلبات توريد بعد';

  @override
  String get requestedOn => 'تاريخ الطلب';

  @override
  String get markApproved => 'اعتماد';

  @override
  String get markOrdered => 'تحديد كـ تم الطلب';

  @override
  String get markReceived => 'تحديد كـ تم الاستلام';

  @override
  String get markRejected => 'رفض';

  @override
  String get priorityMedium => 'متوسطة';

  @override
  String get priorityHigh => 'عالية';

  @override
  String get locationLabel => 'الموقع';

  @override
  String get locationEngineRoom => 'غرفة المحركات';

  @override
  String get locationDeck => 'السطح';

  @override
  String get locationBridge => 'جسر القيادة';

  @override
  String get locationAccommodation => 'أماكن الإقامة';

  @override
  String get locationGalley => 'المطبخ';

  @override
  String get locationOther => 'أخرى';

  @override
  String get assignedOfficerLabel => 'الضابط المسؤول';

  @override
  String get requiredSparePartsLabel => 'قطع الغيار المطلوبة';

  @override
  String get actionTakenLabel => 'الإجراء المتخذ';

  @override
  String get partNumberLabel => 'رقم القطعة';

  @override
  String get oemLabel => 'الشركة المصنّعة';

  @override
  String get stockLabel => 'الكمية بالمخزون';

  @override
  String get unitPriceLabel => 'سعر الوحدة';

  @override
  String get departmentLabel => 'القسم';

  @override
  String get departmentEngine => 'المحركات';

  @override
  String get departmentDeck => 'السطح';

  @override
  String get departmentSteward => 'الإعاشة';

  @override
  String get requiredDeliveryLabel => 'تاريخ التسليم المطلوب';

  @override
  String get reqStatusHod => 'اعتماد رئيس القسم';

  @override
  String get reqStatusTechSup => 'اعتماد المشرف الفني';

  @override
  String get markHodApproval => 'تحديد كـ معتمد من رئيس القسم';

  @override
  String get markTechSupApproval => 'تحديد كـ معتمد من المشرف الفني';

  @override
  String get temperatureLabel => 'درجة الحرارة (°م)';

  @override
  String get lastSounding => 'آخر قياس';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة واحدة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة واحدة',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم واحد',
      zero: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String get soundingHistory24h => 'سجل القياسات';

  @override
  String get overfillCritical => 'حرج (فيضان)';

  @override
  String get overfillWarning => 'تحذير (فيضان)';

  @override
  String get portCalls => 'زيارات الموانئ';

  @override
  String get noPortCalls => 'لا توجد زيارات موانئ مجدولة';

  @override
  String get addPortCall => 'إضافة زيارة ميناء';

  @override
  String get portNameLabel => 'اسم الميناء';

  @override
  String get arrivalEtaLabel => 'الوقت المتوقع للوصول';

  @override
  String get pilotBoardingLabel => 'وقت صعود المرشد';

  @override
  String get agentLabel => 'اسم الوكيل';

  @override
  String get agentContactLabel => 'بيانات التواصل مع الوكيل';

  @override
  String get mgoRequiredLabel => 'الوقود المطلوب MGO (م³)';

  @override
  String get hfoRequiredLabel => 'الوقود المطلوب HFO (م³)';

  @override
  String get freshWaterRequiredLabel => 'المياه العذبة المطلوبة (م³)';

  @override
  String get provisionsRequiredLabel => 'المؤن المطلوبة';

  @override
  String get sludgeDisposalLabel => 'التخلص من الحمأة مطلوب';

  @override
  String get sludgeQuantityLabel => 'كمية الحمأة (م³)';

  @override
  String get portStatusUpcoming => 'قادمة';

  @override
  String get portStatusArrived => 'وصلت';

  @override
  String get portStatusDeparted => 'غادرت';

  @override
  String get customsChecklistLabel => 'قائمة الجمارك والمستندات';

  @override
  String get certification => 'الشهادات';

  @override
  String get vesselCerts => 'شهادات السفينة';

  @override
  String get crewCerts => 'شهادات الطاقم';

  @override
  String get addVesselCert => 'إضافة شهادة سفينة';

  @override
  String get addCrewCert => 'إضافة شهادة طاقم';

  @override
  String get documentNameLabel => 'اسم المستند';

  @override
  String get issuingAuthorityLabel => 'جهة الإصدار';

  @override
  String get issueDateLabel => 'تاريخ الإصدار';

  @override
  String get expiryDateLabel => 'تاريخ الانتهاء';

  @override
  String get officerNameLabel => 'اسم الضابط';

  @override
  String get rankLabel => 'الرتبة';

  @override
  String get certTypeLabel => 'نوع الشهادة';

  @override
  String get certTypeCoc => 'شهادة الكفاءة COC';

  @override
  String get certTypeStcw => 'STCW';

  @override
  String get certTypeMedical => 'شهادة طبية';

  @override
  String get certTypeOther => 'أخرى';

  @override
  String get noCertificates => 'لا توجد شهادات مسجلة';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get addFile => 'إضافة ملف';

  @override
  String get attachmentsLabel => 'المرفقات';

  @override
  String get urgentNotifications => 'الإشعارات العاجلة';

  @override
  String get noUrgentNotifications => 'لا توجد إشعارات عاجلة';

  @override
  String get addUrgentNotification => 'رفع إشعار عاجل';

  @override
  String get alertTypeLabel => 'نوع الحادث';

  @override
  String get alertTypeFire => 'حريق';

  @override
  String get alertTypeFlooding => 'غمر بالمياه';

  @override
  String get alertTypeEngineFailure => 'عطل بالمحرك';

  @override
  String get alertTypeRouting => 'مسار الملاحة';

  @override
  String get alertTypeOther => 'أخرى';

  @override
  String get locationOnVesselLabel => 'الموقع على متن السفينة';

  @override
  String get escalationNotAcknowledged => 'لم يتم الإقرار';

  @override
  String get escalationAcknowledged => 'تم الإقرار';

  @override
  String get escalationResolved => 'تم الحل';

  @override
  String get markAcknowledged => 'تحديد كـ تم الإقرار';

  @override
  String get markResolved => 'تحديد كـ تم الحل';

  @override
  String get raiseAlert => 'رفع الإشعار';

  @override
  String urgentAlertsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشعار عاجل',
      many: '$count إشعارًا عاجلًا',
      few: '$count إشعارات عاجلة',
      two: 'إشعاران عاجلان',
      one: 'إشعار عاجل واحد',
      zero: 'لا توجد إشعارات عاجلة',
    );
    return '$_temp0';
  }

  @override
  String get dailyTasks => 'المهام اليومية';

  @override
  String get noDailyTasks => 'لا توجد مهام يومية بعد';

  @override
  String get addDailyTask => 'إضافة مهمة يومية';

  @override
  String get taskCategoryLabel => 'فئة المهمة';

  @override
  String get categoryEngineRoomRounds => 'جولات غرفة المحركات';

  @override
  String get categoryDeckRounds => 'جولات السطح';

  @override
  String get categorySafetyEquipment => 'فحص معدات السلامة';

  @override
  String get categoryNavigationEquipment => 'اختبار معدات الملاحة';

  @override
  String get categoryGalleyHygiene => 'فحص نظافة المطبخ';

  @override
  String get taskTitleLabel => 'عنوان المهمة';

  @override
  String get assignedToLabel => 'مسندة إلى';

  @override
  String get frequencyLabel => 'التكرار';

  @override
  String get frequencyDaily => 'يوميًا';

  @override
  String get frequencyEveryWatch => 'كل وردية';

  @override
  String get frequencyWeekly => 'أسبوعيًا';

  @override
  String get scheduledTimeLabel => 'الوقت المجدول';

  @override
  String get checklistItemsLabel => 'بنود القائمة';

  @override
  String get checklistItemsHint => 'بند واحد في كل سطر';

  @override
  String get taskStatusPending => 'معلقة';

  @override
  String get taskStatusCompleted => 'مكتملة';

  @override
  String get taskStatusOverdue => 'متأخرة';

  @override
  String get commentHint => 'تعليق (اختياري)';

  @override
  String get evidencePhotosLabel => 'صور إثبات التنفيذ';

  @override
  String get markCompleted => 'تحديد كـ مكتملة';

  @override
  String upcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قادمة',
      many: '$count قادمة',
      few: '$count قادمة',
      two: '٢ قادمة',
      one: '١ قادمة',
      zero: 'لا توجد قادمة',
    );
    return '$_temp0';
  }

  @override
  String unacknowledgedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count غير مُقرّة',
      many: '$count غير مُقرّة',
      few: '$count غير مُقرّة',
      two: '٢ غير مُقرّة',
      one: '١ غير مُقرّ',
      zero: 'لا توجد غير مُقرّة',
    );
    return '$_temp0';
  }

  @override
  String overdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count متأخرة',
      many: '$count متأخرة',
      few: '$count متأخرة',
      two: '٢ متأخرة',
      one: '١ متأخرة',
      zero: 'لا توجد متأخرة',
    );
    return '$_temp0';
  }
}
