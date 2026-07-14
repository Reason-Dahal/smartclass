import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/upload_service.dart';
import '../data/student_service.dart';
import '../models/student_models.dart';
import '../providers/student_providers.dart';

class AssignmentCard extends ConsumerStatefulWidget {
  final AssignmentModel assignment;
  final bool showSubmit;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.showSubmit = false,
  });

  @override
  ConsumerState<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends ConsumerState<AssignmentCard> {
  bool _isUploading = false;

  Future<void> _submitAssignment() async {
    final uploadService = UploadService();
    final studentService = StudentService();

    setState(() => _isUploading = true);

    try {
      final result = await uploadService.pickAndUploadFile(
        ApiConstants.uploadSubmission,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No file selected')));
        }
        // User cancelled the file picker — not an error, just reset state
        // so the button becomes tappable again.
        return;
      }

      await studentService.submitAssignment(
        widget.assignment.id,
        fileUrl: result['fileUrl'],
        fileType: result['fileType'],
      );

      ref.invalidate(studentAssignmentsGroupedProvider);

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
                  const _StatusBadge(
                    label: 'Submitted',
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                  )
                else if (widget.assignment.isPastDue)
                  const _StatusBadge(
                    label: 'Past due',
                    color: AppColors.danger,
                    bgColor: AppColors.dangerLight,
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
            if (widget.showSubmit && !widget.assignment.isSubmitted) ...[
              const SizedBox(height: 10),
              // Same button, same size, whether idle or submitting —
              // only the child content swaps. Keeps the layout stable
              // and matches the loading-state pattern used everywhere
              // else in the app.
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _submitAssignment,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file, size: 16),
                label: Text(
                  _isUploading
                      ? 'Submitting...'
                      : widget.assignment.isPastDue
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

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
