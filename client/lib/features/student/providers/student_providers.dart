import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/student_service.dart';
import '../models/student_models.dart';

final studentServiceProvider = Provider((ref) => StudentService());

final studentAttendanceProvider = FutureProvider<List<AttendanceSummary>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyAttendance();
});

final studentAssignmentsProvider = FutureProvider<List<AssignmentModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyAssignments();
});

final studentNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  return ref.read(studentServiceProvider).getMyNotes();
});

final studentMarksheetsProvider = FutureProvider<List<MarksheetModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyMarksheets();
});

final studentCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  return ref.read(studentServiceProvider).getMyCourses();
});

final studentNotificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyNotifications();
});
