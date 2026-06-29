import 'package:flutter/foundation.dart';

class ApiConstants {
  // static String get baseUrl {
  //   if (kIsWeb) return 'https://smartclass-f6nz.onrender.com/api/v1';
  //   return 'https://smartclass-f6nz.onrender.com/api/v1';
  // }
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    // For physical device — change this to your IP when it changes
    return 'http://192.168.1.16:5000/api/v1';
  }

  // Auth
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Admin — Users
  static const String teachers = '/admin/teachers';
  static const String students = '/admin/students';
  static const String userStatus = '/admin/users';
  static const String resetPassword = '/admin/users/reset-password';
  static const String enroll = '/admin/enroll';

  // Admin — Programs & Batches
  static const String programs = '/admin/programs';
  static const String batches = '/admin/programs/batches';

  // Courses
  static const String courses = '/courses';

  // Teacher
  static const String teacherCourses = '/courses/teacher/my-courses';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherAssignments = '/teacher/assignments';
  static const String teacherSubmissions = '/teacher/submissions';
  static const String teacherNotes = '/teacher/notes';
  static const String teacherCoursesBase = '/teacher/courses';

  // Student
  static const String studentAttendance = '/student/attendance';
  static const String studentAssignments = '/student/assignments';
  static const String studentNotes = '/student/notes';
  static const String studentMarksheets = '/student/marksheets';
  static const String studentFinalResults = '/student/final-results';
  static const String studentEvaluation = '/student/evaluation';
  static const String studentNotifications = '/student/notifications';
  static const String studentCourses = '/courses/student/my-courses';
  static const String studentElectives = '/courses/student/electives';
  static const String studentEnroll = '/courses/student/enroll';

  // Admin — Academic
  static const String finalResults = '/admin/final-results';
  static const String evaluationConfig = '/admin/evaluation-config';
  static const String reports = '/admin/reports';

  // Uploads
  static const String uploadSubmission = '/upload/submission';
  static const String uploadNote = '/upload/note';
}
