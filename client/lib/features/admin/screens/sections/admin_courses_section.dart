import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AdminCoursesSection extends ConsumerWidget {
  const AdminCoursesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(adminCoursesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateCourse(context, ref),
      ),

      body: courses.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No courses yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminCoursesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final c = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.infoLight,
                          child: Text(
                            '${c.term}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          c.subjectName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.programName} · Term ${c.term}'),
                            Text(
                              c.teacherName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.isActive
                                    ? AppColors.successLight
                                    : AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                c.isElective ? 'Elective' : 'Core',
                                style: TextStyle(
                                  color: c.isActive
                                      ? AppColors.success
                                      : AppColors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () =>
                                  _showCourseOptions(context, ref, c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminCoursesProvider),
        ),
      ),
    );
  }

  void _showCourseOptions(BuildContext context, WidgetRef ref, CourseModel c) {
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
              c.subjectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${c.programName} · Term ${c.term} · ${c.teacherName}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Edit Course'),
              onTap: () {
                Navigator.pop(context);
                _showEditCourse(context, ref, c);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.group_add_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Manage Enrollment'),
              subtitle: const Text(
                'View and add students to this course',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEnrollmentManager(context, ref, c);
              },
            ),

            if (c.isActive)
              ListTile(
                leading: const Icon(
                  Icons.pause_circle_outline,
                  color: AppColors.textMuted,
                ),
                title: const Text('Deactivate'),
                subtitle: const Text(
                  'Hidden from teacher and student views',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deactivateCourse(context, ref, c);
                },
              )
            else
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                title: const Text('Reactivate'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref
                        .read(adminServiceProvider)
                        .editCourse(courseId: c.id, isActive: true);
                    ref.invalidate(adminCoursesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Course reactivated'),
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
              ),
          ],
        ),
      ),
    );
  }

  void _showEditCourse(
    BuildContext context,
    WidgetRef ref,
    CourseModel c,
  ) async {
    final service = ref.read(adminServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final teachers = await service.getTeachers();
      if (context.mounted) Navigator.pop(context);

      String? selectedTeacherId = c.teacherId;
      final subjectController = TextEditingController(text: c.subjectName);
      bool isElective = c.isElective;
      bool isSubmitting = false;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Edit Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedTeacherId,
                      decoration: const InputDecoration(
                        labelText: 'Teacher',
                        isDense: true,
                      ),
                      isExpanded: true,
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
                      onChanged: isSubmitting
                          ? null
                          : (val) => setState(() => selectedTeacherId = val),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Text(
                          'Elective course',
                          style: TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Switch(
                          value: isElective,
                          onChanged: isSubmitting
                              ? null
                              : (val) => setState(() => isElective = val),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Program (${c.programName}) and term (${c.term}) cannot be changed.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          try {
                            await service.editCourse(
                              courseId: c.id,
                              subjectName: subjectController.text.trim(),
                              teacherId: selectedTeacherId,
                              isElective: isElective,
                            );
                            ref.invalidate(adminCoursesProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Course updated'),
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

  void _showEnrollmentManager(
    BuildContext context,
    WidgetRef ref,
    CourseModel c,
  ) async {
    final service = ref.read(adminServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final status = await service.getCourseEnrollmentStatus(c.id);
      if (context.mounted) Navigator.pop(context);

      final enrolled = (status['enrolled'] as List)
          .cast<Map<String, dynamic>>();
      final notEnrolled = (status['notEnrolled'] as List)
          .cast<Map<String, dynamic>>();

      // Tracks which student IDs currently have an enroll request in flight —
      // prevents double-tapping the same row while its request is pending.
      final enrollingIds = <String>{};

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text('Enrollment — ${c.subjectName}'),
              content: SizedBox(
                width: double.maxFinite,
                height: 480,
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textMuted,
                        tabs: [
                          Tab(text: 'Enrolled (${enrolled.length})'),
                          Tab(text: 'Not Enrolled (${notEnrolled.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            enrolled.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No students enrolled yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: enrolled.length,
                                    itemBuilder: (context, i) {
                                      final s = enrolled[i];
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.check_circle,
                                          color: AppColors.success,
                                          size: 20,
                                        ),
                                        title: Text(
                                          s['name'] ?? '',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          s['rollNumber'] ?? '',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    },
                                  ),

                            notEnrolled.isEmpty
                                ? const Center(
                                    child: Text(
                                      'All eligible students are enrolled',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: notEnrolled.length,
                                    itemBuilder: (context, i) {
                                      final s = notEnrolled[i];
                                      final studentId = s['studentId']
                                          .toString();
                                      final isEnrolling = enrollingIds.contains(
                                        studentId,
                                      );

                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.person_outline,
                                          color: AppColors.textMuted,
                                          size: 20,
                                        ),
                                        title: Text(
                                          s['name'] ?? '',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          s['rollNumber'] ?? '',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        trailing: SizedBox(
                                          width: 64,
                                          child: isEnrolling
                                              ? const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                )
                                              : TextButton(
                                                  onPressed: () async {
                                                    setState(
                                                      () => enrollingIds.add(
                                                        studentId,
                                                      ),
                                                    );
                                                    try {
                                                      await service
                                                          .manualEnroll(
                                                            studentId:
                                                                studentId,
                                                            courseId: c.id,
                                                          );
                                                      setState(() {
                                                        enrollingIds.remove(
                                                          studentId,
                                                        );
                                                        notEnrolled.removeAt(i);
                                                        enrolled.add(s);
                                                      });
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              '${s['name']} enrolled',
                                                            ),
                                                            backgroundColor:
                                                                AppColors
                                                                    .success,
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      setState(
                                                        () => enrollingIds
                                                            .remove(studentId),
                                                      );
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              e.toString(),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: const Text('Enroll'),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.invalidate(adminCoursesProvider);
                  },
                  child: const Text('Close'),
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

  Future<void> _deactivateCourse(
    BuildContext context,
    WidgetRef ref,
    CourseModel c,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Course'),
        content: Text(
          'Deactivate ${c.subjectName}? It will be hidden from '
          'teacher and student views. Existing data is preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // This confirm dialog already prevents accidental double-taps (it closes
    // immediately on tap), and deactivation is a single quick call — no
    // separate loading state needed beyond the standard try/catch below.
    try {
      await ref.read(adminServiceProvider).deactivateCourse(c.id);
      ref.invalidate(adminCoursesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course deactivated'),
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
  }

  void _showCreateCourse(BuildContext context, WidgetRef ref) async {
    final service = ref.read(adminServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final programs = await service.getPrograms();
      final teachers = await service.getTeachers();
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
      bool isSubmitting = false;

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
                        onChanged: isSubmitting
                            ? null
                            : (val) {
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
                        onChanged: isSubmitting
                            ? null
                            : (val) => setState(() => selectedTeacherId = val),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: subjectController,
                        enabled: !isSubmitting,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: termController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: selectedTotalTerms != null
                              ? 'Term (1–$selectedTotalTerms)'
                              : 'Term',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Text(
                            'Elective course',
                            style: TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          Switch(
                            value: isElective,
                            onChanged: isSubmitting
                                ? null
                                : (val) => setState(() => isElective = val),
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isSubmitting ||
                          selectedProgramId == null ||
                          selectedTeacherId == null ||
                          subjectController.text.isEmpty
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          try {
                            await service.createCourse(
                              programId: selectedProgramId!,
                              teacherId: selectedTeacherId!,
                              subjectName: subjectController.text.trim(),
                              term: int.tryParse(termController.text) ?? 1,
                              isElective: isElective,
                            );
                            ref.invalidate(adminCoursesProvider);
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
                      : const Text('Create'),
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
