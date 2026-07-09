import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/student_models.dart';
import '../../providers/student_providers.dart';
import '../../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  int _selectedTerm = 1;
  bool _initialised = false;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(studentNotesGroupedProvider(_selectedTerm));

    return notesAsync.when(
      data: (response) {
        // Set initial term to currentTerm on first load
        if (!_initialised) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedTerm = response.currentTerm;
                _initialised = true;
              });
            }
          });
        }

        final availableTerms = response.availableTerms.isEmpty
            ? [response.currentTerm]
            : response.availableTerms;

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(studentNotesGroupedProvider(_selectedTerm)),
          child: Column(
            children: [
              // ── Term switcher ─────────────────────────────────────
              if (availableTerms.length > 1)
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown
                      Row(
                        children: [
                          const Text(
                            'Term:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            value: availableTerms.contains(_selectedTerm)
                                ? _selectedTerm
                                : availableTerms.first,
                            items: availableTerms
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text('Term $t'),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedTerm = val);
                              }
                            },
                          ),
                        ],
                      ),
                      // Horizontal scrollable tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: availableTerms.map((t) {
                            final isSelected = t == _selectedTerm;
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: 8,
                                bottom: 8,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTerm = t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.infoLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Term $t',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Notes list ────────────────────────────────────────
              Expanded(
                child:
                    response.groups.isEmpty ||
                        response.groups.every((g) => g.notes.isEmpty)
                    ? const EmptyState(
                        message: 'No notes for this term',
                        icon: Icons.folder_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: response.groups.length,
                        itemBuilder: (context, index) {
                          final group = response.groups[index];
                          if (group.notes.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _NoteSubjectSection(group: group);
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading notes...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(studentNotesGroupedProvider(_selectedTerm)),
      ),
    );
  }
}

// ── SUBJECT SECTION ──────────────────────────────────────────────────────────

class _NoteSubjectSection extends StatelessWidget {
  final NoteGroupModel group;
  const _NoteSubjectSection({required this.group});

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
                  '${group.notes.length}',
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

        // Note cards
        ...group.notes.map((note) => _NoteCard(note: note)),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── NOTE CARD ────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final isPdf = note.fileType == 'pdf';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${note.uploadedAt.day}/${note.uploadedAt.month}/${note.uploadedAt.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Preview button
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: Text(
                      isPdf ? 'Preview' : 'Open',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      context.push(
                        '/pdf-viewer'
                        '?url=${Uri.encodeComponent(note.fileUrl)}'
                        '&title=${Uri.encodeComponent(note.title)}'
                        '&type=${note.fileType}',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Download button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download_outlined, size: 14),
                    label: const Text(
                      'Download',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _download(context, note.fileUrl),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open file');
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
