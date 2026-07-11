import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/upload_service.dart';
import '../../providers/student_providers.dart';
import '../../models/student_models.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AssignmentsTab extends ConsumerWidget {
  const AssignmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(studentAssignmentsGroupedProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return const EmptyState(
            message: 'No assignments for current term',
            icon: Icons.assignment_outlined,
          );
        }

        // Check if all groups have no assignments
        final hasAny = groups.any((g) => g.assignments.isNotEmpty);
        if (!hasAny) {
          return const EmptyState(
            message: 'No assignments for current term',
            icon: Icons.assignment_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(studentAssignmentsGroupedProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              if (group.assignments.isEmpty) return const SizedBox.shrink();
              return _SubjectSection(group: group);
            },
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading assignments...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentAssignmentsGroupedProvider),
      ),
    );
  }
}

// ── SUBJECT SECTION ──────────────────────────────────────────────────────────

class _SubjectSection extends StatelessWidget {
  final AssignmentGroupModel group;
  const _SubjectSection({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject header
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                group.subjectName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${group.assignments.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Assignment cards
        ...group.assignments.map((a) => _AssignmentCard(assignment: a)),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── ASSIGNMENT CARD ──────────────────────────────────────────────────────────

class _AssignmentCard extends ConsumerWidget {
  final AssignmentModel assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = assignment.submission;
    final isSubmitted = assignment.isSubmitted;
    final isPastDue = assignment.isPastDue;
    final isGraded = sub?.isGraded ?? false;
    final canDelete = isSubmitted && !isGraded;
    final canResubmit = !isSubmitted && !isPastDue;
    final canSubmitLate = !isSubmitted && isPastDue;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Status badge
                _StatusBadge(
                  isSubmitted: isSubmitted,
                  isPastDue: isPastDue,
                  isGraded: isGraded,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Due date
            Text(
              'Due: ${_formatDate(assignment.dueDate)}',
              style: TextStyle(
                fontSize: 12,
                color: isPastDue && !isSubmitted
                    ? AppColors.danger
                    : AppColors.textSecondary,
              ),
            ),

            // Description
            if (assignment.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                assignment.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Grade and feedback
            if (isGraded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grade: ${sub!.grade!.toStringAsFixed(0)}/100',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontSize: 13,
                      ),
                    ),
                    if (sub.feedback != null && sub.feedback!.isNotEmpty)
                      Text(
                        sub.feedback!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Preview submission
                if (isSubmitted && sub?.fileUrl != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text(
                      'Preview',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      context.push(
                        '/pdf-viewer'
                        '?url=${Uri.encodeComponent(sub!.fileUrl!)}'
                        '&title=${Uri.encodeComponent(assignment.title)}'
                        '&type=${sub.fileType ?? 'pdf'}',
                      );
                    },
                  ),

                // Submit or Resubmit
                if (canResubmit || canSubmitLate)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_outlined, size: 14),
                    label: Text(
                      canSubmitLate ? 'Submit Late' : 'Submit',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSubmitLate
                          ? AppColors.warning
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () =>
                        _submitAssignment(context, ref, assignment.id),
                  ),

                // Delete submission
                if (canDelete)
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: () => _deleteSubmission(context, ref, sub!.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _submitAssignment(
    BuildContext context,
    WidgetRef ref,
    String assignmentId,
  ) async {
    try {
      final uploadService = UploadService();
      final result = await uploadService.pickAndUploadFile(
        ApiConstants.uploadSubmission,
      );
      if (result == null) return; // user cancelled

      await ref
          .read(studentServiceProvider)
          .submitAssignment(
            assignmentId,
            fileUrl: result['fileUrl'],
            fileType: result['fileType'],
          );

      ref.invalidate(studentAssignmentsGroupedProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteSubmission(
    BuildContext context,
    WidgetRef ref,
    String submissionId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Submission'),
        content: const Text(
          'Delete your submission? You can resubmit before the due date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(studentServiceProvider).deleteSubmission(submissionId);
      ref.invalidate(studentAssignmentsGroupedProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

// ── STATUS BADGE ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isSubmitted;
  final bool isPastDue;
  final bool isGraded;

  const _StatusBadge({
    required this.isSubmitted,
    required this.isPastDue,
    required this.isGraded,
  });

  @override
  Widget build(BuildContext context) {
    if (isGraded) {
      return _badge('Graded', AppColors.success, AppColors.successLight);
    }
    if (isSubmitted) {
      return _badge('Submitted', AppColors.primary, AppColors.infoLight);
    }
    if (isPastDue) {
      return _badge('Past Due', AppColors.danger, AppColors.dangerLight);
    }
    return const SizedBox.shrink();
  }

  Widget _badge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
