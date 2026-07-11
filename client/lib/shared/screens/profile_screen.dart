import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/storage/secure_storage.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic> _user = {};
  String _appVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userJson = await SecureStorage.getUser();
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _user = userJson != null
            ? jsonDecode(userJson) as Map<String, dynamic>
            : {};
        _appVersion = 'v${info.version}';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await SecureStorage.clearAll();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _user['name'] as String? ?? '';
    final email = _user['email'] as String? ?? '';
    final role = _user['role'] as String? ?? '';
    final status = _user['status'] as String? ?? 'active';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),

          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.infoLight,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Center(
            child: Text(
              email,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Role + Status badges
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Badge(
                  label: role.toUpperCase(),
                  color: AppColors.primary,
                  bg: AppColors.infoLight,
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: status.toUpperCase(),
                  color: status == 'active'
                      ? AppColors.success
                      : AppColors.danger,
                  bg: status == 'active'
                      ? AppColors.successLight
                      : AppColors.dangerLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(label: 'Full Name', value: name),
                  const Divider(height: 1),
                  _InfoRow(label: 'Email', value: email),
                  const Divider(height: 1),
                  _InfoRow(label: 'Role', value: role),
                  const Divider(height: 1),
                  _InfoRow(label: 'Status', value: status),
                  const Divider(height: 1),
                  _InfoRow(label: 'App Version', value: _appVersion),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Change Password
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_outline, color: AppColors.primary),
            label: const Text(
              'Change Password',
              style: TextStyle(color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.primary),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => context.push('/change-password'),
          ),
          const SizedBox(height: 12),

          // Logout
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: _logout,
          ),
          const SizedBox(height: 16),

          // Version at bottom
          Center(
            child: Text(
              _appVersion,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── BADGE ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── INFO ROW ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
