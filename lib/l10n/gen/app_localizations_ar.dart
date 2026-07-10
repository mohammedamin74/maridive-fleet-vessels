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
  String get aboutBody => 'يساعد تطبيق أسطول ماريديف الطواقم وموظفي الشاطئ على مراقبة مستويات خزانات الوقود والطين والتشحيم والهيدروليك عبر أسطول سفن الدعم البحري العاملة في ليبيا.';

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
}
