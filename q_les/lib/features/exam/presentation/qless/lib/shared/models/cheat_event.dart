enum CheatEventType { appSwitch, tabOut }

class CheatEvent {
  const CheatEvent({
    required this.type,
    required this.timestampUtc,
    required this.studentId,
  });

  final CheatEventType type;
  final DateTime timestampUtc;
  final String studentId;
}
