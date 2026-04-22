import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Service for Firebase Cloud Messaging
abstract class FCMService {
  /// Initialize FCM
  Future<void> initialize();

  /// Get FCM token
  Future<String?> getToken();

  /// Handle foreground messages
  void handleForegroundMessages();

  /// Handle background messages
  void handleBackgroundMessages();

  /// Request notification permissions
  Future<bool> requestPermissions();

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic);
}

/// Firebase implementation of FCMService
class FirebaseFCMService implements FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    // Request permissions
    await requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    handleForegroundMessages();

    // Handle notification taps
    _handleNotificationTaps();
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  void handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      
      // Show local notification when app is in foreground
      _showLocalNotification(message);
    });
  }

  @override
  void handleBackgroundMessages() {
    // Background message handler is set in initialize()
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked: ${message.messageId}');
      _handleMessageClick(message);
    });
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'school_app_channel',
      'School App Notifications',
      channelDescription: 'Notifications for school app activities',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTaps() {
    // Handle notification tap when app is terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessageClick(message);
      }
    });
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  void _handleMessageClick(RemoteMessage message) {
    debugPrint('Handling message click: ${message.data}');
    
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'verification_approved':
      case 'verification_rejected':
        // Navigate to verification status or refresh auth state
        break;
      case 'new_assignment':
        // Navigate to assignment detail
        final classId = data['classId'];
        final assignmentId = data['assignmentId'];
        // TODO: Navigate to assignment
        break;
      case 'new_quiz':
        // Navigate to quiz
        final classId = data['classId'];
        final quizId = data['quizId'];
        // TODO: Navigate to quiz
        break;
      case 'exam_started':
        // Navigate to exam
        final examId = data['examId'];
        // TODO: Navigate to exam
        break;
      case 'assignment_reminder':
        // Navigate to assignment
        final classId = data['classId'];
        final assignmentId = data['assignmentId'];
        // TODO: Navigate to assignment
        break;
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background message processing here
}