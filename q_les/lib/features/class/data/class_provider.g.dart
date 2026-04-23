// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userClassesHash() => r'bd28e811c9d38cf3696912867cfe92ad27543fa7';

/// Provider for watching user's classes
///
/// Copied from [userClasses].
@ProviderFor(userClasses)
final userClassesProvider =
    AutoDisposeStreamProvider<List<ClassModel>>.internal(
      userClasses,
      name: r'userClassesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userClassesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserClassesRef = AutoDisposeStreamProviderRef<List<ClassModel>>;
String _$classCreatorHash() => r'8401c7729f58cdf75e842ecfcfdc679f8d0aec9d';

/// Provider for creating a new class
///
/// Copied from [ClassCreator].
@ProviderFor(ClassCreator)
final classCreatorProvider =
    AutoDisposeAsyncNotifierProvider<ClassCreator, void>.internal(
      ClassCreator.new,
      name: r'classCreatorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$classCreatorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ClassCreator = AutoDisposeAsyncNotifier<void>;
String _$classJoinerHash() => r'33a3ad354647a70b7d841f9575e24b01ff6642c1';

/// Provider for joining a class
///
/// Copied from [ClassJoiner].
@ProviderFor(ClassJoiner)
final classJoinerProvider =
    AutoDisposeAsyncNotifierProvider<ClassJoiner, void>.internal(
      ClassJoiner.new,
      name: r'classJoinerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$classJoinerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ClassJoiner = AutoDisposeAsyncNotifier<void>;
String _$studentRemoverHash() => r'36325c6a4174cb66dcce80cc0e258b690f96f4c7';

/// Provider for removing a student from class
///
/// Copied from [StudentRemover].
@ProviderFor(StudentRemover)
final studentRemoverProvider =
    AutoDisposeAsyncNotifierProvider<StudentRemover, void>.internal(
      StudentRemover.new,
      name: r'studentRemoverProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$studentRemoverHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StudentRemover = AutoDisposeAsyncNotifier<void>;
String _$classDeleterHash() => r'b0df4ebd400ac8e5a5b28b9d16056515763cc3d5';

/// Provider for deleting a class
///
/// Copied from [ClassDeleter].
@ProviderFor(ClassDeleter)
final classDeleterProvider =
    AutoDisposeAsyncNotifierProvider<ClassDeleter, void>.internal(
      ClassDeleter.new,
      name: r'classDeleterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$classDeleterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ClassDeleter = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
