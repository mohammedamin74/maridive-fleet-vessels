class ChecklistItem {
  final String label;
  final bool checked;
  final String comment;

  const ChecklistItem(
      {required this.label, this.checked = false, this.comment = ''});

  ChecklistItem copyWith({bool? checked, String? comment}) => ChecklistItem(
        label: label,
        checked: checked ?? this.checked,
        comment: comment ?? this.comment,
      );

  Map<String, dynamic> toMap() =>
      {'label': label, 'checked': checked, 'comment': comment};

  factory ChecklistItem.fromMap(Map<dynamic, dynamic> map) => ChecklistItem(
        label: map['label'] as String,
        checked: (map['checked'] as bool?) ?? false,
        comment: (map['comment'] as String?) ?? '',
      );
}
