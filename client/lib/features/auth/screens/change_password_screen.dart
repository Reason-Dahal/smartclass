import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_router.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_service.dart';
import 'dart:convert';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _authService = AuthService();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      // Update mustChangePassword in stored user data
      final userJson = await SecureStorage.getUser();
      if (userJson != null) {
        final user = jsonDecode(userJson) as Map<String, dynamic>;
        user['mustChangePassword'] = false;
        await SecureStorage.saveUser(jsonEncode(user));

        // Route to correct dashboard based on role
        final role = user['role'] as String;
        switch (role) {
          case AppConstants.roleAdmin:
            context.go(AppRouter.adminDashboard);
            break;
          case AppConstants.roleTeacher:
            context.go(AppRouter.teacherDashboard);
            break;
          default:
            context.go(AppRouter.studentDashboard);
        }
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Icon(
                      Icons.lock_reset,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Change your password',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your account requires a password change before continuing.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Current password
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // New password
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                          return 'Must contain at least one uppercase letter';
                        }
                        if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                          return 'Must contain at least one number';
                        }
                        if (!RegExp(
                          r'[!@#$%^&*(),.?":{}|<>]',
                        ).hasMatch(value)) {
                          return 'Must contain at least one special character';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _changePassword,
                            child: const Text('Change password'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
