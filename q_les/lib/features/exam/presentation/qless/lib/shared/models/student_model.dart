class StudentModel {
  const StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.isVerified,
  });

  final String id;
  final String name;
  final String email;
  final bool isVerified;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  StudentModel copyWith({bool? isVerified}) {
    return StudentModel(
      id: id,
      name: name,
      email: email,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
