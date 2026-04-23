# Tasks - School App Implementation

- [ ] 1. Setup Project & Dependencies
  - [ ] 1.1 Update pubspec.yaml dengan dependencies Firebase dan Riverpod
  - [ ] 1.2 Setup Firebase project dan download google-services.json
  - [ ] 1.3 Konfigurasi Firebase di android/app/build.gradle
  - [ ] 1.4 Buat firebase_options.dart dengan FlutterFire CLI
  - [ ] 1.5 Setup struktur folder sesuai feature-first architecture

- [ ] 2. Core Infrastructure
  - [ ] 2.1 Buat app_router.dart dengan GoRouter dan role-based routing
  - [ ] 2.2 Buat app_theme.dart untuk tema aplikasi
  - [ ] 2.3 Buat firestore_paths.dart untuk konstanta path collection
  - [ ] 2.4 Buat app_exception.dart untuk error handling
  - [ ] 2.5 Setup main.dart dengan ProviderScope dan Firebase initialization

- [ ] 3. Authentication System
  - [ ] 3.1 Buat UserModel dengan serialization (freezed/json_annotation)
  - [ ] 3.2 Buat AuthRepository interface dan implementasi Firebase Auth
  - [ ] 3.3 Buat AuthProvider dengan Riverpod untuk state management
  - [ ] 3.4 Buat LoginScreen dengan form validation
  - [ ] 3.5 Buat RegisterScreen dengan role selection (Guru/Murid)
  - [ ] 3.6 Implementasi logout functionality
  - [ ] 3.7 Setup auth state persistence dan auto-login

- [ ] 4. User Profile Management
  - [ ] 4.1 Buat ProfileRepository untuk CRUD data profil di Firestore
  - [ ] 4.2 Buat ProfileScreen untuk tampilan dan edit profil
  - [ ] 4.3 Implementasi upload foto profil ke Firebase Storage
  - [ ] 4.4 Validasi ukuran file (max 5MB) dan format (JPEG/PNG/WebP)
  - [ ] 4.5 Update foto profil di semua pesan chat (denormalisasi)

- [ ] 5. Teacher Verification System
  - [ ] 5.1 Buat VerificationRepository untuk manajemen verifikasi guru
  - [ ] 5.2 Buat VerificationPendingScreen untuk guru yang belum terverifikasi
  - [ ] 5.3 Buat AdminVerificationScreen untuk approval/rejection
  - [ ] 5.4 Implementasi kode verifikasi institusi (opsional)
  - [ ] 5.5 Setup notifikasi FCM untuk status verifikasi

- [ ] 6. Class Management System
  - [ ] 6.1 Buat ClassModel dengan serialization
  - [ ] 6.2 Buat ClassRepository untuk CRUD kelas di Firestore
  - [ ] 6.3 Implementasi generate kode kelas unik (6 karakter alfanumerik)
  - [ ] 6.4 Buat ClassListScreen dengan search dan dropdown
  - [ ] 6.5 Buat CreateClassScreen untuk guru
  - [ ] 6.6 Buat JoinClassScreen untuk murid dengan copy-paste kode
  - [ ] 6.7 Buat ClassDetailScreen dengan tab navigation
  - [ ] 6.8 Implementasi kick murid dari kelas
  - [ ] 6.9 Implementasi copy kode kelas ke clipboard

- [ ] 7. Assignment System
  - [ ] 7.1 Buat AssignmentModel dan SubmissionModel
  - [ ] 7.2 Buat AssignmentRepository untuk CRUD tugas dan submission
  - [ ] 7.3 Implementasi tiga kategori tugas (pilgan, pilgan kompleks, uraian)
  - [ ] 7.4 Buat CreateAssignmentScreen untuk guru
  - [ ] 7.5 Buat AssignmentListScreen dengan status deadline
  - [ ] 7.6 Buat AssignmentDetailScreen untuk submit dan grading
  - [ ] 7.7 Implementasi upload file submission ke Firebase Storage
  - [ ] 7.8 Implementasi late submission handling

