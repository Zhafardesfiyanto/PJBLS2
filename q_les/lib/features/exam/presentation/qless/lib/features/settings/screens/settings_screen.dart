import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        children: [
          // ── ACCOUNT ──────────────────────────────────────────
          _SectionHeader(label: 'ACCOUNT'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconBgColor: AppTheme.primary.withValues(alpha: 0.15),
            iconColor: AppTheme.primary,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            trailing: const Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 20),
            onTap: () => context.push('/settings/profile'),
          ),
          _Separator(),

          // ── ABOUT ─────────────────────────────────────────────
          _SectionHeader(label: 'ABOUT'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconBgColor: Colors.grey.shade200,
            iconColor: Colors.grey.shade600,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          _Separator(),

          // ── ACTIONS ───────────────────────────────────────────
          _SectionHeader(label: 'ACTIONS'),
          _SettingsTile(
            icon: Icons.logout_rounded,
            iconBgColor: Colors.red.shade50,
            iconColor: Colors.red.shade400,
            title: 'Logout',
            titleColor: Colors.red.shade500,
            onTap: () async {
              final router = GoRouter.of(context);
              final confirmed = await _confirmLogout(context);
              if (!confirmed) return;
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              router.go('/auth');
            },
          ),
          _Separator(),
          _SettingsTile(
            icon: Icons.chat_bubble_outline_rounded,
            iconBgColor: Colors.grey.shade300,
            iconColor: Colors.grey.shade700,
            title: 'Feedback',
            onTap: () => context.push('/feedback'),
          ),
          _Separator(),
        ],
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// =============================================================================
// Section Header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// =============================================================================
// Settings Tile
// =============================================================================

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.primary.withValues(alpha: 0.06),
        highlightColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppTheme.textDark,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          
              // Trailing
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Thin separator line
// =============================================================================

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Divider(
        height: 1,
        thickness: 1,
        indent: 70,
        endIndent: 0,
        color: Color(0xFFEEEEEE),
      ),
    );
  }
}
