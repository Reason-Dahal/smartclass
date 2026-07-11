import 'package:client/shared/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage.dart';
import 'sections/admin_home_section.dart';
import 'sections/admin_teachers_section.dart';
import 'sections/admin_students_section.dart';
import 'sections/admin_programs_section.dart';
import 'sections/admin_reports_section.dart';
import 'sections/admin_courses_section.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _userName = '';
  int _currentSection = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userJson = await SecureStorage.getUser();
    if (userJson != null && mounted) {
      final user = jsonDecode(userJson);
      setState(() => _userName = user['name'] ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentSection != 0) {
          setState(() => _currentSection = 0);
        } else {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_sectionTitle()),
          leading: _currentSection != 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _currentSection = 0),
                )
              : null,
          actions: [
            // Profile icon — pushes profile screen on top
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ],
        ),
        body: _buildSection(),
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit SmartClass?'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true && context.mounted) {
      SystemNavigator.pop();
    }
  }

  String _sectionTitle() {
    switch (_currentSection) {
      case 1:
        return 'Teachers';
      case 2:
        return 'Students';
      case 3:
        return 'Programs & Batches';
      case 4:
        return 'Reports';
      case 5:
        return 'Courses';
      default:
        return AppConstants.appName;
    }
  }

  Widget _buildSection() {
    switch (_currentSection) {
      case 1:
        return const AdminTeachersSection();
      case 2:
        return const AdminStudentsSection();
      case 3:
        return const AdminProgramsSection();
      case 4:
        return const AdminReportsSection();
      case 5:
        return const AdminCoursesSection();
      default:
        return AdminHomeSection(
          userName: _userName,
          onNavigate: (index) => setState(() => _currentSection = index),
        );
    }
  }
}
