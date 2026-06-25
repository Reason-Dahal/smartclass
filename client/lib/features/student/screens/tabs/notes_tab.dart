import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/student_providers.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class NotesTab extends ConsumerWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(studentNotesProvider);

    return notes.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
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
                    '${note.subjectName} · ${note.uploadedAt.day}/${note.uploadedAt.month}/${note.uploadedAt.year}',
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
