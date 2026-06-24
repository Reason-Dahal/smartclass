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
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Take attendance — ${course.subjectName}'),
        content: const Text(
          'Attendance taking requires student list. '
          'This feature works when students are enrolled in this course.',
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
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Upload note — ${course.subjectName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'File URL'),
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
              if (titleController.text.isEmpty || urlController.text.isEmpty)
                return;
              final service = ref.read(teacherServiceProvider);
              await service.uploadNote(
                course.id,
                title: titleController.text,
                fileUrl: urlController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Note uploaded')));
              }
            },
            child: const Text('Upload'),
          ),
        ],
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
  ) {
    final studentIdController = TextEditingController();
    final internalMarksController = TextEditingController();
    final totalMarksController = TextEditingController();
    final evalScoreController = TextEditingController();
    final termController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Marksheet — ${course.subjectName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              TextField(
                controller: termController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Term'),
              ),
              TextField(
                controller: internalMarksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Internal Exam Marks',
                ),
              ),
              TextField(
                controller: totalMarksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Marks'),
              ),
              TextField(
                controller: evalScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Teacher Eval Score (0-100)',
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
              final service = ref.read(teacherServiceProvider);
              await service.uploadMarksheet(
                course.id,
                studentId: studentIdController.text,
                term: int.tryParse(termController.text) ?? 1,
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
                  const SnackBar(content: Text('Marksheet uploaded')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
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
