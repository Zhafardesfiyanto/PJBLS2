class AuditEntry {
  const AuditEntry({
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.timestampUtc,
  });

  final String actorId;
  final String actorName;
  final String action;
  final DateTime timestampUtc;

  Map<String, dynamic> toJson() => {
        'actorId': actorId,
        'actorName': actorName,
        'action': action,
        'timestampUtc': timestampUtc.toUtc().toIso8601String(),
      };

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      actorId: json['actorId'] as String,
      actorName: json['actorName'] as String,
      action: json['action'] as String,
      timestampUtc: DateTime.parse(json['timestampUtc'] as String),
    );
  }
}
