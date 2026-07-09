import 'package:client/core/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/student_providers.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class MarksTab extends ConsumerStatefulWidget {
  const MarksTab({super.key});

  @override
  ConsumerState<MarksTab> createState() => _MarksTabState();
}

class _MarksTabState extends ConsumerState<MarksTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Terminal'),
            Tab(text: 'Final'),
          ],
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_TerminalResultsView(), _FinalResultsView()],
          ),
        ),
      ],
    );
  }
}

// ── TERMINAL RESULTS ─────────────────────────────────────────────────────────

class _TerminalResultsView extends ConsumerWidget {
  const _TerminalResultsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTerm = ref.watch(selectedMarksTermProvider);
    final marksheets = ref.watch(studentMarksheetsByTermProvider(selectedTerm));

    // Get all available terms from all marksheets to populate selector
    final allMarksheets = ref.watch(studentMarksheetsProvider);
    final availableTerms =
        allMarksheets.whenOrNull(
          data: (list) {
            final terms = list.map((m) => m.term).toSet().toList()..sort();
            return terms.isEmpty ? [1] : terms;
          },
        ) ??
        [1];

    return Column(
      children: [
        // Term selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Text(
                'Term:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: availableTerms.contains(selectedTerm)
                    ? selectedTerm
                    : availableTerms.first,
                items: availableTerms
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text('Term $t')),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(selectedMarksTermProvider.notifier).state = val;
                  }
                },
              ),
            ],
          ),
        ),

        // Results table
        Expanded(
          child: marksheets.when(
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  message: 'No terminal results for this term',
                  icon: Icons.bar_chart_outlined,
                );
              }

              // Compute aggregate
              final totalMarks = list.fold<double>(
                0,
                (sum, m) => sum + m.internalExamTotalMarks,
              );
              final obtainedMarks = list.fold<double>(
                0,
                (sum, m) => sum + m.internalExamMarks,
              );
              final aggPercent = totalMarks > 0
                  ? (obtainedMarks / totalMarks * 100).toStringAsFixed(1)
                  : '0.0';

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(studentMarksheetsByTermProvider(selectedTerm));
                  ref.invalidate(studentMarksheetsProvider);
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // DataTable
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.infoLight,
                          ),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Subject',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Obtained',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                '%',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: [
                            // Data rows
                            ...list.map((m) {
                              final pct = m.internalExamTotalMarks > 0
                                  ? (m.internalExamMarks /
                                            m.internalExamTotalMarks *
                                            100)
                                        .toStringAsFixed(1)
                                  : '0.0';
                              final isPassing =
                                  double.tryParse(pct) != null &&
                                  double.parse(pct) >= 40;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      m.subjectName,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      m.internalExamTotalMarks.toStringAsFixed(
                                        0,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      m.internalExamMarks.toStringAsFixed(0),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '$pct%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPassing
                                            ? AppColors.success
                                            : AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),

                            // Aggregate row
                            DataRow(
                              color: WidgetStateProperty.all(
                                AppColors.surfaceSecondary,
                              ),
                              cells: [
                                const DataCell(
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    totalMarks.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    obtainedMarks.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '$aggPercent%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LoadingWidget(message: 'Loading results...'),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(studentMarksheetsByTermProvider(selectedTerm)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── FINAL RESULTS ────────────────────────────────────────────────────────────

class _FinalResultsView extends ConsumerWidget {
  const _FinalResultsView();

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
                          // Preview button
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
                          // Download button
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
      const downloadsPath = '/storage/emulated/0/Download';
      final savePath = '$downloadsPath/$fileName';
      await Future.delayed(const Duration(milliseconds: 100)); // brief pause
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Downloading...')));
      }
      // Download using Dio
      final dio = DioClient.instance;
      await dio.download(fileUrl, savePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: $fileName'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    }
  }
}
