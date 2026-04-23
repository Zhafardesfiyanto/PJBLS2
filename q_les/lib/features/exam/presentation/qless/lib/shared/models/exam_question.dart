class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.prompt,
    this.maxCharacters = 2000,
  }) : assert(maxCharacters >= 2000, 'maxCharacters must be at least 2000');

  final String id;
  final String prompt;
  final int maxCharacters;

  factory ExamQuestion.fromJson(String id, Map<String, dynamic> json) {
    return ExamQuestion(
      id: id,
      prompt: json['prompt'] as String,
      maxCharacters: json['maxCharacters'] as int? ?? 2000,
    );
  }
}
