import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/app_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/teacher_service.dart';
import '../models/teacher_models.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';
import '../../../core/network/upload_service.dart';
import '../../../core/constants/api_constants.dart';
import 'dart:convert';

// ─── PROVIDERS ───────────────────────────────────────────────────

final teacherServiceProvider = Provider((ref) => TeacherService());

final teacherCoursesProvider = FutureProvider<List<TeacherCourseModel>>((
  ref,
) async {
  return ref.read(teacherServiceProvider).getMyCourses();
});

final selectedCourseProvider = StateProvider<TeacherCourseModel?>(
  (ref) => null,
);

// ─── DASHBOARD ───────────────────────────────────────────────────

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  int _currentIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userJson = await SecureStorage.getUser();
    if (userJson != null && mounted) {
      final user = jsonDecode(userJson);
      setState(() => _userName = user['name'] ?? '');
    }
  }

  Future<void> _logout() async {
    await SecureStorage.clearAll();
    if (mounted) context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(userName: _userName),
      const _CoursesTab(),
      const _GradingTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? AppConstants.appName : _tabTitle(_currentIndex),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grading_outlined),
            activeIcon: Icon(Icons.grading),
            label: 'Grading',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _tabTitle(int index) {
    switch (index) {
      case 1:
        return 'My Courses';
      case 2:
        return 'Grading';
      case 3:
        return 'Profile';
      default:
        return AppConstants.appName;
    }
  }
}

// ─── HOME TAB ────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  final String userName;
  const _HomeTab({required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(teacherCoursesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(teacherCoursesProvider),
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
            courses.when(
              data: (list) => Row(
                children: [
                  _StatCard(label: 'Courses', value: '${list.length}'),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Students',
                    value: '${list.fold(0, (sum, c) => sum + c.studentCount)}',
                  ),
                ],
              ),
              loading: () => const LoadingWidget(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // My courses list
            const Text(
              'My courses',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            courses.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'No courses assigned yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return Column(
                  children: list
                      .map((course) => _CourseCard(course: course))
                      .toList(),
                );
              },
              loading: () => const LoadingWidget(message: 'Loading courses...'),
              error: (e, _) => AppErrorWidget(message: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COURSES TAB ─────────────────────────────────────────────────

class _CoursesTab extends ConsumerWidget {
  const _CoursesTab();

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
            return _CourseDetailCard(
              course: course,
              onTap: () {
                ref.read(selectedCourseProvider.notifier).state = course;
                _showCourseActions(context, ref, course);
              },
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
            _ActionTile(
              icon: Icons.calendar_today,
              label: 'Take attendance',
              onTap: () {
                Navigator.pop(context);
                _showTakeAttendance(context, ref, course);
              },
            ),
            _ActionTile(
              icon: Icons.assignment_add,
              label: 'Create assignment',
              onTap: () {
                Navigator.pop(context);
                _showCreateAssignment(context, ref, course);
              },
            ),
            _ActionTile(
              icon: Icons.upload_file,
              label: 'Upload note',
              onTap: () {
                Navigator.pop(context);
                _showUploadNote(context, ref, course);
              },
            ),
            _ActionTile(
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

    // Show loading while fetching students
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final students = await service.getCourseStudents(course.id);
      if (context.mounted) Navigator.pop(context); // close loading

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

      // Build attendance map — default everyone to present
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
                    // Date field
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Mark all present button
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

                    // Student list
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
                                // Avatar
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

                                // Name and roll
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

                                // P / A / L toggles
                                Row(
                                  children: [
                                    _StatusButton(
                                      label: 'P',
                                      selected: status == 'present',
                                      selectedColor: AppColors.present,
                                      onTap: () => setState(
                                        () => attendanceMap[studentId] =
                                            'present',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _StatusButton(
                                      label: 'A',
                                      selected: status == 'absent',
                                      selectedColor: AppColors.absent,
                                      onTap: () => setState(
                                        () =>
                                            attendanceMap[studentId] = 'absent',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _StatusButton(
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
                if (titleController.text.isEmpty || dueDate == null) {
                  return;
                }
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
              // File picker button
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
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
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
                // Show selected file confirmation
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

// ─── GRADING TAB ─────────────────────────────────────────────────

class _GradingTab extends ConsumerWidget {
  const _GradingTab();

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
                onTap: () => _showMarksheetEntry(context, ref, course),
              ),
            );
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
    );
  }

  void _showMarksheetEntry(
    BuildContext context,
    WidgetRef ref,
    TeacherCourseModel course,
  ) async {
    final service = ref.read(teacherServiceProvider);

    // Show loading while fetching students
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

      // Build marks map for each student
      // { studentId: { internalMarks, totalMarks, evalScore, term } }
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
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
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
                                  // Student info
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

                                  // Marks fields
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
                      // Submit marksheet for each student
                      for (final student in students) {
                        final studentId = student['studentId'] as String;
                        final controllers = marksMap[studentId]!;

                        final internalMarks =
                            double.tryParse(
                              controllers['internalMarks']!.text,
                            ) ??
                            0;
                        final totalMarks =
                            double.tryParse(controllers['totalMarks']!.text) ??
                            100;
                        final evalScore =
                            double.tryParse(controllers['evalScore']!.text) ??
                            0;
                        final term =
                            int.tryParse(controllers['term']!.text) ?? 1;

                        // Skip if marks not entered
                        if (controllers['internalMarks']!.text.isEmpty) {
                          continue;
                        }

                        await service.uploadMarksheet(
                          course.id,
                          studentId: studentId,
                          term: term,
                          internalExamMarks: internalMarks,
                          internalExamTotalMarks: totalMarks,
                          teacherEvaluationScore: evalScore,
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

// ─── PROFILE TAB ─────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: SecureStorage.getUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingWidget();
        final user = jsonDecode(snapshot.data!) as Map<String, dynamic>;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.infoLight,
                child: Text(
                  (user['name'] as String? ?? 'T')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user['name'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                user['email'] ?? '',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user['role']?.toString().toUpperCase() ?? '',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── SMALL WIDGETS ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final TeacherCourseModel course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.subjectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.programName} · Term ${course.term} · ${course.studentCount} students',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? selectedColor : Colors.white,
          border: Border.all(
            color: selected ? selectedColor : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseDetailCard extends StatelessWidget {
  final TeacherCourseModel course;
  final VoidCallback onTap;

  const _CourseDetailCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.subjectName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.programName} · Term ${course.term}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.studentCount} students enrolled',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (course.evaluationEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Eval ON',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.more_vert, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}
