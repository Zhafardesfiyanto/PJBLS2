import '../domain/class_model.dart';

/// Abstract repository for class operations
abstract class ClassRepository {
  /// Create a new class
  Future<ClassModel> createClass(String name, String description, String teacherId);

  /// Join a class using class code
  Future<void> joinClass(String classCode, String studentId);

  /// Remove a student from class
  Future<void> removeStudent(String classId, String studentId);

  /// Delete a class
  Future<void> deleteClass(String classId);

  /// Watch user's classes (owned or joined)
  Stream<List<ClassModel>> watchUserClasses(String userId);

  /// Get class by class code
  Future<ClassModel?> getClassByCode(String classCode);
}