import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Mock notifications
  final List<_NotificationItem> _notifications = const [
    _NotificationItem(
      icon: Icons.assignment_turned_in,
      title: 'New Exam Added',
      description: 'Data Structures exam has been added for Computer Science.',
      time: '2 min ago',
    ),
    _NotificationItem(
      icon: Icons.lock_open,
      title: 'Course Unlocked',
      description: 'Algorithms course is now unlocked. Start preparing!',
      time: '1 hour ago',
    ),
    _NotificationItem(
      icon: Icons.tips_and_updates,
      title: 'Study Tip',
      description: 'Practice 10 questions daily to improve retention.',
      time: '3 hours ago',
    ),
    _NotificationItem(
      icon: Icons.emoji_events,
      title: 'Achievement',
      description: 'You completed 5 exams – great job!',
      time: 'Yesterday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGradientStart.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.primaryGradientStart,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.time,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String description;
  final String time;
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  });
}