import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_les/features/verification/presentation/widgets/institution_code_field.dart';
import 'package:q_les/features/verification/data/verification_provider.dart';

void main() {
  group('InstitutionCodeField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should display field with correct labels and hints', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InstitutionCodeField(controller: controller),
            ),
          ),
        ),
      );

      expect(find.text('Kode Institusi (Opsional)'), findsOneWidget);
      expect(find.text('Masukkan kode verifikasi institusi'), findsOneWidget);
      expect(find.text('Jika Anda memiliki kode verifikasi dari institusi, '
          'masukkan di sini untuk verifikasi otomatis'), findsOneWidget);
    });

    testWidgets('should convert input to uppercase', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InstitutionCodeField(controller: controller),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Enter lowercase text
      await tester.enterText(textField, 'school123');
      await tester.pump();

      // Should be converted to uppercase
      expect(controller.text, equals('SCHOOL123'));
    });

    testWidgets('should show loading indicator during validation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verificationControllerProvider.overrideWith(
              () => MockVerificationController(delay: const Duration(seconds: 1)),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: InstitutionCodeField(controller: controller),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Enter text to trigger validation
      await tester.enterText(textField, 'SCHOOL123');
      await tester.pump(const Duration(milliseconds: 600)); // After debounce

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show success icon for valid code', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verificationControllerProvider.overrideWith(
              () => MockVerificationController(validationResult: true),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: InstitutionCodeField(controller: controller),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Enter valid code
      await tester.enterText(textField, 'VALID123');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Should show success icon and message
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Kode valid - Verifikasi otomatis akan diaktifkan'), findsOneWidget);
    });

    testWidgets('should show error icon and message for invalid code', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verificationControllerProvider.overrideWith(
              () => MockVerificationController(validationResult: false),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: InstitutionCodeField(controller: controller),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Enter invalid code
      await tester.enterText(textField, 'INVALID123');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Should show error icon and message
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Kode institusi tidak valid atau sudah kedaluwarsa'), findsOneWidget);
    });

    testWidgets('should call validation callback with correct result', (tester) async {
      bool? callbackResult;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verificationControllerProvider.overrideWith(
              () => MockVerificationController(validationResult: true),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: InstitutionCodeField(
                controller: controller,
                onValidationChanged: (isValid) {
                  callbackResult = isValid;
                },
              ),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Enter valid code
      await tester.enterText(textField, 'VALID123');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Callback should be called with true
      expect(callbackResult, isTrue);
    });

    testWidgets('should clear validation state when field is emptied', (tester) async {
      bool? callbackResult;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verificationControllerProvider.overrideWith(
              () => MockVerificationController(validationResult: true),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: InstitutionCodeField(
                controller: controller,
                onValidationChanged: (isValid) {
                  callbackResult = isValid;
                },
              ),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Enter and then clear text
      await tester.enterText(textField, 'VALID123');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      
      await tester.enterText(textField, '');
      await tester.pump();

      // Should clear validation state
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error), findsNothing);
      expect(callbackResult, isFalse);
    });

    testWidgets('should handle validation error gracefully', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verificationControllerProvider.overrideWith(
              () => MockVerificationController(shouldThrowError: true),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: InstitutionCodeField(controller: controller),
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Enter code that will cause error
      await tester.enterText(textField, 'ERROR123');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Gagal memvalidasi kode institusi'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}

// Mock controller for testing
class MockVerificationController extends VerificationController {
  final bool? validationResult;
  final Duration? delay;
  final bool shouldThrowError;

  MockVerificationController({
    this.validationResult,
    this.delay,
    this.shouldThrowError = false,
  });

  @override
  FutureOr<void> build() async {}

  @override
  Future<bool> validateInstitutionCode(String code) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    
    if (shouldThrowError) {
      throw Exception('Validation error');
    }
    
    return validationResult ?? false;
  }
}