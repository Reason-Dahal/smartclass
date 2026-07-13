import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/student_models.dart';
import '../../providers/student_providers.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

// Provider that takes courseId as parameter
final evaluationProvider = FutureProvider.family<EvaluationModel, String>((
  ref,
  courseId,
) async {
  return ref.read(studentServiceProvider).getEvaluation(courseId);
});

class EvaluationTab extends ConsumerStatefulWidget {
  const EvaluationTab({super.key});

  @override
  ConsumerState<EvaluationTab> createState() => _EvaluationTabState();
}

class _EvaluationTabState extends ConsumerState<EvaluationTab> {
  String? _selectedCourseId;
  String? _selectedCourseName;

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(studentCoursesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course selector
          const Text(
            'Select a course',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          courses.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text(
                  'No courses enrolled yet',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'Choose a course',
                  isDense: true,
                ),
                isExpanded: true,
                value: _selectedCourseId,
                items: list.map((c) {
                  final courseId = c.course['_id'] as String? ?? '';
                  final subjectName = c.course['subjectName'] as String? ?? '';
                  return DropdownMenuItem(
                    value: courseId,
                    child: Text(
                      subjectName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final selected = list.firstWhere(
                      (c) => c.course['_id'] == val,
                    );
                    setState(() {
                      _selectedCourseId = val;
                      _selectedCourseName =
                          selected.course['subjectName'] as String?;
                    });
                  }
                },
              );
            },
            loading: () => const LoadingWidget(),
            error: (e, _) => AppErrorWidget(message: e.toString()),
          ),
          const SizedBox(height: 24),

          // Evaluation result
          if (_selectedCourseId != null) ...[
            Text(
              _selectedCourseName ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _EvaluationResult(courseId: _selectedCourseId!),
          ] else
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.insights_outlined,
                    size: 64,
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select a course above to see\nyour evaluation indicator',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EvaluationResult extends ConsumerWidget {
  final String courseId;
  const _EvaluationResult({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluation = ref.watch(evaluationProvider(courseId));

    return evaluation.when(
      data: (eval) => Column(
        children: [
          // Score card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _statusColor(eval.status),
                  _statusColor(eval.status).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${eval.score}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  eval.status,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'out of 100',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Breakdown
          const Text(
            'Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _BreakdownCard(
            label: 'Attendance',
            percent: _getPercent(eval.breakdown, 'attendance'),
            weight: _getWeight(eval.breakdown, 'attendance'),
            contribution: _getContribution(eval.breakdown, 'attendance'),
            color: AppColors.present,
          ),
          _BreakdownCard(
            label: 'Internal Exam',
            percent: _getPercent(eval.breakdown, 'internalExam'),
            weight: _getWeight(eval.breakdown, 'internalExam'),
            contribution: _getContribution(eval.breakdown, 'internalExam'),
            color: AppColors.primary,
          ),
          _BreakdownCard(
            label: 'Assignments',
            percent: _getPercent(eval.breakdown, 'assignments'),
            weight: _getWeight(eval.breakdown, 'assignments'),
            contribution: _getContribution(eval.breakdown, 'assignments'),
            color: AppColors.warning,
          ),
          _BreakdownCard(
            label: 'Teacher Evaluation',
            percent: _getPercent(eval.breakdown, 'teacherEvaluation'),
            weight: _getWeight(eval.breakdown, 'teacherEvaluation'),
            contribution: _getContribution(eval.breakdown, 'teacherEvaluation'),
            color: AppColors.info,
          ),
        ],
      ),
      loading: () => const LoadingWidget(message: 'Computing evaluation...'),
      error: (e, _) {
        // If evaluation is disabled for this course
        if (e.toString().contains('EVALUATION_DISABLED')) {
          return const Center(
            child: Column(
              children: [
                SizedBox(height: 20),
                Icon(
                  Icons.visibility_off_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 12),
                Text(
                  'Your teacher hasn\'t enabled\nevaluation for this course yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        return AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(evaluationProvider(courseId)),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Excellent':
        return AppColors.excellent;
      case 'Good':
        return AppColors.good;
      case 'Average':
        return AppColors.average;
      default:
        return AppColors.atRisk;
    }
  }

  double _getPercent(Map<String, dynamic> breakdown, String key) {
    final item = breakdown[key] as Map<String, dynamic>?;
    return (item?['percent'] ?? item?['score'] ?? 0).toDouble();
  }

  int _getWeight(Map<String, dynamic> breakdown, String key) {
    final item = breakdown[key] as Map<String, dynamic>?;
    return (item?['weight'] ?? 0).toInt();
  }

  double _getContribution(Map<String, dynamic> breakdown, String key) {
    final item = breakdown[key] as Map<String, dynamic>?;
    return (item?['contribution'] ?? 0).toDouble();
  }
}

class _BreakdownCard extends StatelessWidget {
  final String label;
  final double percent;
  final int weight;
  final double contribution;
  final Color color;

  const _BreakdownCard({
    required this.label,
    required this.percent,
    required this.weight,
    required this.contribution,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: AppColors.borderLight,
                color: color,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Weight: $weight%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Contribution: ${contribution.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
