class ApiConstants {
  // Base URL — change this to your production URL when deploying
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';

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
  static const String teacherCourses = '/teacher/courses';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherAssignments = '/teacher/assignments';
  static const String teacherSubmissions = '/teacher/submissions';
  static const String teacherNotes = '/teacher/notes';

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
}
