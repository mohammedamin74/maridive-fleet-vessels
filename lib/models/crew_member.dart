/// Whether a crew member is currently aboard or has signed off (history).
enum CrewStatus { current, previous }

/// A single crew member on a vessel (Request 6). Moving someone to the
/// "Previous Crew List" flips [status] to [CrewStatus.previous] and stamps a
/// [signOffDate] — records are never deleted on sign-off, so crew history is
/// preserved. Deliberately stores minimal personal data (no passport numbers).
class CrewMember {
  final String id;
  final String vesselId;
  final String name;
  final String rank;
  final String nationality;
  final CrewStatus status;
  final DateTime signOnDate;
  final DateTime? signOffDate;
  final String notes;
  final DateTime createdAt;

  const CrewMember({
    required this.id,
    required this.vesselId,
    required this.name,
    this.rank = '',
    this.nationality = '',
    this.status = CrewStatus.current,
    required this.signOnDate,
    this.signOffDate,
    this.notes = '',
    required this.createdAt,
  });

  CrewMember copyWith({
    String? name,
    String? rank,
    String? nationality,
    CrewStatus? status,
    DateTime? signOnDate,
    DateTime? signOffDate,
    bool clearSignOff = false,
    String? notes,
  }) =>
      CrewMember(
        id: id,
        vesselId: vesselId,
        name: name ?? this.name,
        rank: rank ?? this.rank,
        nationality: nationality ?? this.nationality,
        status: status ?? this.status,
        signOnDate: signOnDate ?? this.signOnDate,
        signOffDate: clearSignOff ? null : (signOffDate ?? this.signOffDate),
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'name': name,
        'rank': rank,
        'nationality': nationality,
        'status': status.name,
        'signOnDate': signOnDate.toIso8601String(),
        'signOffDate': signOffDate?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CrewMember.fromMap(Map<dynamic, dynamic> map) => CrewMember(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        name: (map['name'] as String?) ?? '',
        rank: (map['rank'] as String?) ?? '',
        nationality: (map['nationality'] as String?) ?? '',
        status:
            CrewStatus.values.byName((map['status'] as String?) ?? 'current'),
        signOnDate: DateTime.tryParse((map['signOnDate'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        signOffDate: (map['signOffDate'] as String?) != null
            ? DateTime.tryParse(map['signOffDate'] as String)
            : null,
        notes: (map['notes'] as String?) ?? '',
        createdAt: DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
