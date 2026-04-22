# Design Document: Q-Les E-Learning App

## Overview

Q-Les is a Flutter mobile application targeting Android and iOS. It serves two user roles — Teacher and Student — each with a dedicated dashboard. The app integrates Firebase (Authentication + Realtime Database) for identity management and real-time data, and a Laravel REST API for persistent class/exam data.

Key design goals:
- Clean separation between UI, service, and data layers (feature-first folder structure)
- Reactive UI driven by Firebase streams and provider-based state management
- Glassmorphism design system implemented as a shared widget library
- Anti-cheat monitoring during the proctored exam interface

## Architecture

The app follows a layered architecture:

```
UI Layer (Screens & Widgets)
        ↕
State Layer (Providers / Notifiers)
        ↕
Service Layer (Auth, Class, Exam, AuditLog, AntiCheat)
        ↕
Data Layer (Firebase SDK, HTTP Client → Laravel API)
```

State management uses **Riverpod** (flutter_riverpod) for its compile-safe provider graph and first-class async support. Firebase streams are exposed as `StreamProvider`s; API calls as `FutureProvider`s or `AsyncNotifier`s.

### Navigation

GoRouter handles declarative routing with role-based redirect guards:

```
/auth          → AuthScreen
/student       → StudentDashboard
/teacher       → TeacherDashboard
/exam          → ExamInterface
```

A `routerGuard` redirect checks the current auth state and stored role on every navigation event.

### Folder Structure

```
lib/
  core/
    theme/          # AppTheme, GlassCard, typography constants
    router/         # GoRouter config + guards
    storage/        # SecureStorage wrapper
  features/
    auth/
      screens/      # AuthScreen
      providers/    # authProvider, roleProvider
      services/     # AuthService
    student/
      screens/      # StudentDashboard
      providers/    # classListProvider, examCountdownProvider
    teacher/
      screens/      # TeacherDashboard
      providers/    # studentRosterProvider, auditLogProvider, examToggleProvider
    exam/
      screens/      # ExamInterface
      providers/    # examQuestionsProvider, syncStatusProvider
      services/     # ExamService, AntiCheatMonitor
  shared/
    services/       # ClassService, AuditLogService
    models/         # All data models
    widgets/        # Shared UI components
```

## Components and Interfaces

### AuthService

```dart
abstract class AuthService {
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> registerWithEmail(String email, String password, UserRole role);
  Future<void> signOut();
  Future<void> refreshToken();
  Stream<User?> get authStateChanges;
  UserRole? get cachedRole;
}
```

### ClassService

```dart
abstract class ClassService {
  Future<List<ClassModel>> fetchStudentClasses(String studentId);
  Future<List<StudentModel>> fetchClassRoster(String classId);
  Future<void> verifyStudent(String studentId);
  Future<void> removeStudent(String classId, String studentId);
}
```

### ExamService

```dart
abstract class ExamService {
  Stream<ExamSchedule?> watchExamSchedule();
  Stream<bool> watchExamActive();
  Future<void> setExamActive(bool active);
  Future<List<ExamQuestion>> loadQuestions(String examId);
  Future<void> autoSaveDraft(String examId, String questionId, String answer);
  Future<void> submitExam(String examId, Map<String, String> answers);
}
```

### AuditLogService

```dart
abstract class AuditLogService {
  Stream<List<AuditEntry>> watchAuditLog({int limit = 50});
  Future<void> recordEntry(AuditEntry entry);
}
```

### AntiCheatMonitor

```dart
abstract class AntiCheatMonitor {
  Stream<CheatEvent> get violations;
  void startMonitoring();
  void stopMonitoring();
}
```

Implemented using `WidgetsBindingObserver` to detect `AppLifecycleState` changes (paused/inactive = app-switch).

### Design System

`AppTheme` provides:
- `AppTheme.cobaltBlue` = `Color(0xFF0047AB)`
- `AppTheme.backgroundGradient` = white → `#F5F7FA`
- `AppTheme.textTheme` = Plus Jakarta Sans via `google_fonts`

`GlassCard` widget:
```dart
class GlassCard extends StatelessWidget {
  // BackdropFilter + ClipRRect + Container with
  // color: Colors.white.withOpacity(0.18)
  // boxShadow: BlurRadius 8dp
}
```

## Data Models

```dart
enum UserRole { teacher, student }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
}

class ClassModel {
  final String id;
  final String name;
  final String subject;
  final String teacherName;
  final int completedAssignments;
  final int totalAssignments;

  double get progressPercent =>
      totalAssignments == 0 ? 0 : completedAssignments / totalAssignments;
}

class StudentModel {
  final String id;
  final String name;
  final String email;
  final bool isVerified;
}

class ExamSchedule {
  final String examId;
  final DateTime scheduledAt;
  final Duration duration;
  final bool isActive;
}

class ExamQuestion {
  final String id;
  final String prompt;
  final int maxCharacters; // minimum 2000
}

class AuditEntry {
  final String actorId;
  final String actorName;
  final String action;
  final DateTime timestampUtc;
}

enum SyncStatus { synced, syncing, failed }

enum CheatEventType { appSwitch, tabOut }

class CheatEvent {
  final CheatEventType type;
  final DateTime timestampUtc;
  final String studentId;
}
```

Firebase Realtime Database schema:

```
/exams/{examId}/
  active: bool
  scheduledAt: ISO8601 string
  durationSeconds: int
  questions/{questionId}/
    prompt: string
  drafts/{studentId}/{questionId}: string
  submissions/{studentId}/
    answers/{questionId}: string
    submittedAt: ISO8601 string

/audit_logs/{examId}/{entryId}/
  actorId: string
  actorName: string
  action: string
  timestampUtc: ISO8601 string
```

