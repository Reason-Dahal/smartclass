import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AttendanceStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const AttendanceStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
