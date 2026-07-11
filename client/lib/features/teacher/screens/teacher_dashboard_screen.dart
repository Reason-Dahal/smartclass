import 'package:client/shared/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage.dart';
import 'tabs/teacher_home_tab.dart';
import 'tabs/teacher_courses_tab.dart';
import 'tabs/teacher_grading_tab.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  int _currentIndex = 0;
  String _userName = '';

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
    final tabs = [
      TeacherHomeTab(
        userName: _userName,
        onNavigateToCourses: () => setState(() => _currentIndex = 1),
      ),
      const TeacherCoursesTab(),
      const TeacherGradingTab(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentIndex == 0
                ? AppConstants.appName
                : _tabTitle(_currentIndex),
          ),
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
        body: tabs[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grading_outlined),
              activeIcon: Icon(Icons.grading),
              label: 'Grading',
            ),
          ],
        ),
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

  String _tabTitle(int index) {
    switch (index) {
      case 1:
        return 'My Courses';
      case 2:
        return 'Grading';
      default:
        return AppConstants.appName;
    }
  }
}
