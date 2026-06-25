import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/teacher_providers.dart';
import '../../widgets/course_card.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class TeacherHomeTab extends ConsumerWidget {
  final String userName;
  const TeacherHomeTab({super.key, required this.userName});

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
                  children: list.map((c) => CourseCard(course: c)).toList(),
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
