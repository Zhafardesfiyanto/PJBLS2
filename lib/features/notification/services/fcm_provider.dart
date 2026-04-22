import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'fcm_service.dart';

part 'fcm_provider.g.dart';

/// Provider untuk FCMService
@riverpod
FCMService fcmService(FcmServiceRef ref) {
  return FirebaseFCMService();
}

/// Provider untuk FCM initialization
@riverpod
Future<void> initializeFCM(InitializeFCMRef ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  await fcmService.initialize();
}

/// Provider untuk FCM token
@riverpod
Future<String?> fcmToken(FcmTokenRef ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  return await fcmService.getToken();
}