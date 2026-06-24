import 'package:client/shared/widgets/error_widget.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/app_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/student_service.dart';
import '../models/student_models.dart';
import '../../../core/network/upload_service.dart';
import '../../../core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

// ─── PROVIDERS ───────────────────────────────────────────────────

final studentServiceProvider = Provider((ref) => StudentService());

final studentAttendanceProvider = FutureProvider<List<AttendanceSummary>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyAttendance();
});

final studentAssignmentsProvider = FutureProvider<List<AssignmentModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyAssignments();
});

final studentNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  return ref.read(studentServiceProvider).getMyNotes();
});

final studentMarksheetsProvider = FutureProvider<List<MarksheetModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyMarksheets();
});

final studentCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  return ref.read(studentServiceProvider).getMyCourses();
});

final studentNotificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyNotifications();
});

// ─── DASHBOARD ───────────────────────────────────────────────────

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
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
      const _AttendanceTab(),
      const _AssignmentsTab(),
      const _NotesTab(),
      const _MarksTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? AppConstants.appName : _tabTitle(_currentIndex),
        ),
        actions: [
          // Notifications bell
          Consumer(
            builder: (context, ref, _) {
              final notifications = ref.watch(studentNotificationsProvider);
              final unread =
                  notifications.whenOrNull(
                    data: (list) => list.where((n) => !n.isRead).length,
                  ) ??
                  0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Marks',
          ),
        ],
      ),
    );
  }

  String _tabTitle(int index) {
    switch (index) {
      case 1:
        return 'Attendance';
      case 2:
        return 'Assignments';
      case 3:
        return 'Notes';
      case 4:
        return 'Marks';
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
    final attendance = ref.watch(studentAttendanceProvider);
    final assignments = ref.watch(studentAssignmentsProvider);
    final notifications = ref.watch(studentNotificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentAttendanceProvider);
        ref.invalidate(studentAssignmentsProvider);
        ref.invalidate(studentNotificationsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
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

            // Summary cards row
            Row(
              children: [
                // Attendance card
                Expanded(
                  child: attendance.when(
                    data: (list) {
                      final avg = list.isEmpty
                          ? 0.0
                          : list
                                    .map((a) => a.attendancePercentage)
                                    .reduce((a, b) => a + b) /
                                list.length;
                      return _SummaryCard(
                        label: 'Attendance',
                        value: '${avg.toStringAsFixed(0)}%',
                        subtitle: 'This term',
                        color: avg >= 75 ? AppColors.success : AppColors.danger,
                      );
                    },
                    loading: () => const _SummaryCard(
                      label: 'Attendance',
                      value: '...',
                      subtitle: 'Loading',
                      color: AppColors.textMuted,
                    ),
                    error: (_, __) => const _SummaryCard(
                      label: 'Attendance',
                      value: '-',
                      subtitle: 'Error',
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Pending assignments card
                Expanded(
                  child: assignments.when(
                    data: (list) {
                      final pending = list.where((a) => !a.isSubmitted).length;
                      return _SummaryCard(
                        label: 'Pending',
                        value: '$pending',
                        subtitle: 'Assignments',
                        color: pending > 0
                            ? AppColors.warning
                            : AppColors.success,
                      );
                    },
                    loading: () => const _SummaryCard(
                      label: 'Pending',
                      value: '...',
                      subtitle: 'Assignments',
                      color: AppColors.textMuted,
                    ),
                    error: (_, __) => const _SummaryCard(
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

            // Upcoming assignments section
            const Text(
              'Upcoming assignments',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            assignments.when(
              data: (list) {
                final upcoming = list
                    .where((a) => !a.isSubmitted && !a.isPastDue)
                    .take(3)
                    .toList();
                if (upcoming.isEmpty) {
                  return const _EmptyState(
                    message: 'No pending assignments',
                    icon: Icons.check_circle_outline,
                  );
                }
                return Column(
                  children: upcoming
                      .map((a) => _AssignmentCard(assignment: a))
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
                  return const _EmptyState(
                    message: 'No notifications',
                    icon: Icons.notifications_none,
                  );
                }
                return Column(
                  children: recent
                      .map((n) => _NotificationCard(notification: n))
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

// ─── ATTENDANCE TAB ──────────────────────────────────────────────

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(studentAttendanceProvider);

    return attendance.when(
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyState(
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
                          _AttendanceStat(
                            label: 'Present',
                            value: item.present,
                            color: AppColors.present,
                          ),
                          const SizedBox(width: 16),
                          _AttendanceStat(
                            label: 'Absent',
                            value: item.absent,
                            color: AppColors.absent,
                          ),
                          const SizedBox(width: 16),
                          _AttendanceStat(
                            label: 'Late',
                            value: item.late,
                            color: AppColors.late,
                          ),
                          const SizedBox(width: 16),
                          _AttendanceStat(
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

// ─── ASSIGNMENTS TAB ─────────────────────────────────────────────

class _AssignmentsTab extends ConsumerWidget {
  const _AssignmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(studentAssignmentsProvider);

    return assignments.when(
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyState(
            message: 'No assignments yet',
            icon: Icons.assignment_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentAssignmentsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) =>
                _AssignmentCard(assignment: list[index], showSubmit: true),
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading assignments...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentAssignmentsProvider),
      ),
    );
  }
}

// ─── NOTES TAB ───────────────────────────────────────────────────

class _NotesTab extends ConsumerWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(studentNotesProvider);

    return notes.when(
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyState(
            message: 'No notes uploaded yet',
            icon: Icons.folder_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentNotesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final note = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${note.subjectName} · ${_formatDate(note.uploadedAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.download_outlined,
                    color: AppColors.primary,
                  ),
                  onTap: () async {
                    final uri = Uri.parse(note.fileUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open file')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading notes...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentNotesProvider),
      ),
    );
  }
}

// ─── MARKS TAB ───────────────────────────────────────────────────

class _MarksTab extends ConsumerWidget {
  const _MarksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marksheets = ref.watch(studentMarksheetsProvider);

    return marksheets.when(
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyState(
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

// ─── REUSABLE SMALL WIDGETS ───────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends ConsumerStatefulWidget {
  final AssignmentModel assignment;
  final bool showSubmit;

  const _AssignmentCard({required this.assignment, this.showSubmit = false});

  @override
  ConsumerState<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends ConsumerState<_AssignmentCard> {
  bool _isUploading = false;

  Future<void> _submitAssignment() async {
    final uploadService = UploadService();
    final studentService = StudentService();

    setState(() => _isUploading = true);

    try {
      final fileUrl = await uploadService.pickAndUploadFile(
        ApiConstants.uploadSubmission,
      );

      if (fileUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No file selected')));
        }
        return;
      }

      await studentService.submitAssignment(
        widget.assignment.id,
        fileUrl: fileUrl,
      );

      // Refresh assignments list
      ref.invalidate(studentAssignmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
              children: [
                Expanded(
                  child: Text(
                    widget.assignment.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (widget.assignment.isSubmitted)
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
                      'Submitted',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (widget.assignment.isPastDue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Past due',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.assignment.subjectName} · Due ${_formatDate(widget.assignment.dueDate)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            // Submit button
            if (widget.showSubmit && !widget.assignment.isSubmitted) ...[
              const SizedBox(height: 10),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submitAssignment,
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: Text(
                        widget.assignment.isPastDue
                            ? 'Submit late'
                            : 'Submit assignment',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        backgroundColor: widget.assignment.isPastDue
                            ? AppColors.warning
                            : AppColors.primary,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _iconForType(notification.type),
          color: notification.isRead ? AppColors.textMuted : AppColors.primary,
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontSize: 13,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _formatDate(notification.createdAt),
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'note':
        return Icons.folder_outlined;
      case 'grade':
        return Icons.grade_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
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

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
