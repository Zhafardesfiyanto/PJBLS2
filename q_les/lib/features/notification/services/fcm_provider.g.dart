// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fcmServiceHash() => r'38d33f30deea39f1c968bf041a8425030f26fa41';

/// Provider untuk FCMService
///
/// Copied from [fcmService].
@ProviderFor(fcmService)
final fcmServiceProvider = AutoDisposeProvider<FCMService>.internal(
  fcmService,
  name: r'fcmServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fcmServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FcmServiceRef = AutoDisposeProviderRef<FCMService>;
String _$initializeFCMHash() => r'fa7c07c25776c639bf3065315af6d5b8c7577c12';

/// Provider untuk FCM initialization
///
/// Copied from [initializeFCM].
@ProviderFor(initializeFCM)
final initializeFCMProvider = AutoDisposeFutureProvider<void>.internal(
  initializeFCM,
  name: r'initializeFCMProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$initializeFCMHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InitializeFCMRef = AutoDisposeFutureProviderRef<void>;
String _$fcmTokenHash() => r'c53f9cf8d889e5202e68dc173e44570985b99449';

/// Provider untuk FCM token
///
/// Copied from [fcmToken].
@ProviderFor(fcmToken)
final fcmTokenProvider = AutoDisposeFutureProvider<String?>.internal(
  fcmToken,
  name: r'fcmTokenProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fcmTokenHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FcmTokenRef = AutoDisposeFutureProviderRef<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
