import 'package:flutter/material.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/notifications/services/notification_service.dart';
import 'package:styleiq/models/notification.dart' as app_notification;

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  static const String _userId = 'guest';
  final NotificationService _notificationService = NotificationService();

  late Future<List<app_notification.Notification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notificationsFuture = _notificationService.getNotifications(_userId);
  }

  Future<void> _refresh() async {
    _loadNotifications();
    setState(() {});
    // trigger future to refresh
    await _notificationsFuture;
  }

  Future<void> _ensureDemoContent() async {
    final list = await _notificationService.getNotifications(_userId);
    if (list.isEmpty) {
      await _notificationService.createDemoNotification(_userId);
      await _notificationService.addNotification(
        _userId,
        app_notification.Notification(
          userId: _userId,
          title: 'Analysis Complete',
          message: 'Your uploaded outfit has been scored. Check your history for details.',
          type: 'analysis',
          category: 'style',
        ),
      );
      _loadNotifications();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: () async {
              await _notificationService.markAllAsRead(_userId);
              _refresh();
            },
            tooltip: 'Mark all read',
          ),
        ],
      ),
      body: FutureBuilder<List<app_notification.Notification>>(
        future: _notificationsFuture.then((value) async {
          if (value.isEmpty) {
            await _ensureDemoContent();
            return _notificationService.getNotifications(_userId);
          }
          return value;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load notifications: ${snapshot.error}'));
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet. Your updates will appear here.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final note = notifications[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Icon(
                      note.isUnread ? Icons.circle_notifications : Icons.notifications_none,
                      color: note.isUnread ? AppTheme.coral : AppTheme.mediumGrey,
                    ),
                    title: Text(note.title),
                    subtitle: Text(note.message),
                    trailing: note.isUnread
                        ? TextButton(
                            onPressed: () async {
                              await _notificationService.markAsRead(_userId, note.id);
                              _refresh();
                            },
                            child: const Text('Mark read'))
                        : const Icon(Icons.check, color: AppTheme.accentMain),
                    onTap: () async {
                      if (note.isUnread) {
                        await _notificationService.markAsRead(_userId, note.id);
                        _refresh();
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
