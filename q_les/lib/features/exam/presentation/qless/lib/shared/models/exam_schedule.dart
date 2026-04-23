class ExamSchedule {
  const ExamSchedule({
    required this.examId,
    required this.scheduledAt,
    required this.duration,
    required this.isActive,
  });

  final String examId;
  final DateTime scheduledAt;
  final Duration duration;
  final bool isActive;

  factory ExamSchedule.fromJson(Map<String, dynamic> json) {
    return ExamSchedule(
      examId: json['examId'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int),
      isActive: json['active'] as bool? ?? false,
    );
  }
}
