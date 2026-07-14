import 'package:client/features/admin/models/admin_models.dart';
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

  void _showAddStudent(BuildContext context, WidgetRef ref) async {
    final service = ref.read(adminServiceProvider);

    // Show loading while fetching programs
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final programs = await service.getPrograms();
      if (context.mounted) Navigator.pop(context); // dismiss loading

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

      // Local state for the dialog
      String? selectedProgramId;
      String? selectedBatchId;
      List<BatchModel> batches = [];
      bool loadingBatches = false;
      bool isSubmitting = false;

      final nameController = TextEditingController();
      final emailController = TextEditingController();
      final rollController = TextEditingController();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Add Student'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    // Roll Number
                    TextField(
                      controller: rollController,
                      decoration: const InputDecoration(
                        labelText: 'Roll Number',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Program dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Program',
                        isDense: true,
                      ),
                      isExpanded: true,
                      value: selectedProgramId,
                      items: programs
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name} (${p.type})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) async {
                        if (val == null) return;
                        setState(() {
                          selectedProgramId = val;
                          selectedBatchId = null;
                          batches = [];
                          loadingBatches = true;
                        });

                        // Fetch batches for the selected program
                        try {
                          final result = await service.getBatchesByProgram(val);
                          setState(() {
                            batches = result;
                            loadingBatches = false;
                          });
                        } catch (_) {
                          setState(() => loadingBatches = false);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Batch dropdown — only shows after program is selected
                    if (loadingBatches)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    else if (selectedProgramId != null)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Batch',
                          isDense: true,
                        ),
                        isExpanded: true,
                        value: selectedBatchId,
                        items: batches.isEmpty
                            ? [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'No batches found for this program',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ]
                            : batches
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b.id,
                                      child: Text(
                                        b.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        onChanged: batches.isEmpty
                            ? null
                            : (val) => setState(() => selectedBatchId = val),
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
                  // Only enable when all required fields are filled AND not currently submitting
                  onPressed:
                      isSubmitting ||
                          nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          rollController.text.isEmpty ||
                          selectedProgramId == null ||
                          selectedBatchId == null
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          try {
                            await service.createStudent(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              rollNumber: rollController.text.trim(),
                              programId: selectedProgramId!,
                              batchId: selectedBatchId!,
                            );
                            ref.invalidate(adminStudentsProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Student created successfully'),
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
