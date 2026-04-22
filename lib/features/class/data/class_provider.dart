import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/providers/auth_provider.dart';
import '../domain/class_model.dart';
import 'class_repository_impl.dart';

part 'class_provider.g.dart';

/// Provider for watching user's classes
@riverpod
Stream<List<ClassModel>> userClasses(UserClassesRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final repository = ref.watch(classRepositoryProvider);
  return repository.watchUserClasses(user.uid);
}

/// Provider for creating a new class
@riverpod
class ClassCreator extends _$ClassCreator {
  @override
  FutureOr<void> build() {}

  Future<ClassModel> createClass(String name, String description) async {
    state = const AsyncLoading();
    
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');
      
      final repository = ref.read(classRepositoryProvider);
      final classModel = await repository.createClass(name, description, user.uid);
      
      state = const AsyncData(null);
      return classModel;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

/// Provider for joining a class
@riverpod
class ClassJoiner extends _$ClassJoiner {
  @override
  FutureOr<void> build() {}

  Future<void> joinClass(String classCode) async {
    state = const AsyncLoading();
    
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');
      
      final repository = ref.read(classRepositoryProvider);
      await repository.joinClass(classCode, user.uid);
      
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

/// Provider for removing a student from class
@riverpod
class StudentRemover extends _$StudentRemover {
  @override
  FutureOr<void> build() {}

  Future<void> removeStudent(String classId, String studentId) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(classRepositoryProvider);
      await repository.removeStudent(classId, studentId);
      
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

/// Provider for deleting a class
@riverpod
class ClassDeleter extends _$ClassDeleter {
  @override
  FutureOr<void> build() {}

  Future<void> deleteClass(String classId) async {
    state = const AsyncLoading();
    
    try {
      final repository = ref.read(classRepositoryProvider);
      await repository.deleteClass(classId);
      
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}