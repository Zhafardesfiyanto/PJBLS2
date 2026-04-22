// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$verificationRepositoryHash() =>
    r'bc1a1ced2f9bf52f14604d429bd2d416b1ec08d0';

/// Provider untuk VerificationRepository
///
/// Copied from [verificationRepository].
@ProviderFor(verificationRepository)
final verificationRepositoryProvider =
    AutoDisposeProvider<VerificationRepository>.internal(
      verificationRepository,
      name: r'verificationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$verificationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VerificationRepositoryRef =
    AutoDisposeProviderRef<VerificationRepository>;
String _$pendingVerificationRequestsHash() =>
    r'6deb55b2742c031a0f6a527f0546a012b6a32b5f';

/// Provider untuk stream pending verification requests (admin)
///
/// Copied from [pendingVerificationRequests].
@ProviderFor(pendingVerificationRequests)
final pendingVerificationRequestsProvider =
    AutoDisposeStreamProvider<List<VerificationRequestModel>>.internal(
      pendingVerificationRequests,
      name: r'pendingVerificationRequestsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingVerificationRequestsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingVerificationRequestsRef =
    AutoDisposeStreamProviderRef<List<VerificationRequestModel>>;
String _$verificationRequestHash() =>
    r'0d468529adf439ba84ddc1645e321106df3df681';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider untuk verification request by teacher ID
///
/// Copied from [verificationRequest].
@ProviderFor(verificationRequest)
const verificationRequestProvider = VerificationRequestFamily();

/// Provider untuk verification request by teacher ID
///
/// Copied from [verificationRequest].
class VerificationRequestFamily
    extends Family<AsyncValue<VerificationRequestModel?>> {
  /// Provider untuk verification request by teacher ID
  ///
  /// Copied from [verificationRequest].
  const VerificationRequestFamily();

  /// Provider untuk verification request by teacher ID
  ///
  /// Copied from [verificationRequest].
  VerificationRequestProvider call(String teacherId) {
    return VerificationRequestProvider(teacherId);
  }

  @override
  VerificationRequestProvider getProviderOverride(
    covariant VerificationRequestProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'verificationRequestProvider';
}

/// Provider untuk verification request by teacher ID
///
/// Copied from [verificationRequest].
class VerificationRequestProvider
    extends AutoDisposeFutureProvider<VerificationRequestModel?> {
  /// Provider untuk verification request by teacher ID
  ///
  /// Copied from [verificationRequest].
  VerificationRequestProvider(String teacherId)
    : this._internal(
        (ref) => verificationRequest(ref as VerificationRequestRef, teacherId),
        from: verificationRequestProvider,
        name: r'verificationRequestProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$verificationRequestHash,
        dependencies: VerificationRequestFamily._dependencies,
        allTransitiveDependencies:
            VerificationRequestFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  VerificationRequestProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
  }) : super.internal();

  final String teacherId;

  @override
  Override overrideWith(
    FutureOr<VerificationRequestModel?> Function(
      VerificationRequestRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VerificationRequestProvider._internal(
        (ref) => create(ref as VerificationRequestRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<VerificationRequestModel?> createElement() {
    return _VerificationRequestProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VerificationRequestProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VerificationRequestRef
    on AutoDisposeFutureProviderRef<VerificationRequestModel?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _VerificationRequestProviderElement
    extends AutoDisposeFutureProviderElement<VerificationRequestModel?>
    with VerificationRequestRef {
  _VerificationRequestProviderElement(super.provider);

  @override
  String get teacherId => (origin as VerificationRequestProvider).teacherId;
}

String _$verificationControllerHash() =>
    r'0d3721f8be2cb6c772cb121e02b6491077945cb9';

/// Controller untuk verification operations
///
/// Copied from [VerificationController].
@ProviderFor(VerificationController)
final verificationControllerProvider =
    AutoDisposeAsyncNotifierProvider<VerificationController, void>.internal(
      VerificationController.new,
      name: r'verificationControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$verificationControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$VerificationController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
