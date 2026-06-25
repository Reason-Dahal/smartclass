import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_providers.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class AssignmentsTab extends ConsumerWidget {
  const AssignmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(studentAssignmentsProvider);

    return assignments.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
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
                AssignmentCard(assignment: list[index], showSubmit: true),
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
