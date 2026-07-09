import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/student_providers.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class HomeTab extends ConsumerWidget {
  final String userName;
  const HomeTab({super.key, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(studentAttendanceProvider);
    final assignmentsAsync = ref.watch(studentAssignmentsGroupedProvider);
    final notifications = ref.watch(studentNotificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentAttendanceProvider);
        ref.invalidate(studentAssignmentsGroupedProvider);
        ref.invalidate(studentNotificationsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: attendance.when(
                    data: (list) {
                      final avg = list.isEmpty
                          ? 0.0
                          : list
                                    .map((a) => a.attendancePercentage)
                                    .reduce((a, b) => a + b) /
                                list.length;
                      return SummaryCard(
                        label: 'Attendance',
                        value: '${avg.toStringAsFixed(0)}%',
                        subtitle: 'This term',
                        color: avg >= 75 ? AppColors.success : AppColors.danger,
                      );
                    },
                    loading: () => const SummaryCard(
                      label: 'Attendance',
                      value: '...',
                      subtitle: 'Loading',
                      color: AppColors.textMuted,
                    ),
                    error: (_, __) => const SummaryCard(
                      label: 'Attendance',
                      value: '-',
                      subtitle: 'Error',
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: // Summary card — pending count
                  assignmentsAsync.when(
                    data: (groups) {
                      // Flatten all assignments from all groups
                      final allAssignments = groups
                          .expand((g) => g.assignments)
                          .toList();
                      final pending = allAssignments
                          .where((a) => !a.isSubmitted)
                          .length;
                      return SummaryCard(
                        label: 'Pending',
                        value: '$pending',
                        subtitle: 'Assignments',
                        color: pending > 0
                            ? AppColors.warning
                            : AppColors.success,
                      );
                    },
                    loading: () => const SummaryCard(
                      label: 'Pending',
                      value: '...',
                      subtitle: 'Assignments',
                      color: AppColors.textMuted,
                    ),
                    error: (_, __) => const SummaryCard(
                      label: 'Pending',
                      value: '-',
                      subtitle: 'Assignments',
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upcoming assignments
            const Text(
              'Upcoming assignments',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Upcoming assignments section
            assignmentsAsync.when(
              data: (groups) {
                final allAssignments = groups
                    .expand((g) => g.assignments)
                    .toList();
                final upcoming = allAssignments
                    .where((a) => !a.isSubmitted && !a.isPastDue)
                    .take(3)
                    .toList();
                if (upcoming.isEmpty) {
                  return const EmptyState(
                    message: 'No pending assignments',
                    icon: Icons.check_circle_outline,
                  );
                }
                return Column(
                  children: upcoming
                      .map((a) => AssignmentCard(assignment: a))
                      .toList(),
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
            ),
            const SizedBox(height: 24),

            // Recent notifications
            const Text(
              'Recent notifications',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            notifications.when(
              data: (list) {
                final recent = list.take(3).toList();
                if (recent.isEmpty) {
                  return const EmptyState(
                    message: 'No notifications',
                    icon: Icons.notifications_none,
                  );
                }
                return Column(
                  children: recent
                      .map((n) => NotificationCard(notification: n))
                      .toList(),
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}
