import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:q_les/features/profile/presentation/profile_screen.dart';
import 'package:q_les/features/profile/data/profile_repository.dart';
import 'package:q_les/features/auth/domain/user_model.dart';
import 'package:q_les/shared/providers/auth_provider.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ProfileScreen', () {
    late MockProfileRepository mockProfileRepository;

    setUp(() {
      mockProfileRepository = MockProfileRepository();
    });

    Widget createTestWidget({UserModel? user}) {
      return ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('should display user information correctly', (tester) async {
      // Arrange
      const user = UserModel(
        uid: 'test-uid',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'murid',
      );

      // Act
      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('Murid'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsWidgets);
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byIcon(Icons.badge), findsOneWidget);
    });

    testWidgets('should display verification status for guru', (tester) async {
      // Arrange
      const user = UserModel(
        uid: 'test-uid',
        fullName: 'Jane Teacher',
        email: 'jane@example.com',
        role: 'guru',
        verificationStatus: 'verified',
      );

      // Act
      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Guru'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('should display pending verification status', (tester) async {
      // Arrange
      const user = UserModel(
        uid: 'test-uid',
        fullName: 'Pending Teacher',
        email: 'pending@example.com',
        role: 'guru',
        verificationStatus: 'pending',
      );

      // Act
      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
    });

    testWidgets('should show photo options when camera button is tapped', (tester) async {
      // Arrange
      const user = UserModel(
        uid: 'test-uid',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'murid',
      );

      // Act
      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pumpAndSettle();

      // Tap camera button
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
      expect(find.text('Ambil Foto'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
    });

    testWidgets('should show logout confirmation dialog', (tester) async {
      // Arrange
      const user = UserModel(
        uid: 'test-uid',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'murid',
      );

      // Act
      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pumpAndSettle();

      // Tap logout button
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Konfirmasi'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin keluar?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('should display profile photo when available', (tester) async {
      // Arrange
      const user = UserModel(
        uid: 'test-uid',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'murid',
        photoUrl: 'https://example.com/photo.jpg',
      );

      // Act
      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.backgroundImage, isA<NetworkImage>());
    });

    testWidgets('should display default icon when no photo available', (tester) async {
      // Arrange
      const user = UserModel(
        uid: 'test-uid',
        fullName: 'John Doe',
        email: 'john@example.com',
        role: 'murid',
      );

      // Act
      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.backgroundImage, isNull);
      expect(circleAvatar.child, isA<Icon>());
    });

    testWidgets('should show error message when user is null', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(user: null));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Pengguna tidak ditemukan'), findsOneWidget);
    });

    testWidgets('should display admin role correctly', (tester) async {
      // Arrange
      const user = UserModel(
        uid: 'test-uid',
        fullName: 'Admin User',
        email: 'admin@example.com',
        role: 'admin',
      );

      // Act
      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Admin'), findsOneWidget);
      // Admin should not have verification status section
      expect(find.byIcon(Icons.verified), findsNothing);
    });
  });
}