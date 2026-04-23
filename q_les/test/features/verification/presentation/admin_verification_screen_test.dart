import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_les/features/verification/presentation/admin_verification_screen.dart';
import 'package:q_les/features/verification/domain/verification_request_model.dart';
import 'package:q_les/features/verification/data/verification_provider.dart';

void main() {
  group('AdminVerificationScreen', () {
    testWidgets('should display loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingVerificationRequestsProvider.overrideWith(
              (ref) => Stream.value(<VerificationRequestModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: AdminVerificationScreen(),
          ),
        ),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no pending requests', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingVerificationRequestsProvider.overrideWith(
              (ref) => Stream.value(<VerificationRequestModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: AdminVerificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tidak ada permintaan verifikasi'), findsOneWidget);
      expect(find.text('Semua guru sudah terverifikasi'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display list of pending verification requests', (tester) async {
      final mockRequests = [
        VerificationRequestModel(
          id: 'req1',
          teacherId: 'teacher1',
          teacherName: 'John Doe',
          status: VerificationStatus.pending,
          createdAt: DateTime(2024, 1, 1),
        ),
        VerificationRequestModel(
          id: 'req2',
          teacherId: 'teacher2',
          teacherName: 'Jane Smith',
          status: VerificationStatus.pending,
          createdAt: DateTime(2024, 1, 2),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingVerificationRequestsProvider.overrideWith(
              (ref) => Stream.value(mockRequests),
            ),
          ],
          child: const MaterialApp(
            home: AdminVerificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display both requests
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Setujui'), findsNWidgets(2));
      expect(find.text('Tolak'), findsNWidgets(2));
    });

    testWidgets('should show approval dialog when approve button is tapped', (tester) async {
      final mockRequest = VerificationRequestModel(
        id: 'req1',
        teacherId: 'teacher1',
        teacherName: 'John Doe',
        status: VerificationStatus.pending,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingVerificationRequestsProvider.overrideWith(
              (ref) => Stream.value([mockRequest]),
            ),
            verificationControllerProvider.overrideWith(
              () => MockVerificationController(),
            ),
          ],
          child: const MaterialApp(
            home: AdminVerificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap approve button
      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Konfirmasi Persetujuan'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin menyetujui verifikasi untuk John Doe?'), findsOneWidget);
    });

    testWidgets('should show rejection dialog when reject button is tapped', (tester) async {
      final mockRequest = VerificationRequestModel(
        id: 'req1',
        teacherId: 'teacher1',
        teacherName: 'John Doe',
        status: VerificationStatus.pending,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingVerificationRequestsProvider.overrideWith(
              (ref) => Stream.value([mockRequest]),
            ),
            verificationControllerProvider.overrideWith(
              () => MockVerificationController(),
            ),
          ],
          child: const MaterialApp(
            home: AdminVerificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap reject button
      await tester.tap(find.text('Tolak'));
      await tester.pumpAndSettle();

      // Should show rejection dialog
      expect(find.text('Tolak Verifikasi'), findsOneWidget);
      expect(find.text('Menolak verifikasi untuk John Doe'), findsOneWidget);
      expect(find.text('Alasan penolakan'), findsOneWidget);
    });

    testWidgets('should display error state when stream has error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingVerificationRequestsProvider.overrideWith(
              (ref) => Stream.error('Network error'),
            ),
          ],
          child: const MaterialApp(
            home: AdminVerificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Error: Network error'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should refresh data when pull to refresh', (tester) async {
      final mockRequests = [
        VerificationRequestModel(
          id: 'req1',
          teacherId: 'teacher1',
          teacherName: 'John Doe',
          status: VerificationStatus.pending,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingVerificationRequestsProvider.overrideWith(
              (ref) => Stream.value(mockRequests),
            ),
          ],
          child: const MaterialApp(
            home: AdminVerificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the RefreshIndicator and trigger refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should complete without errors
      expect(find.text('John Doe'), findsOneWidget);
    });
  });
}

// Mock controller for testing
class MockVerificationController extends VerificationController {
  @override
  FutureOr<void> build() async {}

  @override
  Future<void> approveVerification(String requestId, String teacherId) async {}

  @override
  Future<void> rejectVerification(String requestId, String teacherId, String reason) async {}
}