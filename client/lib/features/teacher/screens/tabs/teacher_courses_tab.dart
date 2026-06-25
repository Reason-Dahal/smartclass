import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/upload_service.dart';
import '../../data/teacher_service.dart';
import '../../models/teacher_models.dart';
import '../../providers/teacher_providers.dart';
import '../../widgets/course_detail_card.dart';
import '../../widgets/action_tile.dart';
import '../../widgets/status_button.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class TeacherCoursesTab extends ConsumerWidget {
  const TeacherCoursesTab({super.key});

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
            return CourseDetailCard(
              course: course,
              onTap: () => _showCourseActions(context, ref, course),
            );
          },
        );
      },
      loading: () => const LoadingWidget(message: 'Loading courses...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(teacherCoursesProvider),
      ),
    );
  }

  void _showCourseActions(
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
            ActionTile(
              icon: Icons.calendar_today,
              label: 'Take attendance',
              onTap: () {
                Navigator.pop(context);
                _showTakeAttendance(context, ref, course);
              },
            ),
            ActionTile(
              icon: Icons.assignment_add,
              label: 'Create assignment',
              onTap: () {
                Navigator.pop(context);
                _showCreateAssignment(context, ref, course);
              },
            ),
            ActionTile(
              icon: Icons.upload_file,
              label: 'Upload note',
              onTap: () {
                Navigator.pop(context);
                _showUploadNote(context, ref, course);
              },
            ),
            ActionTile(
              icon: course.evaluationEnabled
                  ? Icons.toggle_on
                  : Icons.toggle_off,
              label: course.evaluationEnabled
                  ? 'Disable evaluation indicator'
                  : 'Enable evaluation indicator',
              color: course.evaluationEnabled
                  ? AppColors.success
                  : AppColors.textSecondary,
              onTap: () async {
                Navigator.pop(context);
                final service = ref.read(teacherServiceProvider);
                await service.toggleEvaluation(
                  course.id,
                  !course.evaluationEnabled,
                );
                ref.invalidate(teacherCoursesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        course.evaluationEnabled
                            ? 'Evaluation disabled'
                            : 'Evaluation enabled',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTakeAttendance(
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

      final attendanceMap = <String, String>{};
      for (final s in students) {
        attendanceMap[s['studentId']] = 'present';
      }

      final dateController = TextEditingController(
        text: DateTime.now().toIso8601String().split('T')[0],
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text('Attendance — ${course.subjectName}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            for (final s in students) {
                              attendanceMap[s['studentId']] = 'present';
                            }
                          });
                        },
                        child: const Text('Mark all present'),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (ctx, index) {
                          final student = students[index];
                          final studentId = student['studentId'] as String;
                          final status = attendanceMap[studentId] ?? 'present';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.infoLight,
                                  child: Text(
                                    (student['name'] as String)[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
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
                                        student['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
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
                                ),
                                Row(
                                  children: [
                                    StatusButton(
                                      label: 'P',
                                      selected: status == 'present',
                                      selectedColor: AppColors.present,
                                      onTap: () => setState(
                                        () => attendanceMap[studentId] =
                                            'present',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    StatusButton(
                                      label: 'A',
                                      selected: status == 'absent',
                                      selectedColor: AppColors.absent,
                                      onTap: () => setState(
                                        () =>
                                            attendanceMap[studentId] = 'absent',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    StatusButton(
                                      label: 'L',
                                      selected: status == 'late',
                                      selectedColor: AppColors.late,
                                      onTap: () => setState(
                                        () => attendanceMap[studentId] = 'late',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                    final records = attendanceMap.entries
                        .map((e) => {'studentId': e.key, 'status': e.value})
                        .toList();
                    try {
                      await service.takeAttendance(
                        course.id,
                        dateController.text,
                        records,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attendance saved successfully'),
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
                  child: const Text('Save attendance'),
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

  void _showCreateAssignment(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('New assignment — ${course.subjectName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    dueDate == null
                        ? 'No due date selected'
                        : 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => dueDate = picked);
                      }
                    },
                    child: const Text('Pick date'),
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
              onPressed: () async {
                if (titleController.text.isEmpty || dueDate == null) return;
                final service = ref.read(teacherServiceProvider);
                await service.createAssignment(
                  course.id,
                  title: titleController.text,
                  description: descController.text,
                  dueDate: dueDate!.toIso8601String(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment created')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadNote(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
  ) {
    final titleController = TextEditingController();
    String? selectedFileUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Upload note — ${course.subjectName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              if (selectedFileUrl == null)
                ElevatedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          setState(() => isUploading = true);
                          try {
                            final uploadService = UploadService();
                            final url = await uploadService.pickAndUploadFile(
                              ApiConstants.uploadNote,
                            );
                            setState(() {
                              selectedFileUrl = url;
                              isUploading = false;
                            });
                          } catch (e) {
                            setState(() => isUploading = false);
                          }
                        },
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file, size: 16),
                  label: Text(isUploading ? 'Uploading...' : 'Pick file'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'File uploaded successfully',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => selectedFileUrl = null),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedFileUrl == null || titleController.text.isEmpty
                  ? null
                  : () async {
                      final service = ref.read(teacherServiceProvider);
                      await service.uploadNote(
                        course.id,
                        title: titleController.text,
                        fileUrl: selectedFileUrl!,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note uploaded')),
                        );
                      }
                    },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
