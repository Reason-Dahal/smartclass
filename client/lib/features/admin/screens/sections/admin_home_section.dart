import 'package:client/features/admin/screens/admin_attendance_override_screen.dart';
import 'package:client/features/admin/screens/admin_marksheet_override_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/action_card.dart';
import '../../widgets/stat_badge.dart';
import '../../widgets/report_card.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';
import 'package:file_picker/file_picker.dart';

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
            const Text(
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
                  icon: Icons.menu_book_outlined,
                  label: 'Courses',
                  color: AppColors.primaryDark,
                  onTap: () => onNavigate(5),
                ),

                ActionCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Final Results',
                  color: AppColors.danger,
                  onTap: () => _showUploadFinalResults(context, ref),
                ),

                ActionCard(
                  icon: Icons.tune_outlined,
                  label: 'Eval Config',
                  color: AppColors.primaryDark,
                  onTap: () => _showEvaluationConfig(context, ref),
                ),
                ActionCard(
                  icon: Icons.edit_note_outlined,
                  label: 'Override Data',
                  color: AppColors.textSecondary,
                  onTap: () => _showOverrideOptions(context, ref),
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

    // Fetch programs first
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

      String? selectedProgramId;
      String? selectedFileName;
      List<int>? selectedFileBytes;
      String? selectedFileType;
      final termController = TextEditingController(text: '1');
      bool isUploading = false;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Publish Final Results'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload the Dean's Office result file (PDF or DOCX) "
                      "for a program and term. All students in the program "
                      "will see this file.",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                      onChanged: isUploading
                          ? null
                          : (val) => setState(() => selectedProgramId = val),
                    ),
                    const SizedBox(height: 12),

                    // Term
                    TextField(
                      controller: termController,
                      enabled: !isUploading,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Term / Year Number',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // File picker
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        selectedFileName ?? 'Select Result File (PDF or DOCX)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: isUploading
                          ? null
                          : () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'docx', 'doc'],
                                    withData: true,
                                  );
                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.first;
                                final mime = file.name.endsWith('.pdf')
                                    ? 'pdf'
                                    : 'docx';
                                setState(() {
                                  selectedFileName = file.name;
                                  selectedFileBytes = file.bytes;
                                  selectedFileType = mime;
                                });
                              }
                            },
                    ),

                    // Show selected file name
                    if (selectedFileName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                selectedFileName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      selectedProgramId == null ||
                          selectedFileBytes == null ||
                          isUploading
                      ? null
                      : () async {
                          setState(() => isUploading = true);
                          try {
                            await service.uploadFinalResults(
                              programId: selectedProgramId!,
                              term: int.tryParse(termController.text) ?? 1,
                              fileBytes: selectedFileBytes!,
                              fileName: selectedFileName!,
                              fileType: selectedFileType!,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Result published successfully',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isUploading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publish'),
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

  void _showEvaluationConfig(BuildContext context, WidgetRef ref) async {
    final service = ref.read(adminServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final config = await ref.read(evaluationConfigProvider.future);
      if (context.mounted) Navigator.pop(context);

      // Initialize sliders from current config
      int attendance = (config['attendanceWeight'] ?? 25).toInt();
      int internalExam = (config['internalExamWeight'] ?? 25).toInt();
      int assignment = (config['assignmentWeight'] ?? 25).toInt();
      int teacherEval = (config['teacherEvaluationWeight'] ?? 25).toInt();
      bool isSubmitting = false;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) {
              final total =
                  attendance + internalExam + assignment + teacherEval;
              final isValid = total == 100;

              return AlertDialog(
                title: const Text('Evaluation Weights'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Weights must add up to 100',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Total indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isValid
                              ? AppColors.successLight
                              : AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total: $total / 100',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isValid
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Attendance
                      _WeightSlider(
                        label: 'Attendance',
                        value: attendance,
                        enabled: !isSubmitting,
                        onChanged: (val) => setState(() => attendance = val),
                      ),

                      // Internal Exam
                      _WeightSlider(
                        label: 'Internal Exam',
                        value: internalExam,
                        enabled: !isSubmitting,
                        onChanged: (val) => setState(() => internalExam = val),
                      ),

                      // Assignments
                      _WeightSlider(
                        label: 'Assignments',
                        value: assignment,
                        enabled: !isSubmitting,
                        onChanged: (val) => setState(() => assignment = val),
                      ),

                      // Teacher Evaluation
                      _WeightSlider(
                        label: 'Teacher Eval',
                        value: teacherEval,
                        enabled: !isSubmitting,
                        onChanged: (val) => setState(() => teacherEval = val),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: !isValid || isSubmitting
                        ? null
                        : () async {
                            setState(() => isSubmitting = true);
                            try {
                              await service.updateEvaluationConfig(
                                attendanceWeight: attendance,
                                internalExamWeight: internalExam,
                                assignmentWeight: assignment,
                                teacherEvaluationWeight: teacherEval,
                              );
                              ref.invalidate(evaluationConfigProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Evaluation config updated'),
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
                        : const Text('Save'),
                  ),
                ],
              );
            },
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

  void _showOverrideOptions(BuildContext context, WidgetRef ref) {
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
            const Text(
              'Override Academic Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a course, then browse and edit records directly',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Override Attendance'),
              subtitle: const Text(
                'Change a student\'s attendance status',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminAttendanceOverrideScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.grade_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Override Marksheet'),
              subtitle: const Text(
                'Correct internal exam marks or eval score',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminMarksheetOverrideScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const _WeightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Container(
              width: 40,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$value%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: AppColors.primary,
          onChanged: enabled ? (val) => onChanged(val.toInt()) : null,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
