import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../../../shared/widgets/course_picker_sheet.dart';
import '../../../shared/screens/marksheet_editor_screen.dart';

class AdminMarksheetOverrideScreen extends ConsumerStatefulWidget {
  const AdminMarksheetOverrideScreen({super.key});

  @override
  ConsumerState<AdminMarksheetOverrideScreen> createState() =>
      _AdminMarksheetOverrideScreenState();
}

class _AdminMarksheetOverrideScreenState
    extends ConsumerState<AdminMarksheetOverrideScreen> {
  List<CourseModel> _courses = [];
  bool _isLoading = true;
  String? _error;
  CourseModel? _selectedCourse;

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onCourseSelected(CourseModel course) {
    setState(() => _selectedCourse = course);

    final service = ref.read(adminServiceProvider);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarksheetEditorScreen(
          courseId: course.id,
          subjectName: course.subjectName,
          courseTerm: course.term,
          getCourseStudents: (courseId) => service.getCourseStudents(courseId),
          getMarksheetsByCourse: (courseId) =>
              service.getAdminMarksheetsByCourse(courseId),
          bulkUpload: service.adminBulkUploadMarksheets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Override Marksheet')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a course to view or edit its marksheets',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  CoursePickerField(
                    courses: _courses,
                    selected: _selectedCourse,
                    onSelected: _onCourseSelected,
                  ),
                ],
              ),
            ),
    );
  }
}
