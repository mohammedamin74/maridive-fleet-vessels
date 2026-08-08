import '../models/checklist_template.dart';

/// The engine department's controlled forms, transcribed from the office
/// originals so the app produces exactly the same document. Item text,
/// numbering, order, form codes and revision details are all as printed —
/// changing them here changes the issued form, so treat this as a
/// controlled document, not ordinary code.
///
/// Sources:
///   FLT-FM-009      Critical Equipment Checklists Engine (Rev 1, 05/01/2018)
///   TCH.FM.009+A1   Weekly Routine Maintenance
///   EN.FM.008       Daily Routine Maintenance (loaded into Daily Tasks)
abstract final class ChecklistTemplates {
  /// Critical equipment checks: each item is due either weekly or monthly.
  /// The dates it was actually done are entered per month on the run sheet,
  /// not fixed here.
  static const criticalEquipment = ChecklistTemplate(
    code: 'FLT-FM-009',
    titleEn: 'Critical Equipment Checklists Engine',
    titleAr: 'قائمة فحص المعدات الحرجة',
    revNo: '1',
    revDate: '05/01/2018',
    grid: ChecklistGrid.yesNo,
    items: [
      ChecklistTemplateItem(no: 1, en: 'Bilge Alarm', ar: 'انذار الســرتينة', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 2, en: 'Fuel Oil Quick Closing', ar: 'نظام الغلق السريع للوقود', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 3, en: 'Remote Stops', ar: 'الإيقاف عن بعد', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 4, en: 'Main Engine Emergency Stop', ar: 'الإيقاف الاضطراري للماكينات الرئيسية', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 5, en: 'Auxiliary Emergency Stop', ar: 'الإيقاف الاضطراري للماكينات المساعدة', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 6, en: 'Main Engine Alarm', ar: 'انذارات الماكينات الرئيسية', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 7, en: 'Main Engine Shut Down', ar: 'ايقاف الماكينات الرئيسية', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 8, en: 'Auxiliary Alarms', ar: 'انذارات الآلات المساعدة', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 9, en: 'Auxiliary Shut Down', ar: 'ايقاف الآلات المساعدة', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 10, en: 'Bulk System Emergency Stop', ar: 'الأيقاف الأضطراري لمنظومة الأسمنت', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 11, en: 'CO2 Sys. Alarm', ar: 'انذارمحطة ثانى أوكسيد الكربون', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 12, en: 'Engine Room Vent Flaps', ar: 'ابواب تهوية غرفة الآلا ت', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 13, en: 'Accommodation Ventilation Flaps', ar: 'ابواب تهوية حيز الإعاشة', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 14, en: 'Emergency Steering/ Inert Gas Alarms', ar: 'التوجيه الإحتياطي للدفه- الإنذار العام للغاز', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 15, en: 'Watertight door', ar: 'تجربه الابواب المانعه لنفاذ المياه', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 16, en: 'Emergency Batteries', ar: 'بطاريات الطوار ئ', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 17, en: 'Engine Room Telegraph', ar: 'تلغراف غرفة الآلا ت', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 18, en: 'Remote Engine Room Alarms', ar: 'انذارات غرفة الآلا ت', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 19, en: 'Fire Detection', ar: 'اكتشاف الحريق', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 20, en: 'Fire Alarms', ar: 'انذار الحريق', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 21, en: 'Crew General Alarms', ar: 'الإنذار العام للطاقم', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 22, en: 'Person inside of Ref', ar: 'انذار وجود شخص داخل الثلاجه', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 23, en: 'Emergency Fire Pump', ar: 'طلمبة الحريق', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 24, en: 'Emergency Generator', ar: 'مولد الطوارئ', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 25, en: 'Emergency Air Compressor NO2', ar: 'ضاغط هواء الطوارئ رقم 2', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 26, en: 'Bunker Overflow Tank Alarm', ar: 'انذار الفائض لتنكات مخلفات الزيو ت', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 27, en: 'Oil Drain Tank Alarm', ar: 'انذار الفائض لتنكات الوقود', interval: ChecklistInterval.monthly),
      ChecklistTemplateItem(no: 28, en: 'Main Fire Pump', ar: 'طلمبة الحريق الرئيسية', interval: ChecklistInterval.weekly),
      ChecklistTemplateItem(no: 29, en: 'Emergency Escape Breathing Device', ar: 'أجهزة تنفس للهروب أثناء الطوار ئ', interval: ChecklistInterval.weekly),
    ],
  );

