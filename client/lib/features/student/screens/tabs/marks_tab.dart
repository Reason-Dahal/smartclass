import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/student_providers.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class MarksTab extends ConsumerWidget {
  const MarksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksheets = ref.watch(studentMarksheetsProvider);

    return marksheets.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            message: 'No marksheets available yet',
            icon: Icons.bar_chart_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentMarksheetsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final mark = list[index];
              final percentage =
                  (mark.internalExamMarks / mark.internalExamTotalMarks * 100)
                      .toStringAsFixed(1);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              mark.subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            'Term ${mark.term}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _MarkItem(
                            label: 'Internal Exam',
                            value:
                                '${mark.internalExamMarks}/${mark.internalExamTotalMarks}',
                            sub: '$percentage%',
                          ),
                          const SizedBox(width: 20),
                          _MarkItem(
                            label: 'Teacher Eval',
                            value: '${mark.teacherEvaluationScore}/100',
                            sub: 'Score',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading marksheets...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentMarksheetsProvider),
      ),
    );
  }
}

class _MarkItem extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _MarkItem({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          sub,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
