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

  void _showAddTeacher(BuildContext context, WidgetRef ref) async {
    final service = ref.read(adminServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final programs = await service.getPrograms();
      if (context.mounted) Navigator.pop(context);

      if (programs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No programs found. Create a program first.'),
            ),
          );
        }
        return;
      }

      final nameController = TextEditingController();
      final emailController = TextEditingController();
      String? selectedProgramId;
      bool isSubmitting = false;

      if (context.mounted) {
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
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (_) => setState(() {}),
                  ),
                  TextField(
                    controller: emailController,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Department (Program)',
                      isDense: true,
                    ),
                    isExpanded: true,
                    value: selectedProgramId,
                    items: programs
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.name,
                            child: Text(
                              '${p.name} (${p.type})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: isSubmitting
                        ? null
                        : (val) => setState(() => selectedProgramId = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isSubmitting ||
                          nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          selectedProgramId == null
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          try {
                            await service.createTeacher(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              department: selectedProgramId!,
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
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
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
