import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/student_providers.dart';
import '../../widgets/attendance_stat.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AttendanceTab extends ConsumerWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(studentAttendanceProvider);

    return attendance.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            message: 'No attendance records yet',
            icon: Icons.calendar_today_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentAttendanceProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final percentage = item.attendancePercentage;
              final color = percentage >= 75
                  ? AppColors.success
                  : AppColors.danger;

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
                              item.subjectName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.borderLight,
                          color: color,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          AttendanceStat(
                            label: 'Present',
                            value: item.present,
                            color: AppColors.present,
                          ),
                          const SizedBox(width: 16),
                          AttendanceStat(
                            label: 'Absent',
                            value: item.absent,
                            color: AppColors.absent,
                          ),
                          const SizedBox(width: 16),
                          AttendanceStat(
                            label: 'Late',
                            value: item.late,
                            color: AppColors.late,
                          ),
                          const SizedBox(width: 16),
                          AttendanceStat(
                            label: 'Total',
                            value: item.totalClasses,
                            color: AppColors.textSecondary,
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
      loading: () => const LoadingWidget(message: 'Loading attendance...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentAttendanceProvider),
      ),
    );
  }
}
