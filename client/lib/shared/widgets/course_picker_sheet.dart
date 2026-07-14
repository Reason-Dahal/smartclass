import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/admin/models/admin_models.dart';

/// A searchable, Program → Term grouped course picker, shown as a
/// draggable bottom sheet. Returns the selected CourseModel via
/// Navigator.pop(context, course), or null if dismissed.
///
/// Usage:
///   final picked = await showModalBottomSheet<CourseModel>(
///     context: context,
///     isScrollControlled: true,
///     shape: const RoundedRectangleBorder(
///       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
///     ),
///     builder: (_) => CoursePickerSheet(courses: myCourseList),
///   );
class CoursePickerSheet extends StatefulWidget {
  final List<CourseModel> courses;
  const CoursePickerSheet({super.key, required this.courses});

  @override
  State<CoursePickerSheet> createState() => _CoursePickerSheetState();
}

class _CoursePickerSheetState extends State<CoursePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.courses
        : widget.courses.where((c) {
            final q = _query.toLowerCase();
            return c.subjectName.toLowerCase().contains(q) ||
                c.programName.toLowerCase().contains(q) ||
                c.teacherName.toLowerCase().contains(q);
          }).toList();

    final Map<String, Map<int, List<CourseModel>>> grouped = {};
    for (final course in filtered) {
      grouped.putIfAbsent(course.programName, () => {});
      grouped[course.programName]!.putIfAbsent(course.term, () => []);
      grouped[course.programName]![course.term]!.add(course);
    }
    final programs = grouped.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by subject, program, or teacher',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          Expanded(
            child: programs.isEmpty
                ? const Center(
                    child: Text(
                      'No courses match your search',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: programs.length,
                    itemBuilder: (context, programIndex) {
                      final programName = programs[programIndex];
                      final termMap = grouped[programName]!;
                      final terms = termMap.keys.toList()..sort();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Text(
                              programName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          ...terms.map((term) {
                            final termCourses = termMap[term]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 2,
                                  ),
                                  child: Text(
                                    'Term $term',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                ...termCourses.map(
                                  (course) => ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.only(
                                      left: 8,
                                    ),
                                    title: Text(
                                      course.subjectName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      course.teacherName,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    onTap: () => Navigator.pop(context, course),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Compact tap-to-open field that opens a CoursePickerSheet and
/// displays the current selection. Drop this in place of a raw
/// DropdownButtonFormField<CourseModel> anywhere a searchable,
/// grouped course picker is needed.
class CoursePickerField extends StatelessWidget {
  final List<CourseModel> courses;
  final CourseModel? selected;
  final ValueChanged<CourseModel> onSelected;
  final String label;

  const CoursePickerField({
    super.key,
    required this.courses,
    required this.selected,
    required this.onSelected,
    this.label = 'Course',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showModalBottomSheet<CourseModel>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => CoursePickerSheet(courses: courses),
        );
        if (picked != null) onSelected(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selected == null
              ? 'Tap to select a course'
              : '${selected!.subjectName} — ${selected!.programName} · Term ${selected!.term}',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: selected == null
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
