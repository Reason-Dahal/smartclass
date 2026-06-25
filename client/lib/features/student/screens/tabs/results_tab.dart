import '../../providers/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

final finalResultsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(studentServiceProvider).getMyFinalResults();
});

class ResultsTab extends ConsumerWidget {
  const ResultsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(finalResultsProvider);

    return results.when(
      data: (data) {
        final resultsList = data['results'] as List<dynamic>? ?? [];
        final backlog = data['backlog'] as List<dynamic>? ?? [];

        if (resultsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: AppColors.textMuted.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No final results published yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(finalResultsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Backlog section
              if (backlog.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_outlined,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${backlog.length} Backlog Course${backlog.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...backlog.map((b) {
                        final course =
                            b['course'] as Map<String, dynamic>? ?? {};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 6,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${course['subjectName'] ?? ''} — Term ${b['term']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Results list
              const Text(
                'Term Results',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...resultsList.map((result) {
                final r = result as Map<String, dynamic>;
                final overallStatus = r['overallStatus'] as String? ?? '';
                final term = r['term'] as int? ?? 0;
                final courseResults =
                    r['courseResults'] as List<dynamic>? ?? [];
                final publishedDate = DateTime.tryParse(
                  r['publishedDate'] as String? ?? '',
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Term header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Term $term',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: overallStatus == 'pass'
                                    ? AppColors.successLight
                                    : AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                overallStatus.toUpperCase(),
                                style: TextStyle(
                                  color: overallStatus == 'pass'
                                      ? AppColors.success
                                      : AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (publishedDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Published: ${publishedDate.day}/${publishedDate.month}/${publishedDate.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (courseResults.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 4),
                          ...courseResults.map((cr) {
                            final courseResult = cr as Map<String, dynamic>;
                            final course =
                                courseResult['courseId']
                                    as Map<String, dynamic>? ??
                                {};
                            final status =
                                courseResult['status'] as String? ?? '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    status == 'pass'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color: status == 'pass'
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      course['subjectName'] as String? ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: status == 'pass'
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading results...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(finalResultsProvider),
      ),
    );
  }
}
