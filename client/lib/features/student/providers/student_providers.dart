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

// Final results — list of published result files for student's program
final studentFinalResultsProvider = FutureProvider<List<FinalResultModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyFinalResults();
});

// Marksheets by term — parameterised
final studentMarksheetsByTermProvider =
    FutureProvider.family<List<MarksheetModel>, int>((ref, term) async {
      return ref.read(studentServiceProvider).getMyMarksheets(term: term);
    });

// Selected term state for marks tab
final selectedMarksTermProvider = StateProvider<int>((ref) => 1);

final studentCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  return ref.read(studentServiceProvider).getMyCourses();
});

final studentNotificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyNotifications();
});
