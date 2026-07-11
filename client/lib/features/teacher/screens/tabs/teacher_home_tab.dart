import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/teacher_models.dart';
import '../../providers/teacher_providers.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class TeacherHomeTab extends ConsumerWidget {
  final String userName;
  final VoidCallback? onNavigateToCourses;

  const TeacherHomeTab({
    super.key,
    required this.userName,
    this.onNavigateToCourses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(teacherCoursesProvider);
    final shortcuts = ref.watch(teacherShortcutsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teacherCoursesProvider);
        ref.invalidate(teacherShortcutsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
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

            // Stats
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

            // Quick access shortcuts
            shortcuts.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Most used',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: list
                            .map(
                              (course) => _ShortcutChip(
                                course: course,
                                onTap: onNavigateToCourses,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // My Courses
            const Text(
              'My Courses',
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
                      .take(3)
                      .map((c) => _CourseListTile(course: c))
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

// ── SHORTCUT CHIP ─────────────────────────────────────────────────────────────

class _ShortcutChip extends StatelessWidget {
  final TeacherCourseModel course;
  final VoidCallback? onTap;

  const _ShortcutChip({required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    course.subjectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${course.programName} · Term ${course.term}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${course.studentCount} students',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── COURSE LIST TILE ──────────────────────────────────────────────────────────

class _CourseListTile extends StatelessWidget {
  final TeacherCourseModel course;
  const _CourseListTile({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.infoLight,
          child: Text(
            course.subjectName.isNotEmpty
                ? course.subjectName[0].toUpperCase()
                : 'C',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          course.subjectName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${course.programName} · Term ${course.term} · ${course.studentCount} students',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────

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
