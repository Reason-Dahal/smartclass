import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/action_card.dart';
import '../../widgets/stat_badge.dart';
import '../../widgets/report_card.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AdminHomeSection extends ConsumerWidget {
  final String userName;
  final Function(int) onNavigate;

  const AdminHomeSection({
    super.key,
    required this.userName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);
    final teachers = ref.watch(adminTeachersProvider);
    final students = ref.watch(adminStudentsProvider);
    final programs = ref.watch(adminProgramsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminReportsProvider);
        ref.invalidate(adminTeachersProvider);
        ref.invalidate(adminStudentsProvider);
        ref.invalidate(adminProgramsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                StatBadge(
                  label: 'Students',
                  value:
                      students.whenOrNull(data: (l) => '${l.length}') ?? '...',
                ),
                const SizedBox(width: 10),
                StatBadge(
                  label: 'Teachers',
                  value:
                      teachers.whenOrNull(data: (l) => '${l.length}') ?? '...',
                ),
                const SizedBox(width: 10),
                StatBadge(
                  label: 'Programs',
                  value:
                      programs.whenOrNull(data: (l) => '${l.length}') ?? '...',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions grid
            const Text(
              'Quick actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                ActionCard(
                  icon: Icons.person_add_outlined,
                  label: 'Add Teacher',
                  color: AppColors.primary,
                  onTap: () => onNavigate(1),
                ),
                ActionCard(
                  icon: Icons.school_outlined,
                  label: 'Add Student',
                  color: AppColors.info,
                  onTap: () => onNavigate(2),
                ),
                ActionCard(
                  icon: Icons.account_balance_outlined,
                  label: 'Programs',
                  color: AppColors.success,
                  onTap: () => onNavigate(3),
                ),
                ActionCard(
                  icon: Icons.bar_chart_outlined,
                  label: 'Reports',
                  color: AppColors.warning,
                  onTap: () => onNavigate(4),
                ),
                ActionCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Final Results',
                  color: AppColors.danger,
                  onTap: () => _showUploadFinalResults(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System overview
            const Text(
              'System overview',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            reports.when(
              data: (report) => ReportCard(
                title: 'At a glance',
                children: [
                  ReportRow(
                    label: 'Overall attendance',
                    value: report.overallAttendanceRate,
                  ),
                  const Divider(),
                  ReportRow(
                    label: 'Total assignments',
                    value: '${report.totalAssignments}',
                  ),
                  const Divider(),
                  ReportRow(
                    label: 'Submission rate',
                    value: report.submissionRate,
                  ),
                ],
              ),
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadFinalResults(BuildContext context, WidgetRef ref) async {
    final service = ref.read(adminServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final studentsAsync = await ref.read(adminStudentsProvider.future);
      if (context.mounted) Navigator.pop(context);

      if (studentsAsync.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No students found')));
        }
        return;
      }

      String? selectedStudentId;
      String selectedStatus = 'pass';
      final termController = TextEditingController(text: '1');
      final dateController = TextEditingController(
        text: DateTime.now().toIso8601String().split('T')[0],
      );
      final courseIdController = TextEditingController();
      String courseStatus = 'pass';

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Upload Final Result'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dean\'s Office published result',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Student',
                          isDense: true,
                        ),
                        value: selectedStudentId,
                        isExpanded: true,
                        items: studentsAsync
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedStudentId = val),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: termController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Term',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          labelText: 'Published Date (YYYY-MM-DD)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Overall Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'pass',
                            groupValue: selectedStatus,
                            onChanged: (val) =>
                                setState(() => selectedStatus = val!),
                            activeColor: AppColors.success,
                          ),
                          const Text('Pass'),
                          const SizedBox(width: 16),
                          Radio<String>(
                            value: 'fail',
                            groupValue: selectedStatus,
                            onChanged: (val) =>
                                setState(() => selectedStatus = val!),
                            activeColor: AppColors.danger,
                          ),
                          const Text('Fail'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: courseIdController,
                        decoration: const InputDecoration(
                          labelText: 'Course ID (optional)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'pass',
                            groupValue: courseStatus,
                            onChanged: (val) =>
                                setState(() => courseStatus = val!),
                            activeColor: AppColors.success,
                          ),
                          const Text('Pass'),
                          const SizedBox(width: 16),
                          Radio<String>(
                            value: 'fail',
                            groupValue: courseStatus,
                            onChanged: (val) =>
                                setState(() => courseStatus = val!),
                            activeColor: AppColors.danger,
                          ),
                          const Text('Fail'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedStudentId == null
                      ? null
                      : () async {
                          try {
                            await service.uploadFinalResults(
                              studentId: selectedStudentId!,
                              term: int.tryParse(termController.text) ?? 1,
                              overallStatus: selectedStatus,
                              publishedDate: dateController.text,
                              courseResults: courseIdController.text.isEmpty
                                  ? []
                                  : [
                                      {
                                        'courseId': courseIdController.text,
                                        'status': courseStatus,
                                      },
                                    ],
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Final result uploaded'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: const Text('Upload'),
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
