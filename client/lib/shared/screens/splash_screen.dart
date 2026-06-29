import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Fire-and-forget health ping — wakes up Render server
    // We don't await or care about the result
    _pingServer();

    // Wait 2 seconds minimum for branding visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is already logged in
    final token = await SecureStorage.getToken();
    final userJson = await SecureStorage.getUser();

    if (!mounted) return;

    if (token == null || userJson == null) {
      context.go('/login');
      return;
    }

    // Navigate based on role
    if (userJson.contains('"role":"admin"')) {
      context.go('/admin');
    } else if (userJson.contains('"role":"teacher"')) {
      context.go('/teacher');
    } else {
      context.go('/student');
    }
  }

  Future<void> _pingServer() async {
    try {
      await DioClient.instance.get('/health');
    } catch (_) {
      // Ignore all errors — ping is fire and forget
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/app_icon.png', width: 120, height: 120),
            const SizedBox(height: 24),
            const Text(
              'SmartClass',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4E79),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Academic Management System',
              style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1F4E79),
            ),
          ],
        ),
      ),
    );
  }
}
