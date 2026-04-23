import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/logout_button.dart';
import '../data/verification_provider.dart';

/// Screen untuk guru yang menunggu verifikasi
class VerificationPendingScreen extends ConsumerWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final verificationRequestAsync = user != null 
        ? ref.watch(verificationRequestProvider(user.uid))
        : const AsyncValue.data(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Verifikasi'),
        automaticallyImplyLeading: false,
        actions: const [
          LogoutButton(isIconButton: true),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: verificationRequestAsync.when(
          data: (request) => _buildContent(context, ref, user, request),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorContent(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, user, request) {
    if (user?.isRejected == true) {
      return _buildRejectedContent(context, ref, user, request);
    }
    
    return _buildPendingContent(context, ref, user, request);
  }

  Widget _buildPendingContent(BuildContext context, WidgetRef ref, user, request) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_empty,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            'Halo, ${user?.fullName ?? 'Guru'}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Akun Anda sedang dalam proses verifikasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Informasi Verifikasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• Admin sedang meninjau akun Anda\n'
                      '• Proses verifikasi biasanya memakan waktu 1-2 hari kerja\n'
                      '• Anda akan mendapat notifikasi setelah verifikasi selesai\n'
                      '• Sementara ini, Anda dapat melihat kelas yang sudah ada',
                      style: TextStyle(fontSize: 14),
                    ),
                    if (request != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Tanggal Pengajuan: ${_formatDate(request.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Refresh auth state
                  ref.invalidate(authStateProvider);
                  if (user != null) {
                    ref.invalidate(verificationRequestProvider(user.uid));
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Periksa Status'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to classes (read-only mode)
                  // Will be implemented in class management task
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Lihat Kelas'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedContent(BuildContext context, WidgetRef ref, user, request) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cancel,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            'Halo, ${user?.fullName ?? 'Guru'}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verifikasi Akun Ditolak',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Alasan Penolakan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  request?.rejectionReason ?? 'Tidak ada alasan yang diberikan',
                  style: const TextStyle(fontSize: 14),
                ),
                if (request != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal Penolakan: ${request.reviewedAt != null ? _formatDate(request.reviewedAt!) : 'Tidak diketahui'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Contact admin or reapply
                  _showContactAdminDialog(context);
                },
                icon: const Icon(Icons.contact_support),
                label: const Text('Hubungi Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Refresh status
                  ref.invalidate(authStateProvider);
                  if (user != null) {
                    ref.invalidate(verificationRequestProvider(user.uid));
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Periksa Status'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, WidgetRef ref, error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(authStateProvider);
              final user = ref.read(currentUserProvider);
              if (user != null) {
                ref.invalidate(verificationRequestProvider(user.uid));
              }
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showContactAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hubungi Admin'),
        content: const Text(
          'Untuk informasi lebih lanjut mengenai penolakan verifikasi, '
          'silakan hubungi administrator sekolah atau kirim email ke admin@sekolah.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}