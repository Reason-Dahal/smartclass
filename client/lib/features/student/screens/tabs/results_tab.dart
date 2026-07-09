import 'package:client/core/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../providers/student_providers.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ResultsTab extends ConsumerWidget {
  const ResultsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(studentFinalResultsProvider);

    return results.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            message: 'No official results published yet',
            icon: Icons.assignment_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentFinalResultsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final r = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${r.programName} — Term ${r.term}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Published: ${r.publishedDate.day}/${r.publishedDate.month}/${r.publishedDate.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                              ),
                              label: const Text('Preview'),
                              onPressed: () {
                                context.push(
                                  '/pdf-viewer'
                                  '?url=${Uri.encodeComponent(r.fileUrl)}'
                                  '&title=${Uri.encodeComponent('${r.programName} Term ${r.term} Results')}'
                                  '&type=${r.fileType}',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 16,
                              ),
                              label: const Text('Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _downloadResult(
                                context,
                                r.fileUrl,
                                '${r.programName}_Term${r.term}_Results.${r.fileType}',
                              ),
                            ),
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
      loading: () => const LoadingWidget(message: 'Loading results...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentFinalResultsProvider),
      ),
    );
  }

  Future<void> _downloadResult(
    BuildContext context,
    String fileUrl,
    String fileName,
  ) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download: ${e.toString()}')),
        );
      }
    }
  }
}
