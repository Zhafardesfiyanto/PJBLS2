/// Konstanta path collection Firestore untuk aplikasi q_les
class FirestorePaths {
  // Collections
  static const String users = 'users';
  static const String classes = 'classes';
  static const String assignments = 'assignments';
  static const String submissions = 'submissions';
  static const String quizzes = 'quizzes';
  static const String quizResults = 'quiz_results';
  static const String exams = 'exams';
  static const String examSessions = 'exam_sessions';
  static const String classMessages = 'class_messages';
  static const String assignmentMessages = 'assignment_messages';
  static const String verificationRequests = 'verification_requests';
  static const String verificationCodes = 'verification_codes';

  // User document path
  static String user(String uid) => '$users/$uid';
  
  // Class document path
  static String classDoc(String classId) => '$classes/$classId';
  
  // Assignment document path
  static String assignment(String assignmentId) => '$assignments/$assignmentId';
  
  // Submission document path
  static String submission(String submissionId) => '$submissions/$submissionId';
  
  // Quiz document path
  static String quiz(String quizId) => '$quizzes/$quizId';
  
  // Quiz result document path
  static String quizResult(String resultId) => '$quizResults/$resultId';
  
  // Exam document path
  static String exam(String examId) => '$exams/$examId';
  
  // Exam session document path
  static String examSession(String sessionId) => '$examSessions/$sessionId';
  
  // Class message document path
  static String classMessage(String messageId) => '$classMessages/$messageId';
  
  // Assignment message document path
  static String assignmentMessage(String messageId) => '$assignmentMessages/$messageId';
  
  // Verification request document path
  static String verificationRequest(String requestId) => '$verificationRequests/$requestId';
  
  // Verification code document path
  static String verificationCode(String code) => '$verificationCodes/$code';
}

/// Konstanta path Firebase Storage
class StoragePaths {
  // Profile photos
  static String profilePhoto(String uid) => 'profile_photos/$uid/profile.jpg';
  
  // Assignment files
  static String assignmentFile(String assignmentId, String submissionId, String filename) =>
      'assignment_files/$assignmentId/$submissionId/$filename';
}