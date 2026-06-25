import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/admin_models.dart';

class UserCard extends StatelessWidget {
  final AdminUserModel user;
  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.infoLight,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: user.status == 'active'
                ? AppColors.successLight
                : AppColors.dangerLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.status,
            style: TextStyle(
              color: user.status == 'active'
                  ? AppColors.success
                  : AppColors.danger,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
