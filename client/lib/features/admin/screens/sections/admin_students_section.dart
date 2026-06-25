import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/user_card.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AdminStudentsSection extends ConsumerWidget {
  const AdminStudentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(adminStudentsProvider);

    return Scaffold(
      body: students.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No students yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminStudentsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => UserCard(user: list[index]),
                ),
              ),
        loading: () => const LoadingWidget(message: 'Loading students...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminStudentsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddStudent(context, ref),
      ),
    );
  }

  void _showAddStudent(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final rollController = TextEditingController();
    final programIdController = TextEditingController();
    final batchIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: rollController,
                decoration: const InputDecoration(labelText: 'Roll Number'),
              ),
              TextField(
                controller: programIdController,
                decoration: const InputDecoration(labelText: 'Program ID'),
              ),
              TextField(
                controller: batchIdController,
                decoration: const InputDecoration(labelText: 'Batch ID'),
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
                await service.createStudent(
                  name: nameController.text,
                  email: emailController.text,
                  rollNumber: rollController.text,
                  programId: programIdController.text,
                  batchId: batchIdController.text,
                );
                ref.invalidate(adminStudentsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student created successfully'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
