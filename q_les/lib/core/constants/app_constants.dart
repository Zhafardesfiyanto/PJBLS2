/// Konstanta aplikasi q_les
class AppConstants {
  // App info
  static const String appName = 'Q-Les School App';
  static const String appVersion = '1.0.0';
  
  // Validation constants
  static const int maxMessageLength = 1000;
  static const int maxFileSize = 5 * 1024 * 1024; // 5 MB in bytes
  static const int classCodeLength = 6;
  
  // Supported file formats
  static const List<String> supportedImageFormats = ['.jpg', '.jpeg', '.png', '.webp'];
  static const List<String> supportedDocumentFormats = ['.pdf', '.doc', '.docx'];
  static const List<String> supportedFileFormats = [
    ...supportedImageFormats,
    ...supportedDocumentFormats,
  ];
  
  // User roles
  static const String roleGuru = 'guru';
  static const String roleMurid = 'murid';
  static const String roleAdmin = 'admin';
  
  // Verification status
  static const String verificationPending = 'pending';
  static const String verificationVerified = 'verified';
  static const String verificationRejected = 'rejected';
  
  // Assignment categories
  static const String assignmentPilihanGanda = 'pilihan_ganda';
  static const String assignmentPilihanGandaKompleks = 'pilihan_ganda_kompleks';
  static const String assignmentUraian = 'uraian';
  
  // Quiz question types
  static const String questionTypePilihanGanda = 'pilihan_ganda';
  static const String questionTypePilihanGandaKompleks = 'pilihan_ganda_kompleks';
  static const String questionTypeUraian = 'uraian';
  
  // Exam status
  static const String examStatusScheduled = 'scheduled';
  static const String examStatusActive = 'active';
  static const String examStatusEnded = 'ended';
  
  // Exam session status
  static const String sessionStatusActive = 'active';
  static const String sessionStatusSubmitted = 'submitted';
  static const String sessionStatusForceEnded = 'force_ended';
  
  // Suspicious gesture types
  static const String gestureSwipeOut = 'swipe_out';
  static const String gestureScreenshot = 'screenshot';
  static const String gestureAppSwitch = 'app_switch';
  static const String gestureNotificationPanel = 'notification_panel';
  
  // Chat types
  static const String chatTypeClass = 'class';
  static const String chatTypeAssignment = 'assignment';
  
  // Notification types
  static const String notificationNewAssignment = 'new_assignment';
  static const String notificationNewQuiz = 'new_quiz';
  static const String notificationExamStart = 'exam_start';
  static const String notificationDeadlineReminder = 'deadline_reminder';
  static const String notificationVerificationUpdate = 'verification_update';
  
  // Time constants
  static const Duration deadlineReminderThreshold = Duration(hours: 24);
  static const Duration gestureDetectionTimeout = Duration(seconds: 1);
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}