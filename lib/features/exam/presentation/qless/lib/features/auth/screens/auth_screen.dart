import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Role toggle
  UserRole _selectedRole = UserRole.student;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  String? _loginError;

  // Register form
  final _registerFormKey = GlobalKey<FormState>();
  final _registerEmailCtrl = TextEditingController();
  final _registerPasswordCtrl = TextEditingController();
  final _registerConfirmCtrl = TextEditingController();
  String? _registerError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _registerEmailCtrl.dispose();
    _registerPasswordCtrl.dispose();
    _registerConfirmCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _persistRoleAndNavigate(UserRole role) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'user_role', value: role.name);
    if (!mounted) return;
    context.go(role == UserRole.teacher ? '/teacher' : '/student');
  }

  void _showError({required bool isLogin, required String message}) {
    // Display within 300 ms — we schedule immediately (no artificial delay)
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      setState(() {
        if (isLogin) {
          _loginError = message;
        } else {
          _registerError = message;
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Auth actions
  // ---------------------------------------------------------------------------

  Future<void> _handleLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _loginError = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        _loginEmailCtrl.text.trim(),
        _loginPasswordCtrl.text,
      );
      await _persistRoleAndNavigate(_selectedRole);
    } catch (e) {
      _showError(isLogin: true, message: _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _registerError = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.registerWithEmail(
        _registerEmailCtrl.text.trim(),
        _registerPasswordCtrl.text,
        _selectedRole,
      );
      await _persistRoleAndNavigate(_selectedRole);
    } catch (e) {
      _showError(isLogin: false, message: _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _loginError = null;
      _registerError = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      await _persistRoleAndNavigate(_selectedRole);
    } catch (e) {
      final isLogin = _tabController.index == 0;
      _showError(isLogin: isLogin, message: _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found') || msg.contains('wrong-password')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('google-sign-in-cancelled')) {
      return 'Google Sign-In was cancelled.';
    }
    return 'Authentication failed. Please try again.';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildRoleToggle(),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _buildTabBar(),
                      _buildTabContent(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildGoogleButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Q-Les',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.cobaltBlue,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'E-Learning Platform',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<UserRole>(
          key: const Key('role_toggle'),
          segments: const [
            ButtonSegment(
              value: UserRole.student,
              label: Text('Student'),
              icon: Icon(Icons.school_outlined),
            ),
            ButtonSegment(
              value: UserRole.teacher,
              label: Text('Teacher'),
              icon: Icon(Icons.person_outline),
            ),
          ],
          selected: {_selectedRole},
          onSelectionChanged: (selection) {
            setState(() => _selectedRole = selection.first);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.cobaltBlue;
              }
              return Colors.white.withValues(alpha: 0.7);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return AppTheme.cobaltBlue;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      key: const Key('auth_tab_bar'),
      controller: _tabController,
      labelColor: AppTheme.cobaltBlue,
      unselectedLabelColor: Colors.grey[600],
      indicatorColor: AppTheme.cobaltBlue,
      tabs: const [
        Tab(text: 'Login'),
        Tab(text: 'Register'),
      ],
    );
  }

  Widget _buildTabContent() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 0) {
          return _buildLoginForm();
        }
        return _buildRegisterForm();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Login form
  // ---------------------------------------------------------------------------

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmailField(
              key: const Key('login_email'),
              controller: _loginEmailCtrl,
              label: 'Email',
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              key: const Key('login_password'),
              controller: _loginPasswordCtrl,
              label: 'Password',
            ),
            if (_loginError != null) ...[
              const SizedBox(height: 8),
              _buildInlineError(key: const Key('login_error'), message: _loginError!),
            ],
            const SizedBox(height: 20),
            _buildSubmitButton(
              key: const Key('login_submit'),
              label: 'Login',
              onPressed: _isLoading ? null : _handleLogin,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Register form
  // ---------------------------------------------------------------------------

  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmailField(
              key: const Key('register_email'),
              controller: _registerEmailCtrl,
              label: 'Email',
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              key: const Key('register_password'),
              controller: _registerPasswordCtrl,
              label: 'Password',
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              key: const Key('register_confirm'),
              controller: _registerConfirmCtrl,
              label: 'Confirm Password',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password.';
                }
                if (value != _registerPasswordCtrl.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            if (_registerError != null) ...[
              const SizedBox(height: 8),
              _buildInlineError(
                  key: const Key('register_error'), message: _registerError!),
            ],
            const SizedBox(height: 20),
            _buildSubmitButton(
              key: const Key('register_submit'),
              label: 'Create Account',
              onPressed: _isLoading ? null : _handleRegister,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared form widgets
  // ---------------------------------------------------------------------------

  Widget _buildEmailField({
    required Key key,
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email.';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email address.';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required Key key,
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password.';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters.';
            }
            return null;
          },
    );
  }

  Widget _buildInlineError({required Key key, required String message}) {
    return Row(
      key: key,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return FilledButton(
      key: key,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.cobaltBlue,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      key: const Key('google_sign_in'),
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      icon: const Icon(Icons.g_mobiledata, size: 24),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.cobaltBlue,
        side: const BorderSide(color: AppTheme.cobaltBlue),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
