import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/exam/screens/exam_interface.dart';
import '../../features/student/screens/student_dashboard.dart';
import '../../features/teacher/screens/teacher_dashboard.dart';
import '../../shared/models/user_role.dart';

/// A [ChangeNotifier] that listens to [authStateProvider] changes and
/// notifies GoRouter to re-evaluate the redirect guard.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, _) {
      notifyListeners();
    });
  }
}

/// Riverpod provider for the app's [GoRouter].
///
/// Watches [authStateProvider] and [roleProvider] to drive the router guard,
/// satisfying Requirements 2.5, 2.6, and 9.3.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.valueOrNull != null;
      final isOnAuth = state.matchedLocation == '/auth';

      // Not authenticated — send to /auth unless already there.
      if (!isAuthenticated) {
        return isOnAuth ? null : '/auth';
      }

      // Authenticated and on /auth — redirect to the correct dashboard.
      if (isOnAuth) {
        final roleAsync = ref.read(roleProvider);
        final role = roleAsync.valueOrNull;
        return role == UserRole.teacher ? '/teacher' : '/student';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/exam',
        builder: (context, state) => const ExamInterface(),
      ),
    ],
  );
});
