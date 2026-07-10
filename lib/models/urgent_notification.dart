enum AlertType { fire, flooding, engineFailure, routing, other }

enum EscalationStatus { notAcknowledged, acknowledged, resolved }

class UrgentNotification {
  final String id;
  final String vesselId;
  final AlertType alertType;
  final String location;
  final String description;
  final DateTime timestamp;
  final EscalationStatus escalationStatus;

  const UrgentNotification({
    required this.id,
    required this.vesselId,
    required this.alertType,
    required this.location,
    required this.description,
    required this.timestamp,
    required this.escalationStatus,
  });

  UrgentNotification copyWith({EscalationStatus? escalationStatus}) =>
      UrgentNotification(
        id: id,
        vesselId: vesselId,
        alertType: alertType,
        location: location,
        description: description,
        timestamp: timestamp,
        escalationStatus: escalationStatus ?? this.escalationStatus,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'vesselId': vesselId,
        'alertType': alertType.name,
        'location': location,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'escalationStatus': escalationStatus.name,
      };

  factory UrgentNotification.fromMap(Map<dynamic, dynamic> map) =>
      UrgentNotification(
        id: map['id'] as String,
        vesselId: map['vesselId'] as String,
        alertType:
            AlertType.values.byName((map['alertType'] as String?) ?? 'other'),
        location: (map['location'] as String?) ?? '',
        description: map['description'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        escalationStatus: EscalationStatus.values
            .byName((map['escalationStatus'] as String?) ?? 'notAcknowledged'),
      );
}
