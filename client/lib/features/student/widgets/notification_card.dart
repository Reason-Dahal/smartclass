import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/student_models.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _iconForType(notification.type),
          color: notification.isRead ? AppColors.textMuted : AppColors.primary,
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontSize: 13,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _formatDate(notification.createdAt),
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'note':
        return Icons.folder_outlined;
      case 'grade':
        return Icons.grade_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
