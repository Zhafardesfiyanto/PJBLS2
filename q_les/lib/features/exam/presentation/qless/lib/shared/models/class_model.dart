class ClassModel {
  const ClassModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.teacherName,
    required this.completedAssignments,
    required this.totalAssignments,
  });

  final String id;
  final String name;
  final String subject;
  final String teacherName;
  final int completedAssignments;
  final int totalAssignments;

  double get progressPercent =>
      totalAssignments == 0 ? 0 : completedAssignments / totalAssignments;

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      teacherName: json['teacher_name'] as String,
      completedAssignments: json['completed_assignments'] as int? ?? 0,
      totalAssignments: json['total_assignments'] as int? ?? 0,
    );
  }
}
