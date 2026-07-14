import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/user_card.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AdminTeachersSection extends ConsumerWidget {
  const AdminTeachersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(adminTeachersProvider);

    return Scaffold(
      body: teachers.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No teachers yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminTeachersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => UserCard(user: list[index]),
                ),
              ),
        loading: () => const LoadingWidget(message: 'Loading teachers...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminTeachersProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddTeacher(context, ref),
      ),
    );
  }

  void _showAddTeacher(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final deptController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Teacher'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: deptController,
                decoration: const InputDecoration(labelText: 'Department'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  isSubmitting ||
                      nameController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      deptController.text.isEmpty
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      try {
                        final service = ref.read(adminServiceProvider);
                        await service.createTeacher(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          department: deptController.text.trim(),
                        );
                        ref.invalidate(adminTeachersProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teacher created successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
