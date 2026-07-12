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
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verify_otp_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import 'dart:convert';
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
      final location = state.matchedLocation;

      // Public routes — no auth required
      final publicRoutes = [
        login,
        '/forgot-password',
        '/verify-otp',
        '/reset-password',
      ];

      final isPublicRoute = publicRoutes.contains(location);

      // Not logged in — only allow public routes
      if (token == null && !isPublicRoute) return login;

      // Already logged in — don't show login or public routes
      if (token != null && isPublicRoute) {
        final userJson = await SecureStorage.getUser();
        if (userJson != null) {
          try {
            final user = jsonDecode(userJson) as Map<String, dynamic>;
            final role = user['role'] as String? ?? '';
            switch (role) {
              case 'admin':
                return adminDashboard;
              case 'teacher':
                return teacherDashboard;
              case 'student':
                return studentDashboard;
              default:
                return login; // unknown role — force re-login rather than guessing
            }
          } catch (_) {
            return login; // corrupted user data — force re-login
          }
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
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) =>
            VerifyOtpScreen(email: state.extra as String),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return ResetPasswordScreen(
            email: data['email'] ?? '',
            resetToken: data['resetToken'] ?? '',
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}
