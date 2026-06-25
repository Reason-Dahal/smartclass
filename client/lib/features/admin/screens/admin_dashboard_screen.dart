import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/app_router.dart';
import '../../../core/storage/secure_storage.dart';
import 'sections/admin_home_section.dart';
import 'sections/admin_teachers_section.dart';
import 'sections/admin_students_section.dart';
import 'sections/admin_programs_section.dart';
import 'sections/admin_reports_section.dart';

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

  Future<void> _logout() async {
    await SecureStorage.clearAll();
    if (mounted) context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sectionTitle()),
        leading: _currentSection != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentSection = 0),
              )
            : null,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildSection(),
    );
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
      default:
        return AdminHomeSection(
          userName: _userName,
          onNavigate: (index) => setState(() => _currentSection = index),
        );
    }
  }
}
