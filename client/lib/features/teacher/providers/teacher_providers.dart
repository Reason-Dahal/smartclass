import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/teacher_service.dart';
import '../models/teacher_models.dart';

final teacherServiceProvider = Provider((ref) => TeacherService());

final teacherCoursesProvider = FutureProvider<List<TeacherCourseModel>>((
  ref,
) async {
  return ref.read(teacherServiceProvider).getMyCourses();
});

final teacherShortcutsProvider = FutureProvider<List<TeacherCourseModel>>((
  ref,
) async {
  return ref.read(teacherServiceProvider).getMyShortcuts();
});

final selectedCourseProvider = StateProvider<TeacherCourseModel?>(
  (ref) => null,
);
