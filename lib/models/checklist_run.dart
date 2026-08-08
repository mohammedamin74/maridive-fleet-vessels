import 'attachment.dart';

/// Result of one tick slot. [notApplicable] is a real answer on these forms
/// ("N/A" is printed for equipment a vessel doesn't carry) and must not be
/// confused with [pending], which means nobody has checked it yet.
enum SlotResult { pending, done, notApplicable, failed }

/// One vessel's filled-in copy of a controlled form for one month —
/// the app's equivalent of the printed sheet the Chief Engineer signs.
///
/// Results are stored as `{itemKey: {slotIndex: result}}` so the same record
/// shape serves a yes/no form, a four-week grid and a 31-day grid without
/// changing the table.
class ChecklistRun {
  final String id;
  final String vesselId;

  /// Form code (FLT-FM-009, TCH.FM.009+A1, …) — identifies the template.
  final String templateCode;
  final int year;
  final int month;
  final Map<String, Map<int, SlotResult>> results;

  /// Dates each check was actually carried out this month, as the engineer
  /// writes them on the sheet ("4-11-18-25" for a weekly item, "12" for a
  /// monthly one). Per-run, never fixed by the form.
  final Map<String, String> dates;
  final Map<String, String> remarks;
  final String chiefEngineer;

  /// Set when the Chief Engineer signs the sheet off; null while it's a
  /// working draft the vessel is still ticking through the month.
  final DateTime? submittedAt;
  final List<Attachment> attachments;
  final DateTime createdAt;

  const ChecklistRun({
    required this.id,
    required this.vesselId,
    required this.templateCode,
    required this.year,
    required this.month,
    this.results = const {},
    this.dates = const {},
    this.remarks = const {},
    this.chiefEngineer = '',
    this.submittedAt,
    this.attachments = const [],
    required this.createdAt,
  });

  bool get isSubmitted => submittedAt != null;

  SlotResult resultFor(String itemKey, int slot) =>
      results[itemKey]?[slot] ?? SlotResult.pending;

  /// Slots actually answered (done, N/A or failed) out of the total — drives
  /// the completion figure shown to the superintendent.
  (int done, int total) progress(int itemCount, int slotCount) {
    var done = 0;
    for (final item in results.values) {
      for (final r in item.values) {
        if (r != SlotResult.pending) done++;
      }
    }
    return (done, itemCount * slotCount);
  }

  ChecklistRun copyWith({
    Map<String, Map<int, SlotResult>>? results,
    Map<String, String>? dates,
    Map<String, String>? remarks,
    String? chiefEngineer,
    DateTime? submittedAt,
    bool clearSubmitted = false,
    List<Attachment>? attachments,
  }) =>
      ChecklistRun(
        id: id,
        vesselId: vesselId,
        templateCode: templateCode,
        year: year,
        month: month,
        results: results ?? this.results,
        dates: dates ?? this.dates,
        remarks: remarks ?? this.remarks,
        chiefEngineer: chiefEngineer ?? this.chiefEngineer,
        submittedAt: clearSubmitted ? null : (submittedAt ?? this.submittedAt),
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'templateCode': templateCode,
        'year': year,
        'month': month,
        'results': {
          for (final e in results.entries)
            e.key: {
              for (final s in e.value.entries) s.key.toString(): s.value.name
            }
        },
        'dates': dates,
        'remarks': remarks,
        'chiefEngineer': chiefEngineer,
        'submittedAt': submittedAt?.toIso8601String(),
        'attachments': Attachment.listToMap(attachments),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChecklistRun.fromMap(Map<dynamic, dynamic> map) {
    final rawResults = (map['results'] as Map?) ?? const {};
    final results = <String, Map<int, SlotResult>>{};
    rawResults.forEach((itemKey, slots) {
      final parsed = <int, SlotResult>{};
      (slots as Map).forEach((slot, value) {
        final index = int.tryParse(slot.toString());
        if (index == null) return;
        parsed[index] = SlotResult.values.asNameMap()[value.toString()] ??
            SlotResult.pending;
      });
      results[itemKey.toString()] = parsed;
    });

    return ChecklistRun(
      id: map['id'] as String,
      vesselId: map['vesselId'] as String,
      templateCode: (map['templateCode'] as String?) ?? '',
      year: (map['year'] as num?)?.toInt() ?? 0,
      month: (map['month'] as num?)?.toInt() ?? 1,
      results: results,
      dates: {
        for (final e in ((map['dates'] as Map?) ?? const {}).entries)
          e.key.toString(): e.value.toString()
      },
      remarks: {
        for (final e in ((map['remarks'] as Map?) ?? const {}).entries)
          e.key.toString(): e.value.toString()
      },
      chiefEngineer: (map['chiefEngineer'] as String?) ?? '',
      submittedAt: DateTime.tryParse((map['submittedAt'] as String?) ?? ''),
      attachments: Attachment.listFromMap(map),
      createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
