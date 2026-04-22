# Implementation Plan: Q-Les E-Learning App

## Overview

Incremental Flutter implementation using Riverpod, GoRouter, Firebase, and a Laravel REST API. Tasks build from the foundation (theme, models, routing) up through each feature screen, ending with full integration.

## Tasks

- [x] 1. Set up project foundation: theme, models, and routing
  - Add dependencies to `pubspec.yaml`: `flutter_riverpod`, `go_router`, `firebase_core`, `firebase_auth`, `firebase_database`, `google_sign_in`, `flutter_secure_storage`, `google_fonts`, `http`
  - Create `lib/core/theme/app_theme.dart` with `AppTheme.cobaltBlue`, `AppTheme.backgroundGradient`, and `AppTheme.textTheme` using Plus Jakarta Sans
  - Create `lib/shared/widgets/glass_card.dart` implementing `BackdropFilter` + `ClipRRect` with `Colors.white.withOpacity(0.18)` and 8dp blur/shadow
  - Create all data models in `lib/shared/models/`: `AppUser`, `ClassModel`, `StudentModel`, `ExamSchedule`, `ExamQuestion`, `AuditEntry`, `CheatEvent`, `SyncStatus`, `UserRole`, `CheatEventType`
  - Create `lib/core/router/app_router.dart` with GoRouter routes `/auth`, `/student`, `/teacher`, `/exam` and a `routerGuard` redirect based on auth state and stored role
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.5, 2.6, 9.3_

- [x] 2. Implement authentication layer
  - [x] 2.1 Create `AuthService` in `lib/features/auth/services/auth_service.dart`
    - Implement `signInWithEmail`, `signInWithGoogle`, `registerWithEmail`, `signOut`, `refreshToken`, `authStateChanges`, `cachedRole`
    - Store role in `flutter_secure_storage` (not plain-text prefs)
    - _Requirements: 2.3, 2.4, 2.8, 9.1, 9.2, 9.4_

  - [x] 2.2 Create Riverpod providers in `lib/features/auth/providers/auth_provider.dart`
    - `authStateProvider` as `StreamProvider<User?>`
    - `roleProvider` reading from secure storage
    - _Requirements: 2.5, 2.6, 9.3_

  - [x] 2.3 Build `AuthScreen` in `lib/features/auth/screens/auth_screen.dart`
    - Tab control toggling login/register forms in a single scrollable view
    - `Role_Toggle` with "Teacher" / "Student" options styled in Cobalt Blue
    - Google Sign-In button
    - Inline error messages displayed within 300ms of failure
    - Wrap form container in `GlassCard`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.7, 2.9_

  - [x] 2.4 Write widget tests for AuthScreen
    - Test tab toggle renders both forms
    - Test role toggle selection
    - Test inline error display on auth failure
    - _Requirements: 2.1, 2.2, 2.7_

- [x] 3. Checkpoint — Ensure auth flow compiles and routes correctly
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement shared services: ClassService and AuditLogService
  - [x] 4.1 Create `ClassService` in `lib/shared/services/class_service.dart`
    - Implement `fetchStudentClasses`, `fetchClassRoster`, `verifyStudent`, `removeStudent` via HTTP to Laravel API
    - _Requirements: 3.1, 6.1, 6.3, 6.4_

  - [x] 4.2 Create `AuditLogService` in `lib/shared/services/audit_log_service.dart`
    - Implement `watchAuditLog(limit: 50)` as a Firebase stream
    - Implement `recordEntry` writing to `/audit_logs/{examId}/{entryId}`
    - _Requirements: 5.4, 7.1, 7.2, 8.4_

  - [x] 4.3 Write unit tests for ClassService
    - Test successful fetch, error handling, verify/remove actions
    - _Requirements: 3.1, 6.1, 6.3, 6.4_

  - [x] 4.4 Write unit tests for AuditLogService
    - Test stream emissions and `recordEntry` writes
    - _Requirements: 7.1, 7.2_

- [x] 5. Implement Student Dashboard
  - [x] 5.1 Create providers in `lib/features/student/providers/`
    - `classListProvider` as `FutureProvider` calling `ClassService.fetchStudentClasses`
    - `examCountdownProvider` as `StreamProvider<ExamSchedule?>` from `ExamService.watchExamSchedule`
    - _Requirements: 3.1, 4.1_

  - [x] 5.2 Build `StudentDashboard` in `lib/features/student/screens/student_dashboard.dart`
    - Render each class as a `GlassCard` with name, subject, teacher name, and assignment progress percentage
    - Show loading skeleton while fetching
    - Show retry button + error message on API failure
    - Countdown timer (days/hours/minutes/seconds) updating every 1 second
    - Replace countdown with "Enter Exam" button when timer reaches zero
    - Show "No upcoming exams" placeholder when no exam is scheduled
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 4.2, 4.3, 4.4, 4.5_

  - [x] 5.3 Write widget tests for StudentDashboard
    - Test loading skeleton, error state, class card rendering, countdown display, "Enter Exam" button
    - _Requirements: 3.2, 3.3, 3.4, 4.2, 4.3_

