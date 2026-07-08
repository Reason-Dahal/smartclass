import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_service.dart';
import '../models/admin_models.dart';

final adminServiceProvider = Provider((ref) => AdminService());

final adminTeachersProvider = FutureProvider<List<AdminUserModel>>((ref) async {
  return ref.read(adminServiceProvider).getTeachers();
});

final adminStudentsProvider = FutureProvider<List<AdminUserModel>>((ref) async {
  return ref.read(adminServiceProvider).getStudents();
});

final adminProgramsProvider = FutureProvider<List<ProgramModel>>((ref) async {
  return ref.read(adminServiceProvider).getPrograms();
});

final adminBatchesProvider = FutureProvider<List<BatchModel>>((ref) async {
  return ref.read(adminServiceProvider).getAllBatches();
});

final adminReportsProvider = FutureProvider<SystemReportModel>((ref) async {
  return ref.read(adminServiceProvider).getReports();
});

final adminCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  return ref.read(adminServiceProvider).getCourses();
});

final evaluationConfigProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return ref.read(adminServiceProvider).getEvaluationConfig();
});
