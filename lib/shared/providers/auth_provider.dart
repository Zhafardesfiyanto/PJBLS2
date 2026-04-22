import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/user_model.dart';

part 'auth_provider.g.dart';

/// Provider untuk AuthRepository
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return FirebaseAuthRepository();
}

/// Provider untuk current user stream
@riverpod
Stream<UserModel?> authState(AuthStateRef ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
}

/// Provider untuk current user (synchronous)
@riverpod
UserModel? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, _) => null,
  );
}

/// Auth controller untuk login, register, logout
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  /// Register new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? institutionCode,
  }) async {
    state = const AsyncLoading();
    
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        institutionCode: institutionCode,
      );
      
      state = const AsyncData(null);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Login user
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.login(email, password);
      state = const AsyncData(null);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle({required String role}) async {
    state = const AsyncLoading();
    
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.signInWithGoogle(role: role);
      state = const AsyncData(null);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    state = const AsyncLoading();
    
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.logout();
      
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}