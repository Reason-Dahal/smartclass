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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            if (user.department != null)
              Text(
                user.department!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            if (user.rollNumber != null)
              Text(
                'Roll: ${user.rollNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        isThreeLine: user.department != null || user.rollNumber != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => _showOptions(context, ref),
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

  void _showOptions(BuildContext context, WidgetRef ref) {
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

            // Edit
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, ref);
              },
            ),

            // Status options
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

            // Deactivate
            if (user.status != 'inactive')
              ListTile(
                leading: const Icon(
                  Icons.person_off_outlined,
                  color: AppColors.textMuted,
                ),
                title: const Text('Deactivate'),
                subtitle: const Text(
                  'Soft delete — account is preserved',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deactivate(context, ref);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final departmentController = TextEditingController(
      text: user.department ?? '',
    );
    final rollController = TextEditingController(text: user.rollNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${user.role == 'teacher' ? 'Teacher' : 'Student'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  isDense: true,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              // Teacher-specific field
              if (user.role == 'teacher')
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    isDense: true,
                  ),
                ),
              // Student-specific field
              if (user.role == 'student')
                TextField(
                  controller: rollController,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number',
                    isDense: true,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final service = ref.read(adminServiceProvider);
                if (user.role == 'teacher') {
                  await service.editTeacher(
                    profileId: user.profileId,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    department: departmentController.text.trim(),
                  );
                } else {
                  await service.editStudent(
                    profileId: user.profileId,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    rollNumber: rollController.text.trim(),
                  );
                }
                ref.invalidate(adminTeachersProvider);
                ref.invalidate(adminStudentsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Updated successfully'),
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
            },
            child: const Text('Save'),
          ),
        ],
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
      ref.invalidate(adminTeachersProvider);
      ref.invalidate(adminStudentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account $status successfully'),
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

  Future<void> _deactivate(BuildContext context, WidgetRef ref) async {
    // Confirm before deactivating
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: Text(
          'Deactivate ${user.name}? They will not be able to log in. '
          'This can be reversed by setting the account to Active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final service = ref.read(adminServiceProvider);
      if (user.role == 'teacher') {
        await service.deactivateTeacher(user.profileId);
      } else {
        await service.deactivateStudent(user.profileId);
      }
      ref.invalidate(adminTeachersProvider);
      ref.invalidate(adminStudentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deactivated'),
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