  /// Weekly routine maintenance: every item is ticked once per week of the
  /// month, or marked not applicable for this vessel.
  static const weeklyRoutine = ChecklistTemplate(
    code: 'TCH.FM.009+A1',
    titleEn: 'Weekly Routine Maintenance',
    titleAr: 'بنود الروتين الاسبوعى',
    revNo: '',
    revDate: '',
    grid: ChecklistGrid.weeksOfMonth,
    items: [
      ChecklistTemplateItem(no: 1, en: 'CLEAN FUEL & LUBRICATING OIL PURIFIERS', ar: 'نظافة منقي الوقود وازيت'),
      ChecklistTemplateItem(no: 2, en: 'CLEAN FUEL FILTERS', ar: 'نظافة فلاتر الوقود'),
      ChecklistTemplateItem(no: 3, en: 'CLEAN A/C AIR FILTERS', ar: 'نظافة فلاتر هواء التكيف'),
      ChecklistTemplateItem(no: 4, en: 'CLEAN GALLEY FILTERS', ar: 'نظافة فلاتر شفاط المطبخ'),
      ChecklistTemplateItem(no: 5, en: 'CLEAN SEA CHEST FILTERS', ar: 'نظافة فلاتر البحر'),
      ChecklistTemplateItem(no: 6, en: 'GREASE PUMPS (FRESH WATER, BALLAST, FIRE, FUEL & BILGE)', ar: 'تشحيم طلمبات المياه العذبة والمالحة والوقود والحريق والبلاست والسنتينة'),
      ChecklistTemplateItem(no: 7, en: 'GREASE RUDDERS, TOWING WINCH, ANCHOR WINDLASS & DECK CRANE', ar: 'تشحيم الدفف وونش المخطاف وونش القطر وونش السطح'),
      ChecklistTemplateItem(no: 8, en: 'LUBRICATE FUEL RACKS AND GOVERNOR ARMS FOR BOTH DIESEL GENERATORS & MAIN ENGINES', ar: 'تزييت اذرع طلمبات الوقود والجفرنر للماكينات الرئيسية والديازل'),
      ChecklistTemplateItem(no: 9, en: 'TEST BILGE HIGH LEVEL ALARMS', ar: 'اختبار انذار ارتفاع مستوي السنتينة'),
      ChecklistTemplateItem(no: 10, en: 'TEST SHARK JAW & TOWING PINS', ar: 'تجربة الشارك جو –وبنوز القطر'),
      ChecklistTemplateItem(no: 11, en: 'TEST ANCHOR HANDLING &TOWING WINCH', ar: 'تجربة ونش القطر وتداول المخاطيف'),
      ChecklistTemplateItem(no: 12, en: 'TEST BULK SYSTEM AND EASE ALL THE VALVES', ar: 'تجربة منظومة الاسمنت وتلين البلوف'),
      ChecklistTemplateItem(no: 13, en: 'CHECK BATTERIES CLEANLINESS, ELECTROLYTE LEVEL & DENSITY', ar: 'التاكد من مستوي الحامض وكثافة ونظافة البطاريات'),
      ChecklistTemplateItem(no: 14, en: 'INSPECT MAIN FIRE PUMP', ar: 'الكشف علي طلمبة الحريق الرئيسية'),
      ChecklistTemplateItem(no: 15, en: 'INSPECT MAIN FIRE PUMP CLUTCH', ar: 'الكشف علي تعشيقة طلمبة الحريق الرئيسية'),
      ChecklistTemplateItem(no: 16, en: 'TEST & TRIAL OF FI-FI MONITORSأ', ar: 'اختبار وتجربة منظومة توجيه مدافع الحريق'),
      ChecklistTemplateItem(no: 17, en: 'TEST FIRE FIGHTING PUMP', ar: 'تجربة طلمبة الحريق الطوارئ'),
      ChecklistTemplateItem(no: 18, en: 'TEST PORTABLE FIRE FIGHTING PUMP', ar: 'تجربة طلمبة الحريق النقالي'),
      ChecklistTemplateItem(no: 19, en: 'TEST PORTABLE EXTINGUISHER', ar: 'الكشف علي طفايات الحريق النقالي'),
      ChecklistTemplateItem(no: 20, en: 'TEST FIRE FIGHTING DEVICES', ar: 'الكشف علي معدات مكافحة الحريق'),
      ChecklistTemplateItem(no: 21, en: 'CHECK CO2 SYSTEM CONATION AND JUNCTION', ar: 'فحص خراطيم ووصلات منظومة ثاني اكسيد الكربون'),
      ChecklistTemplateItem(no: 22, en: 'CHECK CO2 ALARM SYSTEM', ar: 'تجربة دائرة انذار منظومة ثاني اكسد الكربون'),
      ChecklistTemplateItem(no: 23, en: 'CHECK GAS, FLAME & TEMPERATURE DETECTORS', ar: 'اختبار منظومة مكتشفات الدخان والحرارة واللهب'),
      ChecklistTemplateItem(no: 24, en: 'CHECK RESCUE BOAT AND GREASING WINCH', ar: 'تجربة ماكينة قارب الانقاذ وتجربة وتشخيم البتافورة'),
      ChecklistTemplateItem(no: 25, en: 'CHECK M/E MAIN AND AUXILIARY PUMP', ar: 'تجربة طلمبات تجهيز الماكينات الرئيسية للتشغيل(الاساسية والاحطياطية)'),
      ChecklistTemplateItem(no: 26, en: 'TEST M/E ALARM SYSTEM', ar: 'اختبار دائرة انذار الماكينات الرئيسية'),
      ChecklistTemplateItem(no: 27, en: 'TEST D/G ALARM SYSTEM', ar: 'اختبار دائرة انذار الديازل'),
      ChecklistTemplateItem(no: 28, en: 'TEST AND CHECK EMERGENCY D/G', ar: 'تجربة وتشغيل ديزل الطوارئ'),
      ChecklistTemplateItem(no: 29, en: 'TEST DP SYSTEM', ar: 'DPتجربة نظام'),
      ChecklistTemplateItem(no: 30, en: 'CHECK EMERGENCY LIGHTING', ar: 'تجربة انارة الطوارئ'),
      ChecklistTemplateItem(no: 31, en: 'TEST, CLEAN AND GREASING ENGINE ROOM VENTS', ar: 'تالكشف علي هوايات غرفة الماكينات والنظافة والتشحيم'),
      ChecklistTemplateItem(no: 32, en: 'TEST CLOSING ACCOMMODATION VENT', ar: 'تجربة غلق ابواب هوايات الاعاشة'),
      ChecklistTemplateItem(no: 33, en: 'CHECK WTD SEALING RUBBER', ar: 'الكشف علي كاوتش الهاتشات والابواب المانعة للمياه'),
      ChecklistTemplateItem(no: 34, en: 'TEST CLOSING WTD', ar: 'تجربة غلق الابواب المانعة لنفاذ المياه'),
      ChecklistTemplateItem(no: 35, en: 'CHECK FAN AND PUMP BELT', ar: 'الكشف علي سيور الطلمبات والمراوح'),
      ChecklistTemplateItem(no: 36, en: 'CHECK ANTIPOLLUTION SYSTEM', ar: 'فحص نظام مكافحة التلوث'),
      ChecklistTemplateItem(no: 37, en: 'CHECK EMG. STOP FOR EMG. DISTRIBUTION PANEL', ar: 'فحص الايقاف الاضطراري للوحة توزيع الطوارئ'),
      ChecklistTemplateItem(no: 38, en: 'CHECK EMG. STOP FOR MAIN  DISTRIBUTION PANEL', ar: 'فحص الايقاف الاضطراري للوحة التوزيع الرئيسية'),
      ChecklistTemplateItem(no: 39, en: 'TEST QUICK CLOSING VALVE', ar: 'اختبار بلف الغلق السريع'),
      ChecklistTemplateItem(no: 40, en: 'TEST STEERING SYSTEM DURING IN EMG. CASE', ar: 'اختبار نظام التوجيه اثناء حالة الطوارئ'),
      ChecklistTemplateItem(no: 42, en: 'GREASING DOOR AND HATCHES', ar: 'تشحيم الهاتشات والباب'),
      ChecklistTemplateItem(no: 43, en: 'TEST AIR COMPRESSORS', ar: 'اختبار ضاغط الهواء'),
      ChecklistTemplateItem(no: 44, en: 'TEST FRESH WATER MAKER', ar: 'اختبار جهاز تحلية المياه'),
      ChecklistTemplateItem(no: 45, en: 'TEST OILY WATER SEPARATOR', ar: 'اختبار فاصل الزيوت عن الماء'),
      ChecklistTemplateItem(no: 46, en: 'TEST SEWAGE TREATMENT UNIT ALARM', ar: 'اختبار انذار وحدة معالجة الصرف الصحي'),
      ChecklistTemplateItem(no: 47, en: 'CHECK TRANSFORMER(AC,DC)', ar: 'الكشف علي المحولات (متردد , مستمر)'),
      ChecklistTemplateItem(no: 48, en: 'CHECK CABLE INSULATION', ar: 'الكشف علي عزل الكابلات'),
      ChecklistTemplateItem(no: 49, en: 'CHECK MAN IN COLD ROOM ALARM', ar: 'كشف انذار وجود شخص في الثلاجة'),
      ChecklistTemplateItem(no: 50, en: 'TEST BOW EMG. STOP', ar: 'اختبار ايقاف الطوارئ للرفاص التوجيه الامامي'),
      ChecklistTemplateItem(no: 51, en: 'TEST STERN THRUSTER EMG. STOP', ar: 'اختبار ايقاف الطوارئ لرفاص التوجيه اللخلفي'),
      ChecklistTemplateItem(no: 52, en: 'TEST ENGINE ROOM TELEGRAPH WITH BRIDGE', ar: 'اختبار تليغراف غرفة الآلات مع الممشي'),
      ChecklistTemplateItem(no: 53, en: 'TEST M/E EMG. STOP', ar: 'اختبار طوارئ غرفة الماكينات الرئيسية'),
      ChecklistTemplateItem(no: 54, en: 'CLEAN SEARCHLIGHT', ar: 'searchlightتنظيف كشاف'),
      ChecklistTemplateItem(no: 55, en: 'CLEAN M/E AND D/G TURBOCHARGER FILTER', ar: 'تنظيف فلاتر الهواء الخاصة بالماكينات الرئيسية والديازل'),
      ChecklistTemplateItem(no: 56, en: 'TEST PROPELLER BLADES EMG. OPERATION', ar: 'اختبار تشغيل الطوارئ للتحكم في ريش الرفاص'),
      ChecklistTemplateItem(no: 57, en: 'CHECK HOT WATER BOILER', ar: 'الكشف علي سخان المياه'),
      ChecklistTemplateItem(no: 58, en: 'TEST  ALL DECK MACHINERY', ar: 'تجربة كل معدات السطح'),
      ChecklistTemplateItem(no: 59, en: 'CHECK AND TEST DECK CRANE', ar: 'فحص وتجربة كل معدات ونش السطح'),
    ],
  );

