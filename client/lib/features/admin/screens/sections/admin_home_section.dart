import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
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
                ActionCard(
                  icon: Icons.menu_book_outlined,
                  label: 'Create Course',
                  color: AppColors.primaryLight,
                  onTap: () => _showCreateCourse(context, ref),
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
                                value: s.profileId,
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

  void _showCreateCourse(BuildContext context, WidgetRef ref) async {
    final service = ref.read(adminServiceProvider);

    // Fetch programs and teachers first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final programs = await ref.read(adminProgramsProvider.future);
      final teachers = await ref.read(adminTeachersProvider.future);
      if (context.mounted) Navigator.pop(context);

      if (programs.isEmpty || teachers.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You need at least one program and one teacher first',
              ),
            ),
          );
        }
        return;
      }

      String? selectedProgramId;
      String? selectedTeacherId;
      int? selectedTotalTerms;
      final subjectController = TextEditingController();
      final termController = TextEditingController(text: '1');
      bool isElective = false;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Create Course'),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        onChanged: (val) {
                          if (val != null) {
                            final program = programs.firstWhere(
                              (p) => p.id == val,
                            );
                            setState(() {
                              selectedProgramId = val;
                              selectedTotalTerms = program.totalTerms;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Teacher dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Teacher',
                          isDense: true,
                        ),
                        isExpanded: true,
                        value: selectedTeacherId,
                        items: teachers
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.profileId,
                                child: Text(
                                  t.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedTeacherId = val),
                      ),
                      const SizedBox(height: 12),

                      // Subject name
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Term
                      TextField(
                        controller: termController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: selectedTotalTerms != null
                              ? 'Term (1–$selectedTotalTerms)'
                              : 'Term',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Elective toggle
                      Row(
                        children: [
                          const Text(
                            'Elective course',
                            style: TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          Switch(
                            value: isElective,
                            onChanged: (val) =>
                                setState(() => isElective = val),
                            activeColor: AppColors.primary,
                          ),
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
                  onPressed:
                      selectedProgramId == null ||
                          selectedTeacherId == null ||
                          subjectController.text.isEmpty
                      ? null
                      : () async {
                          try {
                            await service.createCourse(
                              programId: selectedProgramId!,
                              teacherId: selectedTeacherId!,
                              subjectName: subjectController.text,
                              term: int.tryParse(termController.text) ?? 1,
                              isElective: isElective,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Course created successfully'),
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
                  child: const Text('Create'),
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
                        onChanged: (val) => setState(() => attendance = val),
                      ),

                      // Internal Exam
                      _WeightSlider(
                        label: 'Internal Exam',
                        value: internalExam,
                        onChanged: (val) => setState(() => internalExam = val),
                      ),

                      // Assignments
                      _WeightSlider(
                        label: 'Assignments',
                        value: assignment,
                        onChanged: (val) => setState(() => assignment = val),
                      ),

                      // Teacher Evaluation
                      _WeightSlider(
                        label: 'Teacher Eval',
                        value: teacherEval,
                        onChanged: (val) => setState(() => teacherEval = val),
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
                    onPressed: !isValid
                        ? null
                        : () async {
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
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                    child: const Text('Save'),
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
              'Requires the document ID from the database',
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
                _showOverrideAttendance(context, ref);
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
                _showOverrideMarksheet(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOverrideAttendance(BuildContext context, WidgetRef ref) {
    final idController = TextEditingController();
    String selectedStatus = 'present';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Override Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Attendance Record ID',
                  hintText: 'Paste MongoDB _id here',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New Status:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusOption(
                    label: 'Present',
                    value: 'present',
                    selected: selectedStatus,
                    color: AppColors.present,
                    onTap: () => setState(() => selectedStatus = 'present'),
                  ),
                  const SizedBox(width: 8),
                  _StatusOption(
                    label: 'Absent',
                    value: 'absent',
                    selected: selectedStatus,
                    color: AppColors.absent,
                    onTap: () => setState(() => selectedStatus = 'absent'),
                  ),
                  const SizedBox(width: 8),
                  _StatusOption(
                    label: 'Late',
                    value: 'late',
                    selected: selectedStatus,
                    color: AppColors.late,
                    onTap: () => setState(() => selectedStatus = 'late'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: idController.text.isEmpty
                  ? null
                  : () async {
                      try {
                        final service = ref.read(adminServiceProvider);
                        await service.overrideAttendance(
                          attendanceId: idController.text.trim(),
                          status: selectedStatus,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Attendance overridden successfully',
                              ),
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
              child: const Text('Override'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOverrideMarksheet(BuildContext context, WidgetRef ref) {
    final idController = TextEditingController();
    final internalMarksController = TextEditingController();
    final totalMarksController = TextEditingController(text: '100');
    final evalScoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Override Marksheet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Marksheet Record ID',
                  hintText: 'Paste MongoDB _id here',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: internalMarksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Internal Exam Marks',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalMarksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Marks',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: evalScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Teacher Eval Score (0-100)',
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
              if (idController.text.isEmpty ||
                  internalMarksController.text.isEmpty)
                return;
              try {
                final service = ref.read(adminServiceProvider);
                await service.overrideMarksheet(
                  marksheetId: idController.text.trim(),
                  internalExamMarks:
                      double.tryParse(internalMarksController.text) ?? 0,
                  internalExamTotalMarks:
                      double.tryParse(totalMarksController.text) ?? 100,
                  teacherEvaluationScore:
                      double.tryParse(evalScoreController.text) ?? 0,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Marksheet overridden successfully'),
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
            child: const Text('Override'),
          ),
        ],
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _WeightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
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
          onChanged: (val) => onChanged(val.toInt()),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
