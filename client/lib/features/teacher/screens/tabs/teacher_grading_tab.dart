import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/teacher_models.dart';
import '../../providers/teacher_providers.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class TeacherGradingTab extends ConsumerWidget {
  const TeacherGradingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(teacherCoursesProvider);

    return courses.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'No courses assigned yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final course = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  course.subjectName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${course.programName} · Term ${course.term}'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                onTap: () => _showGradingOptions(context, ref, course),
              ),
            );
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
    );
  }

  // ─── GRADING OPTIONS ─────────────────────────────────────────

  void _showGradingOptions(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
  ) {
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
              course.subjectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.primary,
              ),
              title: const Text('View Submissions'),
              subtitle: const Text(
                'See and grade student assignment submissions',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSubmissions(context, ref, course);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.grade_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Enter Marksheets'),
              subtitle: const Text(
                'Enter internal exam marks and evaluation scores',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showMarksheetEntry(context, ref, course);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── SUBMISSIONS ─────────────────────────────────────────────

  void _showSubmissions(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
  ) async {
    final service = ref.read(teacherServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final assignments = await service.getCourseAssignments(course.id);
      if (context.mounted) Navigator.pop(context);

      if (assignments.isEmpty) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('No Assignments'),
              content: const Text(
                'No assignments created for this course yet.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Assignments — ${course.subjectName}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: assignments.length,
                itemBuilder: (ctx, index) {
                  final assignment = assignments[index];
                  final dueDate = DateTime.tryParse(
                    assignment['dueDate'] ?? '',
                  );
                  return ListTile(
                    leading: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      assignment['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: dueDate != null
                        ? Text(
                            'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAssignmentSubmissions(
                        context,
                        ref,
                        assignment['_id'] ?? '',
                        assignment['title'] ?? '',
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
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

  void _showAssignmentSubmissions(
    BuildContext context,
    WidgetRef ref,
    String assignmentId,
    String assignmentTitle,
  ) async {
    final service = ref.read(teacherServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final submissions = await service.getSubmissions(assignmentId);
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(assignmentTitle),
            content: SizedBox(
              width: double.maxFinite,
              child: submissions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No submissions yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: submissions.length,
                      itemBuilder: (ctx, index) {
                        final sub = submissions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.infoLight,
                                      child: Text(
                                        sub.studentName.isNotEmpty
                                            ? sub.studentName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            sub.rollNumber,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sub.status == 'on-time'
                                            ? AppColors.successLight
                                            : AppColors.warningLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        sub.status,
                                        style: TextStyle(
                                          color: sub.status == 'on-time'
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Grade display or entry
                                if (sub.grade != null) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.grade,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Grade: ${sub.grade}',
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (sub.feedback != null) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            sub.feedback!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Re-grade button
                                  TextButton(
                                    onPressed: () => _showGradeDialog(
                                      ctx,
                                      ref,
                                      sub.id,
                                      sub.grade,
                                      sub.feedback,
                                    ),
                                    child: const Text('Update grade'),
                                  ),
                                ] else
                                  ElevatedButton.icon(
                                    onPressed: () => _showGradeDialog(
                                      ctx,
                                      ref,
                                      sub.id,
                                      null,
                                      null,
                                    ),
                                    icon: const Icon(Icons.grade, size: 14),
                                    label: const Text('Grade'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(80, 30),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
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

  void _showGradeDialog(
    BuildContext context,
    WidgetRef ref,
    String submissionId,
    double? currentGrade,
    String? currentFeedback,
  ) {
    final gradeController = TextEditingController(
      text: currentGrade?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: currentFeedback ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grade Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback (optional)',
                isDense: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final grade = double.tryParse(gradeController.text);
              if (grade == null) return;
              try {
                final service = ref.read(teacherServiceProvider);
                await service.gradeSubmission(
                  submissionId,
                  grade: grade,
                  feedback: feedbackController.text.isEmpty
                      ? null
                      : feedbackController.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Submission graded'),
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
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  // ─── MARKSHEETS (kept from before) ───────────────────────────

  void _showMarksheetEntry(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
  ) async {
    final service = ref.read(teacherServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final students = await service.getCourseStudents(course.id);
      if (context.mounted) Navigator.pop(context);

      if (students.isEmpty) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('No students'),
              content: const Text(
                'No students are enrolled in this course yet.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final marksMap = <String, Map<String, TextEditingController>>{};
      for (final s in students) {
        marksMap[s['studentId']] = {
          'internalMarks': TextEditingController(),
          'totalMarks': TextEditingController(text: '100'),
          'evalScore': TextEditingController(),
          'term': TextEditingController(text: '1'),
        };
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Marksheet — ${course.subjectName}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter marks for each student:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (ctx, index) {
                        final student = students[index];
                        final studentId = student['studentId'] as String;
                        final controllers = marksMap[studentId]!;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.infoLight,
                                      child: Text(
                                        (student['name'] as String)[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          student['rollNumber'] as String,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            controllers['internalMarks'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Marks',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: controllers['totalMarks'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Out of',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: controllers['evalScore'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Eval (0-100)',
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: controllers['term'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Term',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                    for (final student in students) {
                      final studentId = student['studentId'] as String;
                      final controllers = marksMap[studentId]!;
                      if (controllers['internalMarks']!.text.isEmpty) continue;
                      await service.uploadMarksheet(
                        course.id,
                        studentId: studentId,
                        term: int.tryParse(controllers['term']!.text) ?? 1,
                        internalExamMarks:
                            double.tryParse(
                              controllers['internalMarks']!.text,
                            ) ??
                            0,
                        internalExamTotalMarks:
                            double.tryParse(controllers['totalMarks']!.text) ??
                            100,
                        teacherEvaluationScore:
                            double.tryParse(controllers['evalScore']!.text) ??
                            0,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marksheets saved successfully'),
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
                child: const Text('Save marks'),
              ),
            ],
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