  /// Daily routine maintenance. These load into the existing Daily Tasks
  /// module as one task's checklist rather than a separate screen — the
  /// engineer already does these as a daily round.
  static const dailyRoutine = ChecklistTemplate(
    code: 'EN.FM.008',
    titleEn: 'Daily Routine Maintenance',
    titleAr: 'بنود الروتين اليومى',
    revNo: '',
    revDate: '',
    grid: ChecklistGrid.daysOfMonth,
    items: [
      ChecklistTemplateItem(no: 1, en: 'Check bilges And watch its level', ar: 'المرور على السراتين و مراقبة مستواها'),
      ChecklistTemplateItem(no: 2, en: 'Check oil level in main engines', ar: 'قياس مستوى الزيوت في الماكينات الرئيسية'),
      ChecklistTemplateItem(no: 3, en: 'Check oil level in auxiliaries', ar: 'قياس مستوى الزيوت في المحركات المساعدة'),
      ChecklistTemplateItem(no: 4, en: 'Check oil level in hydraulic system', ar: 'قياس مستوى الزيوت في منظومة الهيدروليك'),
      ChecklistTemplateItem(no: 5, en: 'Check oil level in main engine reduction gears', ar: 'قياس مستوى الزيت فى مخفض سرعة الماكينات الرئيسية'),
      ChecklistTemplateItem(no: 6, en: 'Check main shaft bearings\' oil level', ar: 'قياس مستوى الزيت فى كراسى عمود الرفاص'),
      ChecklistTemplateItem(no: 7, en: 'Check stern tube\'s oil level', ar: 'قياس مستوى الزيت فى جلبة عمود الرفاص'),
      ChecklistTemplateItem(no: 8, en: 'Check CPP oil level', ar: 'قياس مستوى زيت ريش الرفاص المتحركة'),
      ChecklistTemplateItem(no: 9, en: 'Check steering gear\'s oil level', ar: 'قياس مستوى الزيت في منظومة الدفة'),
      ChecklistTemplateItem(no: 10, en: 'Check compressors’ oil level', ar: 'قياس مستوى الزيت بضواغط الهواء'),
      ChecklistTemplateItem(no: 11, en: 'Check stern thruster’s system oil level', ar: 'قياس مستوى الزيت لمنظومة رفاص التوجيه الخلفى'),
      ChecklistTemplateItem(no: 12, en: 'Check oil level for generators’ air starters', ar: 'قياس مستوى الزيت لمنظومة هواء بدء الحركة للديازل'),
      ChecklistTemplateItem(no: 13, en: 'Inspect main engines & auxiliaries for cracks or leakage', ar: 'فحص الماكينات الرئيسية و الالات المساعدة والتأكد من خلوها من الشروخ و التسييلات'),
      ChecklistTemplateItem(no: 14, en: 'Test conversion from auto-pilot to manual steering gear', ar: 'تجربة التحويل من نظام التوجيه الأوتوماتيكى الى اليدوى'),
      ChecklistTemplateItem(no: 15, en: 'Clean main engines, auxiliaries and the rest of equipment’s', ar: 'نظافة الماكينات الرئيسية و المساعدة وباقي الالات'),
      ChecklistTemplateItem(no: 16, en: 'Daily fuel and fresh water tank compensation', ar: 'أستعواض تنك التعويض اليومى للوقود والمياه'),
      ChecklistTemplateItem(no: 17, en: 'Drain air bottle and fuel daily tank from water 4 times a day', ar: 'تصفية زجاجات الهواء وتنك الخدمة اليومي من المياه 4مرات يوميا'),
      ChecklistTemplateItem(no: 18, en: 'Check & observe pipes , valves\' glands and connections of all systems', ar: 'فحص وملاحظة جلندات بلوف ومواسير ووصلات جميع منظومات وخطوط السفينة'),
      ChecklistTemplateItem(no: 19, en: 'Record refrigeration room’s temperature and ensure that the doors are closed tightly', ar: 'تسجيل ومتابعة درجة حرارة الثلاجة والتاكد من احكام غلق الباب'),
      ChecklistTemplateItem(no: 20, en: 'Liquid mud circulation and soften all the system’s valves', ar: 'تقليب الطفلة وتلين بلوف المنظومة 4مرات يوميا( ان وجد)'),
      ChecklistTemplateItem(no: 21, en: 'Manual turning of main engines, auxiliaries and fire pumps', ar: 'تقليب الماكينات الرئيسية والديازل وماكينات الحريق يدويا'),
      ChecklistTemplateItem(no: 22, en: 'Observe A\\C unit\'s temperature and pressure gauges', ar: 'مراقبة عدادات الحرارة والضغط الخاصة بوحدة التكييف وتسجيل القراءة'),
      ChecklistTemplateItem(no: 23, en: 'Check tightening of engine room’s hatches during sailing', ar: 'التاكد من احكام الهاتشات والابواب المانعة لنفاذ المياه اثناء الابحار المتواجدة داخل غرفة الماكينات'),
      ChecklistTemplateItem(no: 24, en: 'Ensure that all electrical equipment’s and switch board are clean from dust', ar: 'التاكد من نظافة الاجهزة الكهربائية ولوحة التوزيع من الاتربة'),
      ChecklistTemplateItem(no: 25, en: 'Ensure that all electrical control boxes are clean from dust', ar: 'التاكد من نظافة صناديق توزيع الكهرباء من الاتربة'),
      ChecklistTemplateItem(no: 26, en: 'Check electrical equipment’s voltage and current during operation', ar: 'مراقبة الفولت والامبير للاجهزة الكهربائية اثناء التشغيل'),
      ChecklistTemplateItem(no: 27, en: 'Test the communication between the bridge, engine control room steering room', ar: 'تجربة الاتصالات بين الممشي وغرفة الماكينات وغرفة الدومان'),
    ],
  );

  /// Forms that get their own monthly run sheet in the checklists module.
  static const all = [criticalEquipment, weeklyRoutine];
}
