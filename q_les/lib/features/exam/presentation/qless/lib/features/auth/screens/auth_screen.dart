import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/models/user_role.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isRegisterMode = false;

  void _switchToRegister() => setState(() => _isRegisterMode = true);
  void _switchToLogin() => setState(() => _isRegisterMode = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isRegisterMode
            ? _RegisterPage(
                key: const ValueKey('register'),
                onSwitchToLogin: _switchToLogin,
              )
            : _LoginPage(
                key: const ValueKey('login'),
                onSwitchToRegister: _switchToRegister,
              ),
      ),
    );
  }
}

// =============================================================================
// Login Page
// =============================================================================

class _LoginPage extends ConsumerStatefulWidget {
  const _LoginPage({super.key, required this.onSwitchToRegister});
  final VoidCallback onSwitchToRegister;

  @override
  ConsumerState<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<_LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  // Default role — user can change on register; login uses stored role
  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _persistRoleAndNavigate(UserRole role) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'user_role', value: role.name);
    if (!mounted) return;
    GoRouter.of(context).go(role == UserRole.teacher ? '/teacher' : '/student');
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      final role = authService.cachedRole ?? _selectedRole;
      await _persistRoleAndNavigate(role);
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      final role = authService.cachedRole ?? _selectedRole;
      await _persistRoleAndNavigate(role);
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found') || msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('invalid-email')) { return 'Please enter a valid email.'; }
    if (msg.contains('google-sign-in-cancelled')) { return 'Google Sign-In was cancelled.'; }
    return 'Authentication failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              _QLesLogo(),
              const SizedBox(height: 20),
              const Text(
                'Q-Les',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Learn and teach together',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 40),

              // Role selector (subtle)
              _RoleSelector(
                selected: _selectedRole,
                onChanged: (r) => setState(() => _selectedRole = r),
              ),
              const SizedBox(height: 24),

              // Email
              _FieldLabel(label: 'Email'),
              const SizedBox(height: 8),
              _AuthTextField(
                key: const Key('login_email'),
                controller: _emailCtrl,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password
              _FieldLabel(label: 'Password'),
              const SizedBox(height: 8),
              _AuthTextField(
                key: const Key('login_password'),
                controller: _passwordCtrl,
                hint: 'Enter your password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your password';
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],

              const SizedBox(height: 24),

              // Google button
              _GoogleButton(onPressed: _isLoading ? null : _handleGoogle),
              const SizedBox(height: 12),

              // Login button
              _PrimaryButton(
                key: const Key('login_submit'),
                label: 'Login',
                icon: Icons.lock_clock_outlined,
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 24),

              // Switch to register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: widget.onSwitchToRegister,
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Color(0xFF3E41D4),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Register Page
// =============================================================================

class _RegisterPage extends ConsumerStatefulWidget {
  const _RegisterPage({super.key, required this.onSwitchToLogin});
  final VoidCallback onSwitchToLogin;

  @override
  ConsumerState<_RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<_RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;
  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _persistRoleAndNavigate(UserRole role) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'user_role', value: role.name);
    if (!mounted) return;
    GoRouter.of(context).go(role == UserRole.teacher ? '/teacher' : '/student');
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.registerWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _selectedRole,
      );
      await _persistRoleAndNavigate(_selectedRole);
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      await _persistRoleAndNavigate(_selectedRole);
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) return 'An account with this email already exists.';
    if (msg.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (msg.contains('invalid-email')) return 'Please enter a valid email.';
    if (msg.contains('google-sign-in-cancelled')) return 'Google Sign-In was cancelled.';
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _QLesLogo(),
              const SizedBox(height: 16),
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Join Q-Les today',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 28),

              // Role selector
              _RoleSelector(
                selected: _selectedRole,
                onChanged: (r) => setState(() => _selectedRole = r),
              ),
              const SizedBox(height: 20),

              // Full name
              _FieldLabel(label: 'Full Name'),
              const SizedBox(height: 8),
              _AuthTextField(
                key: const Key('register_name'),
                controller: _nameCtrl,
                hint: 'Enter your full name',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your name';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              _FieldLabel(label: 'Email'),
              const SizedBox(height: 8),
              _AuthTextField(
                key: const Key('register_email'),
                controller: _emailCtrl,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              _FieldLabel(label: 'Password'),
              const SizedBox(height: 8),
              _AuthTextField(
                key: const Key('register_password'),
                controller: _passwordCtrl,
                hint: 'Create a password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a password';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm password
              _FieldLabel(label: 'Confirm Password'),
              const SizedBox(height: 8),
              _AuthTextField(
                key: const Key('register_confirm'),
                controller: _confirmCtrl,
                hint: 'Repeat your password',
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirm your password';
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],

              const SizedBox(height: 24),

              // Google button
              _GoogleButton(onPressed: _isLoading ? null : _handleGoogle),
              const SizedBox(height: 12),

              // Register button
              _PrimaryButton(
                key: const Key('register_submit'),
                label: 'Create Account',
                icon: Icons.person_add_outlined,
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 24),

              // Switch to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: widget.onSwitchToLogin,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF3E41D4),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Shared Widgets
// =============================================================================

/// Q-Les logo — menggunakan asset gambar logo asli
class _QLesLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: 80,
        height: 80,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback ke gradient Q jika asset belum ada
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4FC3F7), Color(0xFF3E41D4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3E41D4).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Q',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bold field label above each text field
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

/// Rounded text field with light grey fill — matches the design
class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E41D4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

/// Google sign-in outline button
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: const Key('google_sign_in'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google "G" logo using colored text segments
          _GoogleGIcon(),
          const SizedBox(width: 10),
          const Text(
            'Google',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple Google "G" icon built with RichText
class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw colored arcs for Google G
    final segments = [
      (0.0, 1.57, const Color(0xFF4285F4)),   // blue top-right
      (1.57, 3.14, const Color(0xFF34A853)),  // green bottom-right
      (3.14, 4.71, const Color(0xFFFBBC05)),  // yellow bottom-left
      (4.71, 6.28, const Color(0xFFEA4335)),  // red top-left
    ];

    for (final (start, end, color) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1.75),
        start,
        end - start,
        false,
        paint,
      );
    }

    // White cutout for the "G" horizontal bar
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - 2, radius, 4),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Purple primary action button
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3E41D4),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF3E41D4).withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Role selector — compact segmented control
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      key: const Key('role_toggle'),
      segments: const [
        ButtonSegment(
          value: UserRole.student,
          label: Text('Student'),
          icon: Icon(Icons.school_outlined, size: 16),
        ),
        ButtonSegment(
          value: UserRole.teacher,
          label: Text('Teacher'),
          icon: Icon(Icons.person_outline, size: 16),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF3E41D4);
          }
          return const Color(0xFFF2F2F2);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.grey[600];
        }),
        side: WidgetStateProperty.all(BorderSide.none),
      ),
    );
  }
}

/// Inline error banner
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}


