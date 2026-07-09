import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/student_service.dart';
import '../models/student_models.dart';

final studentServiceProvider = Provider((ref) => StudentService());

// ─── ATTENDANCE ──────────────────────────────────────────────────────────────

final studentAttendanceProvider = FutureProvider<List<AttendanceSummary>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyAttendance();
});

// ─── ASSIGNMENTS ─────────────────────────────────────────────────────────────

// V2 — grouped by subject, current term only
final studentAssignmentsGroupedProvider =
    FutureProvider<List<AssignmentGroupModel>>((ref) async {
      return ref.read(studentServiceProvider).getMyAssignmentsGrouped();
    });

// ─── NOTES ───────────────────────────────────────────────────────────────────

// V2 — grouped by subject with term filter
final studentNotesGroupedProvider = FutureProvider.family<NotesResponse, int>((
  ref,
  term,
) async {
  return ref.read(studentServiceProvider).getMyNotes(term: term);
});

// ─── MARKSHEETS ──────────────────────────────────────────────────────────────

// All marksheets — used to get available terms list
final studentMarksheetsProvider = FutureProvider<List<MarksheetModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyMarksheets();
});

// Marksheets filtered by term — used in terminal results table
final studentMarksheetsByTermProvider =
    FutureProvider.family<List<MarksheetModel>, int>((ref, term) async {
      return ref.read(studentServiceProvider).getMyMarksheets(term: term);
    });

// Selected term state for marks tab
final selectedMarksTermProvider = StateProvider<int>((ref) => 1);

// ─── FINAL RESULTS ───────────────────────────────────────────────────────────

final studentFinalResultsProvider = FutureProvider<List<FinalResultModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyFinalResults();
});

// ─── COURSES ─────────────────────────────────────────────────────────────────

final studentCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  return ref.read(studentServiceProvider).getMyCourses();
});

// ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

final studentNotificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  return ref.read(studentServiceProvider).getMyNotifications();
});
