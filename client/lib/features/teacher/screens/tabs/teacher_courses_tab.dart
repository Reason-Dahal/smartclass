import 'package:client/shared/screens/marksheet_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/upload_service.dart';
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

        // Group by program → term → courses
        final Map<String, Map<int, List<TeacherCourseModel>>> grouped = {};
        for (final course in list) {
          grouped.putIfAbsent(course.programName, () => {});
          grouped[course.programName]!.putIfAbsent(course.term, () => []);
          grouped[course.programName]![course.term]!.add(course);
        }

        final programs = grouped.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: programs.length,
          itemBuilder: (context, programIndex) {
            final programName = programs[programIndex];
            final termMap = grouped[programName]!;
            final terms = termMap.keys.toList()..sort();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: CircleAvatar(
                  backgroundColor: AppColors.infoLight,
                  child: Text(
                    programName.isNotEmpty ? programName[0].toUpperCase() : 'P',
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
                  '${terms.length} term${terms.length > 1 ? 's' : ''} · '
                  '${termMap.values.fold(0, (s, l) => s + l.length)} course${termMap.values.fold(0, (s, l) => s + l.length) > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                children: terms.map((term) {
                  final termCourses = termMap[term]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Term header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Term $term',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Courses under this term
                      ...termCourses.map(
                        (course) => Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: CourseDetailCard(
                            course: course,
                            onTap: () =>
                                _showCourseActions(context, ref, course),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
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
              icon: Icons.edit_calendar_outlined,
              label: 'Edit attendance',
              onTap: () {
                Navigator.pop(context);
                _showEditAttendance(context, ref, course);
              },
            ),
            ActionTile(
              icon: Icons.edit_note_outlined,
              label: 'Edit marksheet',
              onTap: () {
                Navigator.pop(context);
                _showEditMarksheet(context, ref, course);
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
    bool showTitleError = false;

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
                decoration: InputDecoration(
                  labelText: 'Title',
                  errorText: showTitleError ? 'Title cannot be empty' : null,
                ),
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
                if (titleController.text.trim().isEmpty) {
                  setState(() => showTitleError = true);
                  return;
                }
                if (dueDate == null) return;

                final service = ref.read(teacherServiceProvider);
                await service.createAssignment(
                  course.id,
                  title: titleController.text.trim(),
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
    bool showTitleError = false;

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
                decoration: InputDecoration(
                  labelText: 'Title',
                  errorText: showTitleError ? 'Title cannot be empty' : null,
                ),
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
                            final result = await uploadService
                                .pickAndUploadFile(ApiConstants.uploadNote);
                            setState(() {
                              selectedFileUrl =
                                  result?['fileUrl']; // ← extract URL
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
              onPressed: selectedFileUrl == null
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        setState(() => showTitleError = true);
                        return;
                      }

                      try {
                        final service = ref.read(teacherServiceProvider);
                        await service.uploadNote(
                          course.id,
                          title: titleController.text.trim(),
                          fileUrl: selectedFileUrl!,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Note uploaded')),
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
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EDIT ATTENDANCE ─────────────────────────────────────────────
  void _showEditAttendance(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
  ) async {
    final service = ref.read(teacherServiceProvider);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dates = await service.getAttendanceDates(course.id);
      if (context.mounted) Navigator.pop(context);

      if (dates.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No attendance records found')),
          );
        }
        return;
      }

      DateTime selectedDate = dates.first;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text('Edit Attendance — ${course.subjectName}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date picker dropdown
                    DropdownButtonFormField<DateTime>(
                      value: selectedDate,
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        isDense: true,
                      ),
                      items: dates
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                '${d.day}/${d.month}/${d.year}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedDate = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _showEditAttendanceForDate(
                          context,
                          ref,
                          course,
                          selectedDate,
                        );
                      },
                      child: const Text('Load Attendance'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
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

  void _showEditAttendanceForDate(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
    DateTime date,
  ) async {
    final service = ref.read(teacherServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final records = await service.getAttendanceForDate(course.id, dateStr);
      if (context.mounted) Navigator.pop(context);

      // Build mutable status map
      final statusMap = <String, String>{};
      for (final r in records) {
        final studentId = r['studentId'] is Map
            ? r['studentId']['_id']?.toString() ?? ''
            : r['studentId']?.toString() ?? '';
        statusMap[studentId] = r['status'] ?? 'present';
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text('Edit — ${date.day}/${date.month}/${date.year}'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final r = records[index];
                    final studentData = r['studentId'] is Map
                        ? r['studentId'] as Map
                        : <String, dynamic>{};
                    final userData = studentData['userId'] is Map
                        ? studentData['userId'] as Map
                        : <String, dynamic>{};
                    final studentId = studentData['_id']?.toString() ?? '';
                    final name = userData['name'] ?? 'Student ${index + 1}';
                    final currentStatus = statusMap[studentId] ?? 'present';

                    return ListTile(
                      title: Text(name, style: const TextStyle(fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['present', 'absent', 'late'].map((s) {
                          final isSelected = currentStatus == s;
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => statusMap[studentId] = s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _statusColor(s)
                                      : AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s[0].toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
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
                      final recordsList = statusMap.entries
                          .map((e) => {'studentId': e.key, 'status': e.value})
                          .toList();

                      await service.editAttendance(
                        courseId: course.id,
                        date: dateStr,
                        records: recordsList,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attendance updated'),
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
                  child: const Text('Save'),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.danger;
      case 'late':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  // ─── EDIT MARKSHEET ───────────────────────────────────────────────
  void _showEditMarksheet(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarksheetEditorScreen(
          courseId: course.id,
          subjectName: course.subjectName,
          courseTerm: course.term,
          getCourseStudents: ref.read(teacherServiceProvider).getCourseStudents,
          getMarksheetsByCourse: ref
              .read(teacherServiceProvider)
              .getMarksheetsByCourse,
          bulkUpload: ref.read(teacherServiceProvider).bulkUploadMarksheets,
        ),
      ),
    );
  }
}
