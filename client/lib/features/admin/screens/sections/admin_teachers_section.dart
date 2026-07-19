import 'package:client/features/admin/models/admin_models.dart';
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
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No teachers yet'));
          }

          final assigned = list.where((t) => t.activeCount > 0).toList();
          final unassigned = list.where((t) => t.activeCount == 0).toList();

          // Group assigned teachers by program — a teacher can appear
          // under more than one program if they teach in both, which
          // accurately reflects their real course load.
          final Map<String, List<AdminUserModel>> byProgram = {};
          for (final teacher in assigned) {
            final programNames = teacher.courses
                .map((c) => c.programName)
                .toSet();
            for (final programName in programNames) {
              byProgram.putIfAbsent(programName, () => []).add(teacher);
            }
          }
          final programNames = byProgram.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminTeachersProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (assigned.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Assigned',
                    count: assigned.length,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  ...programNames.map((programName) {
                    final teachersInProgram = byProgram[programName]!;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.infoLight,
                          child: Text(
                            programName.isNotEmpty
                                ? programName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          programName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${teachersInProgram.length} teacher${teachersInProgram.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        children: teachersInProgram.map((teacher) {
                          final coursesInThisProgram = teacher.courses
                              .where((c) => c.programName == programName)
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UserCard(user: teacher),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    bottom: 4,
                                  ),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: coursesInThisProgram.map((c) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.infoLight,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${c.subjectName} · Term ${c.term}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                if (unassigned.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Unassigned',
                    count: unassigned.length,
                    color: AppColors.textMuted,
                    subtitle: 'No active course load',
                  ),
                  ...unassigned.map((t) => UserCard(user: t)),
                ],
              ],
            ),
          );
        },
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String? subtitle;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
