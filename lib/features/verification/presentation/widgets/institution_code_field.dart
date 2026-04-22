import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/verification_provider.dart';

/// Widget untuk input kode verifikasi institusi
class InstitutionCodeField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(bool isValid)? onValidationChanged;

  const InstitutionCodeField({
    super.key,
    required this.controller,
    this.onValidationChanged,
  });

  @override
  ConsumerState<InstitutionCodeField> createState() => _InstitutionCodeFieldState();
}

class _InstitutionCodeFieldState extends ConsumerState<InstitutionCodeField> {
  bool _isValidating = false;
  bool? _isValid;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCodeChanged);
    super.dispose();
  }

  void _onCodeChanged() {
    if (widget.controller.text.isEmpty) {
      setState(() {
        _isValid = null;
        _errorMessage = null;
      });
      widget.onValidationChanged?.call(false);
      return;
    }

    // Debounce validation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.controller.text.isNotEmpty) {
        _validateCode();
      }
    });
  }

  Future<void> _validateCode() async {
    final code = widget.controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final isValid = await ref.read(verificationControllerProvider.notifier)
          .validateInstitutionCode(code);
      
      if (mounted) {
        setState(() {
          _isValid = isValid;
          _isValidating = false;
          _errorMessage = isValid ? null : 'Kode institusi tidak valid atau sudah kedaluwarsa';
        });
        widget.onValidationChanged?.call(isValid);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValid = false;
          _isValidating = false;
          _errorMessage = 'Gagal memvalidasi kode institusi';
        });
        widget.onValidationChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Kode Institusi (Opsional)',
            hintText: 'Masukkan kode verifikasi institusi',
            border: const OutlineInputBorder(),
            suffixIcon: _buildSuffixIcon(),
            errorText: _errorMessage,
            helperText: 'Jika Anda memiliki kode verifikasi dari institusi, '
                'masukkan di sini untuk verifikasi otomatis',
            helperMaxLines: 2,
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            // Auto uppercase
            final upperValue = value.toUpperCase();
            if (upperValue != value) {
              widget.controller.value = widget.controller.value.copyWith(
                text: upperValue,
                selection: TextSelection.collapsed(offset: upperValue.length),
              );
            }
          },
        ),
        if (_isValid == true) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                'Kode valid - Verifikasi otomatis akan diaktifkan',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isValidating) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isValid == true) {
      return Icon(Icons.check_circle, color: Colors.green.shade600);
    }

    if (_isValid == false) {
      return Icon(Icons.error, color: Colors.red.shade600);
    }

    return null;
  }
}