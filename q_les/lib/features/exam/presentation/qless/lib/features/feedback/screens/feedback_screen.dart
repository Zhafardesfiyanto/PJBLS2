import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  int _rating = 0;
  bool _submitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _isLoading = true);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() { _isLoading = false; _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: _submitted
            ? _ThankYouPage(key: const ValueKey('thankyou'))
            : _FeedbackForm(
                key: const ValueKey('form'),
                formKey: _formKey,
                nameCtrl: _nameCtrl,
                emailCtrl: _emailCtrl,
                messageCtrl: _messageCtrl,
                rating: _rating,
                isLoading: _isLoading,
                onRatingChanged: (r) => setState(() => _rating = r),
                onSubmit: _submit,
              ),
      ),
    );
  }
}

// =============================================================================
// Feedback Form Page
// =============================================================================

class _FeedbackForm extends StatelessWidget {
  const _FeedbackForm({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.messageCtrl,
    required this.rating,
    required this.isLoading,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController messageCtrl;
  final int rating;
  final bool isLoading;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar row
              const _AppBarRow(),
              const SizedBox(height: 28),

              // Title
              const Text(
                'SHARE YOUR THOUGHTS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Help us improve with your valuable feedback.',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 28),

              // Name field
              _FeedbackTextField(
                controller: nameCtrl,
                hint: 'Student',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),

              // Email field
              _FeedbackTextField(
                controller: emailCtrl,
                hint: 'student@qles.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Message field
              _FeedbackTextField(
                controller: messageCtrl,
                hint: 'Mantap keren',
                maxLines: 5,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your message' : null,
              ),
              const SizedBox(height: 24),

              // Star rating
              _StarRating(
                rating: rating,
                onChanged: onRatingChanged,
              ),
              const SizedBox(height: 8),
              Text(
                'How would you rate your experience?',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E41D4),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF3E41D4).withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
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
                      : const Text(
                          'SUBMIT FEEDBACK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Thank You Page
// =============================================================================

class _ThankYouPage extends StatelessWidget {
  const _ThankYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AppBarRow(),
            const Spacer(),

            // Illustration
            Center(
              child: _FeedbackIllustration(),
            ),
            const SizedBox(height: 36),

            // Thank you text
            const Center(
              child: Text(
                'THANK YOU!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'By making your voice heard, you help us\nimprove Q-Les.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shared Widgets
// =============================================================================

/// Top app bar row with Q logo + "Q-Les Feedback" title
class _AppBarRow extends StatelessWidget {
  const _AppBarRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Q logo circle
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4FC3F7), Color(0xFF3E41D4)],
            ),
          ),
          child: const Center(
            child: Text(
              'Q',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Q-Les Feedback',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

/// Outlined text field matching the design
class _FeedbackTextField extends StatelessWidget {
  const _FeedbackTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF3E41D4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

/// 5-star rating row
class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < rating;
        return GestureDetector(
          onTap: () => onChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              filled ? Icons.star : Icons.star_border,
              color: const Color(0xFF3E41D4),
              size: 36,
            ),
          ),
        );
      }),
    );
  }
}

/// Illustration for the thank you page — woman with raised hands
/// Built with CustomPainter to match the flat illustration style
class _FeedbackIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: _WomanIllustrationPainter(),
      ),
    );
  }
}

class _WomanIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // --- Body colors ---
    final skinPaint = Paint()..color = const Color(0xFFF4C2A1);
    final bluePaint = Paint()..color = const Color(0xFF3E41D4);
    final darkNavyPaint = Paint()..color = const Color(0xFF1A1A2E);
    final accentBluePaint = Paint()..color = const Color(0xFF4FC3F7);

    // Head
    canvas.drawCircle(Offset(cx, 80), 32, skinPaint);

    // Hair
    final hairPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawCircle(Offset(cx, 68), 34, hairPaint);
    canvas.drawCircle(Offset(cx, 80), 32, skinPaint);
    // Long hair sides
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 28, 100), width: 18, height: 50),
      hairPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 28, 100), width: 18, height: 50),
      hairPaint,
    );

    // Torso (blue shirt)
    final torsoPath = Path()
      ..moveTo(cx - 30, 118)
      ..lineTo(cx + 30, 118)
      ..lineTo(cx + 38, 195)
      ..lineTo(cx - 38, 195)
      ..close();
    canvas.drawPath(torsoPath, bluePaint);

    // Left arm raised
    final leftArmPath = Path()
      ..moveTo(cx - 30, 125)
      ..quadraticBezierTo(cx - 80, 110, cx - 70, 70)
      ..lineTo(cx - 58, 72)
      ..quadraticBezierTo(cx - 68, 108, cx - 22, 130)
      ..close();
    canvas.drawPath(leftArmPath, bluePaint);

    // Right arm raised
    final rightArmPath = Path()
      ..moveTo(cx + 30, 125)
      ..quadraticBezierTo(cx + 80, 110, cx + 70, 70)
      ..lineTo(cx + 58, 72)
      ..quadraticBezierTo(cx + 68, 108, cx + 22, 130)
      ..close();
    canvas.drawPath(rightArmPath, bluePaint);

    // Left hand
    canvas.drawCircle(Offset(cx - 66, 68), 10, skinPaint);
    // Right hand
    canvas.drawCircle(Offset(cx + 66, 68), 10, skinPaint);

    // Skirt (dark navy)
    final skirtPath = Path()
      ..moveTo(cx - 38, 192)
      ..lineTo(cx + 38, 192)
      ..lineTo(cx + 50, 255)
      ..lineTo(cx - 50, 255)
      ..close();
    canvas.drawPath(skirtPath, darkNavyPaint);

    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 36, 250, 22, 30),
        const Radius.circular(6),
      ),
      darkNavyPaint,
    );

    // Right leg (slightly raised / bent)
    final rightLegPath = Path()
      ..moveTo(cx + 14, 252)
      ..lineTo(cx + 36, 252)
      ..lineTo(cx + 42, 278)
      ..lineTo(cx + 20, 278)
      ..close();
    canvas.drawPath(rightLegPath, darkNavyPaint);

    // Left shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 40, 276, 28, 12),
        const Radius.circular(6),
      ),
      accentBluePaint,
    );

    // Right shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 18, 276, 28, 12),
        const Radius.circular(6),
      ),
      accentBluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

