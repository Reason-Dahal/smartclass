import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/report_card.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AdminReportsSection extends ConsumerWidget {
  const AdminReportsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);

    return reports.when(
      data: (report) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminReportsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ReportCard(
              title: 'Overview',
              children: [
                ReportRow(
                  label: 'Total students',
                  value: '${report.totalStudents}',
                ),
                ReportRow(
                  label: 'Total teachers',
                  value: '${report.totalTeachers}',
                ),
                ReportRow(
                  label: 'Total programs',
                  value: '${report.totalPrograms}',
                ),
                ReportRow(
                  label: 'Total courses',
                  value: '${report.totalCourses}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReportCard(
              title: 'Attendance',
              children: [
                ReportRow(
                  label: 'Overall rate',
                  value: report.overallAttendanceRate,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReportCard(
              title: 'Assignments',
              children: [
                ReportRow(
                  label: 'Total assignments',
                  value: '${report.totalAssignments}',
                ),
                ReportRow(
                  label: 'Total submissions',
                  value: '${report.totalSubmissions}',
                ),
                ReportRow(
                  label: 'Submission rate',
                  value: report.submissionRate,
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const LoadingWidget(message: 'Loading reports...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(adminReportsProvider),
      ),
    );
  }
}
