import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/class/presentation/class_list_screen.dart';
import '../../features/class/presentation/class_detail_screen.dart';
import '../../features/class/presentation/create_class_screen.dart';
import '../../features/class/presentation/join_class_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/verification/presentation/verification_pending_screen.dart';
import '../../features/verification/presentation/admin_verification_screen.dart';

/// Provider untuk GoRouter dengan role-based routing
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      
      return authState.when(
        data: (user) {
          final currentPath = state.uri.path;
          
          // Jika user null, redirect ke login (kecuali sudah di auth pages)
          if (user == null) {
            if (currentPath == '/login' || currentPath == '/register') {
              return null; // Stay on current auth page
            }
            return '/login';
          }
          
          // Jika user sudah login, redirect dari auth pages ke dashboard
          if (currentPath == '/login' || currentPath == '/register') {
            if (user.isAdmin) {
              return '/admin/verifications';
            } else if (user.isGuru && !user.isVerified) {
              return '/verification-pending';
            } else {
              return '/classes';
            }
          }
          
          // Role-based access control
          if (user.isGuru && !user.isVerified && currentPath != '/verification-pending') {
            return '/verification-pending';
          }
          
          if (currentPath.startsWith('/admin') && !user.isAdmin) {
            return '/classes'; // Non-admin tidak bisa akses admin pages
          }
          
          return null; // Allow navigation
        },
        loading: () => null, // Stay on current page while loading
        error: (_, _) => '/login', // Redirect to login on auth error
      );
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/classes',
        name: 'classes',
        builder: (context, state) => const ClassListScreen(),
        routes: [
          // Create class route (for teachers)
          GoRoute(
            path: '/create',
            name: 'create-class',
            builder: (context, state) => const CreateClassScreen(),
          ),
          
          // Join class route (for students)
          GoRoute(
            path: '/join',
            name: 'join-class',
            builder: (context, state) => const JoinClassScreen(),
          ),
          
          // Class detail routes
          GoRoute(
            path: '/:classId',
            name: 'class-detail',
            builder: (context, state) {
              final classId = state.pathParameters['classId']!;
              return ClassDetailScreen(classId: classId);
            },
            routes: [
              // Assignment routes
              GoRoute(
                path: '/assignments/:assignmentId',
                name: 'assignment-detail',
                builder: (context, state) {
                  final assignmentId = state.pathParameters['assignmentId']!;
                  return Scaffold(
                    appBar: AppBar(title: Text('Assignment $assignmentId')),
                    body: const Center(
                      child: Text('Assignment Detail - Coming Soon'),
                    ),
                  );
                },
              ),
              
              // Quiz routes
              GoRoute(
                path: '/quiz/:quizId',
                name: 'quiz-detail',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId']!;
                  return Scaffold(
                    appBar: AppBar(title: Text('Quiz $quizId')),
                    body: const Center(
                      child: Text('Quiz Detail - Coming Soon'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      
      // Exam route (full-screen, replaces all navigation)
      GoRoute(
        path: '/exam/:examId',
        name: 'exam',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.quiz,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Exam Mode: $examId',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Exam Lockdown Screen - Coming Soon',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      
      // Profile route
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Verification routes
      GoRoute(
        path: '/verification-pending',
        name: 'verification-pending',
        builder: (context, state) => const VerificationPendingScreen(),
      ),
      
      // Admin routes
      GoRoute(
        path: '/admin',
        name: 'admin',
        redirect: (context, state) => '/admin/verifications',
      ),
      GoRoute(
        path: '/admin/verifications',
        name: 'admin-verifications',
        builder: (context, state) => const AdminVerificationScreen(),
      ),
    ],
    
    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Halaman Tidak Ditemukan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Path: ${state.uri.path}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/classes'),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Extension untuk navigasi yang lebih mudah
extension AppRouterExtension on GoRouter {
  /// Navigate to login screen
  void goToLogin() => go('/login');
  
  /// Navigate to register screen
  void goToRegister() => go('/register');
  
  /// Navigate to classes list
  void goToClasses() => go('/classes');
  
  /// Navigate to create class screen
  void goToCreateClass() => go('/classes/create');
  
  /// Navigate to join class screen
  void goToJoinClass() => go('/classes/join');
  
  /// Navigate to class detail
  void goToClassDetail(String classId) => go('/classes/$classId');
  
  /// Navigate to assignment detail
  void goToAssignmentDetail(String classId, String assignmentId) =>
      go('/classes/$classId/assignments/$assignmentId');
  
  /// Navigate to quiz detail
  void goToQuizDetail(String classId, String quizId) =>
      go('/classes/$classId/quiz/$quizId');
  
  /// Navigate to exam (full-screen mode)
  void goToExam(String examId) => go('/exam/$examId');
  
  /// Navigate to profile
  void goToProfile() => go('/profile');
  
  /// Navigate to verification pending
  void goToVerificationPending() => go('/verification-pending');
  
  /// Navigate to admin verifications
  void goToAdminVerifications() => go('/admin/verifications');
}