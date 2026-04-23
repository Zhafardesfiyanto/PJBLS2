import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/class_provider.dart';

/// Screen untuk bergabung ke kelas menggunakan kode (khusus Murid)
class JoinClassScreen extends ConsumerStatefulWidget {
  const JoinClassScreen({super.key});

  @override
  ConsumerState<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends ConsumerState<JoinClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classCodeController = TextEditingController();

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinClass() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final classJoiner = ref.read(classJoinerProvider.notifier);
      await classJoiner.joinClass(_classCodeController.text.trim().toUpperCase());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil bergabung ke kelas!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final text = clipboardData!.text!.trim().toUpperCase();
        // Validate that it looks like a class code (6 alphanumeric characters)
        if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(text)) {
          _classCodeController.text = text;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kode kelas berhasil ditempel'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format kode kelas tidak valid'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil dari clipboard'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final classJoinerState = ref.watch(classJoinerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gabung Kelas'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_add,
                      size: 48,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gabung Kelas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masukkan kode kelas yang diberikan guru',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Class code input
              TextFormField(
                controller: _classCodeController,
                decoration: InputDecoration(
                  labelText: 'Kode Kelas',
                  hintText: 'Contoh: ABC123',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste),
                    onPressed: _pasteFromClipboard,
                    tooltip: 'Tempel dari clipboard',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kode kelas tidak boleh kosong';
                  }
                  final cleanValue = value.trim().toUpperCase();
                  if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(cleanValue)) {
                    return 'Kode kelas harus 6 karakter alfanumerik';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return newValue.copyWith(text: newValue.text.toUpperCase());
                  }),
                ],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Info cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Kode kelas terdiri dari 6 karakter huruf dan angka\n'
                      '• Minta kode kelas kepada guru Anda\n'
                      '• Gunakan tombol tempel jika kode sudah disalin',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Join button
              ElevatedButton(
                onPressed: classJoinerState.isLoading ? null : _joinClass,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: classJoinerState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Gabung Kelas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}