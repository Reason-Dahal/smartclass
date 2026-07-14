import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminAttendanceOverrideScreen extends ConsumerStatefulWidget {
  const AdminAttendanceOverrideScreen({super.key});

  @override
  ConsumerState<AdminAttendanceOverrideScreen> createState() =>
      _AdminAttendanceOverrideScreenState();
}

class _AdminAttendanceOverrideScreenState
    extends ConsumerState<AdminAttendanceOverrideScreen> {
  List<CourseModel> _courses = [];
  bool _isLoadingCourses = true;
  String? _error;

  CourseModel? _selectedCourse;
  List<DateTime> _dates = [];
  DateTime? _selectedDate;
  bool _isLoadingDates = false;

  List<Map<String, dynamic>> _records = [];
  final Map<String, String> _statusMap = {};
  bool _isLoadingRecords = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final service = ref.read(adminServiceProvider);
      final courses = await service.getCourses();
      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _onCourseSelected(CourseModel course) async {
    setState(() {
      _selectedCourse = course;
      _selectedDate = null;
      _records = [];
      _statusMap.clear();
      _isLoadingDates = true;
    });

    try {
      final service = ref.read(adminServiceProvider);
      final dates = await service.getAdminAttendanceDates(course.id);
      setState(() {
        _dates = dates;
        _isLoadingDates = false;
      });
    } catch (e) {
      setState(() => _isLoadingDates = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _onDateSelected(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _isLoadingRecords = true;
    });

    try {
      final service = ref.read(adminServiceProvider);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final records = await service.getAdminAttendanceForDate(
        _selectedCourse!.id,
        dateStr,
      );

      final statusMap = <String, String>{};
      for (final r in records) {
        final studentId = r['studentId'] is Map
            ? r['studentId']['_id']?.toString() ?? ''
            : r['studentId']?.toString() ?? '';
        statusMap[studentId] = r['status'] ?? 'present';
      }

      setState(() {
        _records = records;
        _statusMap
          ..clear()
          ..addAll(statusMap);
        _isLoadingRecords = false;
      });
    } catch (e) {
      setState(() => _isLoadingRecords = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _save() async {
    if (_selectedCourse == null || _selectedDate == null) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(adminServiceProvider);
      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      final records = _statusMap.entries
          .map((e) => {'studentId': e.key, 'status': e.value})
          .toList();

      await service.adminEditAttendance(
        courseId: _selectedCourse!.id,
        date: dateStr,
        records: records,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance overridden successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.danger;
      case 'late':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Override Attendance'),
        actions: [
          if (_records.isNotEmpty)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        ],
      ),
      body: _isLoadingCourses
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                // Course dropdown
                // Course picker — searchable, grouped by Program > Term
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showModalBottomSheet<CourseModel>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => _CoursePickerSheet(courses: _courses),
                      );
                      if (picked != null) _onCourseSelected(picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        isDense: true,
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        _selectedCourse == null
                            ? 'Tap to select a course'
                            : '${_selectedCourse!.subjectName} — ${_selectedCourse!.programName} · Term ${_selectedCourse!.term}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedCourse == null
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Date dropdown — only shows once a course is picked
                if (_selectedCourse != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _isLoadingDates
                        ? const LinearProgressIndicator()
                        : _dates.isEmpty
                        ? const Text(
                            'No attendance records exist for this course yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          )
                        : DropdownButtonFormField<DateTime>(
                            value: _selectedDate,
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: _dates.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(
                                  '${d.day}/${d.month}/${d.year}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) _onDateSelected(val);
                            },
                          ),
                  ),

                // Student list — only shows once a date is picked
                if (_isLoadingRecords)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_records.isNotEmpty)
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _records.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = _records[index];
                        final studentData = r['studentId'] is Map
                            ? r['studentId'] as Map
                            : <String, dynamic>{};
                        final userData = studentData['userId'] is Map
                            ? studentData['userId'] as Map
                            : <String, dynamic>{};
                        final studentId = studentData['_id']?.toString() ?? '';
                        final name = userData['name'] ?? 'Student ${index + 1}';
                        final currentStatus =
                            _statusMap[studentId] ?? 'present';

                        return ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: ['present', 'absent', 'late'].map((s) {
                              final isSelected = currentStatus == s;
                              return Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _statusMap[studentId] = s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _statusColor(s)
                                          : AppColors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s[0].toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  )
                else if (_selectedDate != null)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No students found for this date',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Select a course and date to view attendance',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CoursePickerSheet extends StatefulWidget {
  final List<CourseModel> courses;
  const _CoursePickerSheet({required this.courses});

  @override
  State<_CoursePickerSheet> createState() => _CoursePickerSheetState();
}

class _CoursePickerSheetState extends State<_CoursePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // Filter by search query first
    final filtered = _query.isEmpty
        ? widget.courses
        : widget.courses.where((c) {
            final q = _query.toLowerCase();
            return c.subjectName.toLowerCase().contains(q) ||
                c.programName.toLowerCase().contains(q) ||
                c.teacherName.toLowerCase().contains(q);
          }).toList();

    // Group by Program → Term
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
