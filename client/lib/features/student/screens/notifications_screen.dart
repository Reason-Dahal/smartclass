import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/student_providers.dart';
import '../widgets/notification_card.dart';
import '../widgets/empty_state.dart';
import 'package:client/shared/widgets/loading_widget.dart';
import 'package:client/shared/widgets/error_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(studentNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notifications.whenOrNull(
                data: (list) => list.any((n) => !n.isRead)
                    ? TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(studentServiceProvider)
                                .markAllNotificationsRead();
                            ref.invalidate(studentNotificationsProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notifications.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              message: 'No notifications yet',
              icon: Icons.notifications_none,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentNotificationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final n = list[index];
                return NotificationCard(
                  notification: n,
                  onTap: () async {
                    if (!n.isRead) {
                      try {
                        await ref
                            .read(studentServiceProvider)
                            .markNotificationRead(n.id);
                        ref.invalidate(studentNotificationsProvider);
                      } catch (_) {
                        // Non-critical — tapping still works even if the
                        // mark-as-read call fails silently in the background
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading notifications...'),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(studentNotificationsProvider),
        ),
      ),
    );
  }
}
