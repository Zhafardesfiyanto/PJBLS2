import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_les/features/verification/presentation/verification_pending_screen.dart';
import 'package:q_les/features/verification/domain/verification_request_model.dart';
import 'package:q_les/features/verification/data/verification_provider.dart';
import 'package:q_les/features/auth/domain/user_model.dart';
import 'package:q_les/shared/providers/auth_provider.dart';

void main() {
  group('VerificationPendingScreen', () {
    testWidgets('should display pending verification content for pending teacher', (tester) async {
      final mockUser = UserModel(
        uid: 'teacher123',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'guru',
        verificationStatus: 'pending',
      );

      final mockRequest = VerificationRequestModel(
        id: 'req1',
        teacherId: 'teacher123',
        teacherName: 'John Doe',
        status: VerificationStatus.pending,
        createdAt: DateTime(2024, 1, 1, 10, 30),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            verificationRequestProvider('teacher123').overrideWith(
              (ref) => Future.value(mockRequest),
            ),
          ],
          child: const MaterialApp(
            home: VerificationPendingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display pending content
      expect(find.text('Halo, John Doe!'), findsOneWidget);
      expect(find.text('Akun Anda sedang dalam proses verifikasi'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.text('Informasi Verifikasi'), findsOneWidget);
      expect(find.text('Tanggal Pengajuan: 1/1/2024 10:30'), findsOneWidget);
      expect(find.text('Periksa Status'), findsOneWidget);
      expect(find.text('Lihat Kelas'), findsOneWidget);
    });

    testWidgets('should display rejected verification content for rejected teacher', (tester) async {
      final mockUser = UserModel(
        uid: 'teacher123',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'guru',
        verificationStatus: 'rejected',
      );

      final mockRequest = VerificationRequestModel(
        id: 'req1',
        teacherId: 'teacher123',
        teacherName: 'John Doe',
        status: VerificationStatus.rejected,
        createdAt: DateTime(2024, 1, 1, 10, 30),
        rejectionReason: 'Invalid credentials provided',
        reviewedAt: DateTime(2024, 1, 2, 14, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            verificationRequestProvider('teacher123').overrideWith(
              (ref) => Future.value(mockRequest),
            ),
          ],
          child: const MaterialApp(
            home: VerificationPendingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display rejected content
      expect(find.text('Halo, John Doe!'), findsOneWidget);
      expect(find.text('Verifikasi Akun Ditolak'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.text('Alasan Penolakan'), findsOneWidget);
      expect(find.text('Invalid credentials provided'), findsOneWidget);
      expect(find.text('Tanggal Penolakan: 2/1/2024 14:15'), findsOneWidget);
      expect(find.text('Hubungi Admin'), findsOneWidget);
    });

    testWidgets('should show contact admin dialog when button is tapped', (tester) async {
      final mockUser = UserModel(
        uid: 'teacher123',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'guru',
        verificationStatus: 'rejected',
      );

      final mockRequest = VerificationRequestModel(
        id: 'req1',
        teacherId: 'teacher123',
        teacherName: 'John Doe',
        status: VerificationStatus.rejected,
        createdAt: DateTime(2024, 1, 1),
        rejectionReason: 'Invalid credentials',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            verificationRequestProvider('teacher123').overrideWith(
              (ref) => Future.value(mockRequest),
            ),
          ],
          child: const MaterialApp(
            home: VerificationPendingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap contact admin button
      await tester.tap(find.text('Hubungi Admin'));
      await tester.pumpAndSettle();

      // Should show contact dialog
      expect(find.text('Hubungi Admin'), findsNWidgets(2)); // Button + Dialog title
      expect(find.text('Untuk informasi lebih lanjut mengenai penolakan verifikasi'), findsOneWidget);
      expect(find.text('admin@sekolah.com'), findsOneWidget);
    });

    testWidgets('should display loading indicator when verification request is loading', (tester) async {
      final mockUser = UserModel(
        uid: 'teacher123',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'guru',
        verificationStatus: 'pending',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            verificationRequestProvider('teacher123').overrideWith(
              (ref) => Future.delayed(
                const Duration(seconds: 1),
                () => null,
              ),
            ),
          ],
          child: const MaterialApp(
            home: VerificationPendingScreen(),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error content when verification request fails', (tester) async {
      final mockUser = UserModel(
        uid: 'teacher123',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'guru',
        verificationStatus: 'pending',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            verificationRequestProvider('teacher123').overrideWith(
              (ref) => Future.error('Network error'),
            ),
          ],
          child: const MaterialApp(
            home: VerificationPendingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display error content
      expect(find.text('Error: Network error'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should handle null user gracefully', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: VerificationPendingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display default content without crashing
      expect(find.text('Halo, Guru!'), findsOneWidget);
    });

    testWidgets('should refresh status when refresh button is tapped', (tester) async {
      final mockUser = UserModel(
        uid: 'teacher123',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'guru',
        verificationStatus: 'pending',
      );

      bool refreshCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            verificationRequestProvider('teacher123').overrideWith(
              (ref) {
                refreshCalled = true;
                return Future.value(null);
              },
            ),
          ],
          child: const MaterialApp(
            home: VerificationPendingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap refresh button
      await tester.tap(find.text('Periksa Status'));
      await tester.pumpAndSettle();

      // Should trigger refresh
      expect(refreshCalled, isTrue);
    });
  });
}