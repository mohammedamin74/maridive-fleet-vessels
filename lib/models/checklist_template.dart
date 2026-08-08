/// How a form's tick grid is laid out. Each value maps to a different set of
/// slots per item, which is the only structural difference between the
/// engine department's controlled forms.
enum ChecklistGrid {
  /// One yes/no tick per item, plus remarks (FLT-FM-009).
  yesNo,

  /// Four slots — one per week of the month (TCH.FM.009+A1).
  weeksOfMonth,

  /// One slot per calendar day (EN.FM.008).
  daysOfMonth,
}

/// How often an item is due. Only the critical-equipment form states this
/// per item; the routine forms take their interval from the grid itself.
enum ChecklistInterval { weekly, monthly }

/// One printed line of a form: its number, bilingual text, and — for the
/// critical-equipment checklist — how often it is due.
///
/// The dates a check was actually carried out are NOT part of the template:
/// they differ every month and are entered by the vessel on that month's
/// sheet (see [ChecklistRun.dates]).
class ChecklistTemplateItem {
  final int no;
  final String en;
  final String ar;
  final ChecklistInterval? interval;

  const ChecklistTemplateItem({
    required this.no,
    required this.en,
    required this.ar,
    this.interval,
  });

  /// Stable key for storing this item's result in a run. Uses the printed
  /// number so a run keeps pointing at the right line even if wording is
  /// corrected later.
  String get key => 'i$no';
}

/// A controlled form as printed by the office: its code, revision details,
/// bilingual title, grid type and item list. Templates are compiled-in data
/// (see data/checklist_templates.dart), not user-editable records — the
/// office owns these documents.
class ChecklistTemplate {
  final String code;
  final String titleEn;
  final String titleAr;
  final String revNo;
  final String revDate;
  final ChecklistGrid grid;
  final List<ChecklistTemplateItem> items;

  const ChecklistTemplate({
    required this.code,
    required this.titleEn,
    required this.titleAr,
    required this.revNo,
    required this.revDate,
    required this.grid,
    required this.items,
  });

  /// Number of tick slots per item for a given month.
  int slotCount(int year, int month) => switch (grid) {
        ChecklistGrid.yesNo => 1,
        ChecklistGrid.weeksOfMonth => 4,
        ChecklistGrid.daysOfMonth => DateTime(year, month + 1, 0).day,
      };
}
