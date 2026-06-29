import 'package:client/shared/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/student/screens/student_dashboard_screen.dart';
import '../storage/secure_storage.dart';
import '../../shared/screens/pdf_viewer_screen.dart';
// import '../constants/app_constants.dart';

class AppRouter {
  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String adminDashboard = '/admin';
  static const String teacherDashboard = '/teacher';
  static const String studentDashboard = '/student';

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final token = await SecureStorage.getToken();
      final isLoginPage = state.matchedLocation == login;

      // Not logged in — send to login
      if (token == null && !isLoginPage) return login;

      // Already logged in — don't show login page again
      if (token != null && isLoginPage) {
        final userJson = await SecureStorage.getUser();
        if (userJson != null) {
          // Route based on role
          if (userJson.contains('"role":"admin"')) return adminDashboard;
          if (userJson.contains('"role":"teacher"')) return teacherDashboard;
          return studentDashboard;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: teacherDashboard,
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: studentDashboard,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return PDFViewerScreen(
            fileUrl: params['url'] ?? '',
            title: params['title'] ?? 'Document',
            fileType: params['type'] ?? 'pdf',
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}
