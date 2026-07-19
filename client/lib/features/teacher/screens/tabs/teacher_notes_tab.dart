import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../shared/screens/pdf_viewer_screen.dart';
import '../../providers/teacher_providers.dart';

class TeacherNotesTab extends ConsumerStatefulWidget {
  const TeacherNotesTab({super.key});

  @override
  ConsumerState<TeacherNotesTab> createState() => _TeacherNotesTabState();
}

class _TeacherNotesTabState extends ConsumerState<TeacherNotesTab> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _error;

  // Tracks note IDs currently being deleted or replaced —
  // prevents double-tapping the same note while an action is in flight.
  final Set<String> _busyNoteIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(teacherServiceProvider);
      final groups = await service.getMyNotes();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNote(String noteId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete "$title"? This cannot be undone.'),
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

    setState(() => _busyNoteIds.add(noteId));
    try {
      final service = ref.read(teacherServiceProvider);
      await service.deleteNote(noteId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _busyNoteIds.remove(noteId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _replaceNote(String noteId, String title) async {
    setState(() => _busyNoteIds.add(noteId));
    try {
      final uploadService = UploadService();
      final result = await uploadService.pickAndUploadFile(
        ApiConstants.uploadNote,
      );

      if (result == null) {
        setState(() => _busyNoteIds.remove(noteId));
        return;
      }

      final service = ref.read(teacherServiceProvider);
      await service.replaceNoteFile(
        noteId: noteId,
        fileUrl: result['fileUrl']!,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" replaced with new file'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _busyNoteIds.remove(noteId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _previewNote(String fileUrl, String title) {
    final fileType = fileUrl.toLowerCase().contains('.pdf') ? 'pdf' : 'docx';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PDFViewerScreen(fileUrl: fileUrl, title: title, fileType: fileType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> byProgram = {};
    for (final group in _groups) {
      final programName = group['programName']?.toString() ?? '';
      byProgram.putIfAbsent(programName, () => []).add(group);
    }
    final programs = byProgram.keys.toList()..sort();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_groups.isEmpty) {
      return const Center(
        child: Text(
          'You haven\'t uploaded any notes yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: programs.length,
        itemBuilder: (context, programIndex) {
          final programName = programs[programIndex];
          final courseGroups = byProgram[programName]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderLight),
            ),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: CircleAvatar(
                backgroundColor: AppColors.infoLight,
                child: Text(
                  programName.isNotEmpty ? programName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                programName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              children: courseGroups.map((courseGroup) {
                final subjectName =
                    courseGroup['subjectName']?.toString() ?? '';
                final term = courseGroup['term'];
                final notes = (courseGroup['notes'] as List? ?? [])
                    .cast<Map<String, dynamic>>();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Term $term — $subjectName',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ...notes.map((note) {
                      final noteId = note['_id']?.toString() ?? '';
                      final title = note['title']?.toString() ?? '';
                      final fileUrl = note['fileUrl']?.toString() ?? '';
                      final isBusy = _busyNoteIds.contains(noteId);

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: AppColors.surfaceSecondary,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isBusy)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    tooltip: 'Preview',
                                    onPressed: () =>
                                        _previewNote(fileUrl, title),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.swap_horiz,
                                      size: 18,
                                    ),
                                    tooltip: 'Replace file',
                                    onPressed: () =>
                                        _replaceNote(noteId, title),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.danger,
                                    ),
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteNote(noteId, title),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