- [x] 6. Implement ExamService
  - [x] 6.1 Create `ExamService` in `lib/features/exam/services/exam_service.dart`
    - Implement `watchExamSchedule`, `watchExamActive`, `setExamActive`, `loadQuestions`, `autoSaveDraft`, `submitExam`
    - Auto-save draft to Firebase every 30 seconds
    - On submit: write to Firebase then POST to Laravel `/exams/{id}/submit`; on Laravel failure retain Firebase draft and surface `SyncStatus.failed`
    - _Requirements: 4.1, 5.2, 5.3, 8.1, 8.6, 8.7, 8.8_

  - [x] 6.2 Write property test for ExamService auto-save and submit
    - **Property 1: Draft persistence — for any answer written before a submit failure, the draft remains readable from Firebase**
    - **Validates: Requirements 8.8**

  - [x] 6.3 Write unit tests for ExamService
    - Test `watchExamActive` stream, `setExamActive` writes, `submitExam` success and failure paths
    - _Requirements: 5.2, 5.3, 8.7, 8.8_

- [x] 7. Implement Teacher Dashboard
  - [x] 7.1 Create providers in `lib/features/teacher/providers/`
    - `studentRosterProvider` as `FutureProvider` calling `ClassService.fetchClassRoster`
    - `auditLogProvider` as `StreamProvider<List<AuditEntry>>` from `AuditLogService.watchAuditLog`
    - `examToggleProvider` as `StreamProvider<bool>` from `ExamService.watchExamActive`
    - _Requirements: 5.1, 6.1, 7.1_

  - [x] 7.2 Build `TeacherDashboard` in `lib/features/teacher/screens/teacher_dashboard.dart`
    - Master Exam Toggle switch styled in Cobalt Blue; reflects Firebase state within 500ms
    - On toggle: call `ExamService.setExamActive` and `AuditLogService.recordEntry`
    - Student list with name, email, verification status; "Verify" and "Remove" actions
    - Toast notification on API error within 300ms
    - Real-time audit log list (50 entries, scrollable); "Reconnecting..." indicator on stream interruption
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 6.2, 6.3, 6.4, 6.5, 7.2, 7.3, 7.4, 7.5_

  - [x] 7.3 Write widget tests for TeacherDashboard
    - Test toggle state sync, student list rendering, verify/remove actions, audit log rendering
    - _Requirements: 5.1, 5.5, 6.2, 7.3, 7.4_

- [x] 8. Checkpoint — Ensure all dashboard tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Implement AntiCheatMonitor and Exam Interface
  - [x] 9.1 Create `AntiCheatMonitor` in `lib/features/exam/services/anti_cheat_monitor.dart`
    - Use `WidgetsBindingObserver` to detect `AppLifecycleState.paused` / `inactive` as `CheatEventType.appSwitch`
    - Emit `CheatEvent` on `violations` stream with student ID and UTC timestamp
    - _Requirements: 8.3_

  - [x] 9.2 Create providers in `lib/features/exam/providers/`
    - `examQuestionsProvider` as `FutureProvider<List<ExamQuestion>>` from `ExamService.loadQuestions`
    - `syncStatusProvider` as `StateProvider<SyncStatus>`
    - _Requirements: 8.1, 8.5_

  - [x] 9.3 Build `ExamInterface` in `lib/features/exam/screens/exam_interface.dart`
    - Render each question with a multi-line `TextField` supporting minimum 2000 characters
    - Display sync status indicator ("Synced" / "Syncing..." / "Sync Failed")
    - Show violation warning overlay when `AntiCheatMonitor` emits a violation; record via `AuditLogService`
    - "Submit Exam" button triggering `ExamService.submitExam`
    - Auto-trigger submission when exam time limit expires
    - "Sync Failed" state shows manual retry button
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9_

  - [x] 9.4 Write property test for AntiCheatMonitor
    - **Property 2: Every app-switch lifecycle event produces exactly one CheatEvent on the violations stream**
    - **Validates: Requirements 8.3**

  - [x] 9.5 Write widget tests for ExamInterface
    - Test question rendering, sync status display, violation overlay, submit flow
    - _Requirements: 8.2, 8.4, 8.5, 8.7, 8.8_

- [x] 10. Implement session management and router guard
  - [x] 10.1 Wire `routerGuard` in `app_router.dart` to `authStateProvider` and `roleProvider`
    - Redirect unauthenticated users to `/auth`
    - Redirect authenticated users to `/student` or `/teacher` based on stored role
    - _Requirements: 2.5, 2.6, 9.3_

  - [x] 10.2 Wire silent token refresh in `AuthService`
    - Call `refreshToken` on Firebase token expiry via `authStateChanges` listener
    - _Requirements: 9.1_

  - [x] 10.3 Implement sign-out flow
    - Revoke Firebase session, clear secure storage, navigate to `/auth`
    - _Requirements: 9.2_

  - [x] 10.4 Write integration tests for session management
    - Test token refresh, sign-out clears storage, app launch restores session to correct dashboard
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 11. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties; unit/widget tests cover specific examples and edge cases