- [ ] 8. Quiz System
  - [ ] 8.1 Buat QuizModel dan QuestionModel dengan tipe soal
  - [ ] 8.2 Buat QuizRepository untuk CRUD kuis dan hasil
  - [ ] 8.3 Buat CreateQuizScreen dengan editor pertanyaan
  - [ ] 8.4 Buat QuizScreen untuk mengerjakan kuis
  - [ ] 8.5 Implementasi scoring per soal dan total
  - [ ] 8.6 Buat QuizResultScreen dengan breakdown nilai
  - [ ] 8.7 Implementasi prevent retake quiz

- [ ] 9. Exam System & Lockdown Mode
  - [ ] 9.1 Buat ExamModel dan ExamSessionModel
  - [ ] 9.2 Buat ExamRepository untuk manajemen sesi ujian
  - [ ] 9.3 Implementasi ExamLockdownService dengan MethodChannel
  - [ ] 9.4 Buat MainActivity.kt dengan startLockTask() dan stopLockTask()
  - [ ] 9.5 Buat ExamScreen dengan full-screen mode dan gesture detection
  - [ ] 9.6 Implementasi deteksi gestur mencurigakan (swipe, screenshot, app switch)
  - [ ] 9.7 Implementasi offline storage untuk jawaban dan gesture log
  - [ ] 9.8 Buat ExamRecapScreen untuk guru melihat gesture log
  - [ ] 9.9 Setup AndroidManifest.xml untuk kiosk mode

- [ ] 10. Class Chat System
  - [ ] 10.1 Buat MessageModel untuk chat kelas
  - [ ] 10.2 Buat ChatRepository dengan Firestore streams
  - [ ] 10.3 Buat ClassChatScreen dengan real-time messaging
  - [ ] 10.4 Implementasi pagination untuk riwayat pesan lama
  - [ ] 10.5 Implementasi delete message untuk guru
  - [ ] 10.6 Validasi panjang pesan (max 1000 karakter)

- [ ] 11. Assignment Chat System
  - [ ] 11.1 Extend MessageModel untuk chat tugas
  - [ ] 11.2 Extend ChatRepository untuk assignment messages
  - [ ] 11.3 Buat AssignmentChatScreen terintegrasi di AssignmentDetailScreen
  - [ ] 11.4 Implementasi chat context switching (kelas vs tugas)

- [ ] 12. Push Notifications
  - [ ] 12.1 Setup FCM token management di AuthRepository
  - [ ] 12.2 Buat FCMService untuk handle incoming notifications
  - [ ] 12.3 Setup Firebase Cloud Functions untuk trigger notifikasi
  - [ ] 12.4 Implementasi notification payload routing
  - [ ] 12.5 Setup scheduled reminder untuk deadline tugas

- [ ] 13. UI/UX Polish
  - [ ] 13.1 Buat UserAvatar widget dengan fallback
  - [ ] 13.2 Buat ClassDropdown widget dengan search
  - [ ] 13.3 Implementasi loading states dan error handling
  - [ ] 13.4 Setup responsive design untuk tablet
  - [ ] 13.5 Implementasi dark mode support

- [ ] 14. Testing Implementation
  - [ ] 14.1 Setup testing dependencies (mocktail, fake_cloud_firestore)
  - [ ] 14.2 Buat unit tests untuk repositories dan models
  - [ ] 14.3 Buat widget tests untuk screens utama
  - [ ] 14.4 Buat integration tests untuk auth flow
  - [ ] 14.5 Setup property-based testing dengan glados

- [ ] 15. Final Integration & Deployment
  - [ ] 15.1 Setup Firebase Security Rules untuk Firestore
  - [ ] 15.2 Setup Firebase Storage Rules
  - [ ] 15.3 Konfigurasi Android signing untuk release
  - [ ] 15.4 Test end-to-end di perangkat fisik
  - [ ] 15.5 Deploy Firebase Cloud Functions