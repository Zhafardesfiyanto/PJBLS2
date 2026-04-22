# Firebase Setup Instructions

## Task 1 Completion Status

✅ **1.1 Update pubspec.yaml dengan dependencies Firebase dan Riverpod** - COMPLETED
✅ **1.3 Konfigurasi Firebase di android/app/build.gradle** - COMPLETED  
✅ **1.5 Setup struktur folder sesuai feature-first architecture** - COMPLETED

## Remaining Manual Steps

### 1.2 Setup Firebase Project dan Download google-services.json

**MANUAL ACTION REQUIRED:**

1. **Buat Firebase Project:**
   - Buka [Firebase Console](https://console.firebase.google.com/)
   - Klik "Add project" atau "Create a project"
   - Masukkan nama project: `school-app-qles` (atau nama lain)
   - Aktifkan Google Analytics (opsional)
   - Klik "Create project"

2. **Tambahkan Android App:**
   - Di Firebase Console, klik "Add app" → pilih Android
   - Masukkan package name: `com.example.q_les`
   - Masukkan app nickname: `Q-Les School App`
   - Klik "Register app"

3. **Download google-services.json:**
   - Download file `google-services.json` yang diberikan Firebase
   - **REPLACE** file `android/app/google-services.json` dengan file yang baru didownload
   - File saat ini hanya placeholder dengan nilai dummy

4. **Aktifkan Firebase Services:**
   - **Authentication:** Firebase Console → Authentication → Get started → Sign-in method → Email/Password (Enable)
   - **Firestore:** Firebase Console → Firestore Database → Create database → Start in test mode
   - **Storage:** Firebase Console → Storage → Get started → Start in test mode  
   - **Cloud Messaging:** Firebase Console → Cloud Messaging (otomatis aktif)

### 1.4 Buat firebase_options.dart dengan FlutterFire CLI

**MANUAL ACTION REQUIRED:**

1. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Login ke Firebase:**
   ```bash
   firebase login
   ```

3. **Generate firebase_options.dart:**
   ```bash
   flutterfire configure
   ```
   - Pilih project Firebase yang sudah dibuat
   - Pilih platform: Android, iOS (sesuai kebutuhan)
   - File `lib/firebase_options.dart` akan di-generate otomatis dan menggantikan placeholder

## Verification Steps

Setelah menyelesaikan langkah manual di atas:

1. **Test Firebase Connection:**
   ```bash
   flutter run
   ```
   - App harus bisa build tanpa error
   - Tidak ada error Firebase di console

2. **Verify Firebase Services:**
   - Authentication: Coba register/login user baru
   - Firestore: Cek apakah data tersimpan di Firebase Console
   - Storage: Coba upload file
   - FCM: Test notifikasi push

## Project Structure Created

```
lib/
├── main.dart ✅
├── firebase_options.dart ✅ (placeholder - needs FlutterFire CLI)
├── core/
│   ├── constants/
│   │   ├── firestore_paths.dart ✅
│   │   └── app_constants.dart ✅
│   ├── errors/
│   │   └── app_exception.dart ✅
│   ├── router/
│   │   └── app_router.dart ✅
│   └── theme/
│       └── app_theme.dart ✅
├── features/ ✅
│   ├── auth/ ✅
│   ├── class/ ✅
│   ├── assignment/ ✅
│   ├── quiz/ ✅
│   ├── exam/ ✅
│   ├── chat/ ✅
│   ├── profile/ ✅
│   ├── verification/ ✅
│   └── notification/ ✅
└── shared/ ✅
    ├── widgets/ ✅
    └── providers/ ✅
```

## Dependencies Added

### Production Dependencies:
- firebase_core: ^3.6.0
- firebase_auth: ^5.3.1
- cloud_firestore: ^5.4.3
- firebase_storage: ^12.3.2
- firebase_messaging: ^15.1.3
- flutter_riverpod: ^2.6.1
- riverpod_annotation: ^2.6.1
- go_router: ^14.6.2
- image_picker: ^1.1.2
- file_picker: ^8.1.2
- connectivity_plus: ^6.0.5
- hive: ^2.2.3
- android_intent_plus: ^5.1.0

### Development Dependencies:
- riverpod_generator: ^2.6.2
- build_runner: ^2.4.13
- mocktail: ^1.0.4
- fake_cloud_firestore: ^3.0.3
- firebase_auth_mocks: ^0.14.1
- fast_check: ^1.1.0
- hive_generator: ^2.0.1

## Android Configuration Completed

✅ **Firebase plugins added to build.gradle**
✅ **Permissions added to AndroidManifest.xml**
✅ **Exam lockdown method channel implemented**
✅ **FCM service configured**
✅ **Multidex enabled**

## Next Steps

Setelah menyelesaikan setup Firebase manual:

1. Run `flutter pub get` untuk install dependencies
2. Run `flutter run` untuk test build
3. Mulai implementasi fitur authentication (Task 2)
4. Test Firebase connection dengan membuat user pertama

## Notes

- File `google-services.json` saat ini adalah placeholder dan HARUS diganti
- File `firebase_options.dart` saat ini adalah placeholder dan HARUS di-generate ulang
- Exam lockdown mode memerlukan testing di perangkat Android fisik
- FCM memerlukan konfigurasi server-side untuk Cloud Functions (opsional untuk development)