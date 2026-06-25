import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';

class UserCard extends ConsumerWidget {
  final AdminUserModel user;
  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.infoLight,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(user.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.status,
                style: TextStyle(
                  color: _statusColor(user.status),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Action button
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => _showStatusOptions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'suspended':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  void _showStatusOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change account status:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // Active
            if (user.status != 'active')
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                title: const Text('Set Active'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(context, ref, 'active');
                },
              ),

            // Suspend
            if (user.status != 'suspended')
              ListTile(
                leading: const Icon(
                  Icons.block_outlined,
                  color: AppColors.danger,
                ),
                title: const Text('Suspend Account'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(context, ref, 'suspended');
                },
              ),

            // Inactive
            if (user.status != 'inactive')
              ListTile(
                leading: const Icon(
                  Icons.pause_circle_outline,
                  color: AppColors.textMuted,
                ),
                title: const Text('Set Inactive'),
                onTap: () async {
                  Navigator.pop(context);
                  await _updateStatus(context, ref, 'inactive');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    try {
      final service = ref.read(adminServiceProvider);
      await service.updateUserStatus(user.id, status);

      // Refresh both lists since we don't know if
      // this is a teacher or student card
      ref.invalidate(adminTeachersProvider);
      ref.invalidate(adminStudentsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account ${status} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
