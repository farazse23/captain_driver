import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _markAsRead(String notificationId) async {
    print('NotificationScreen: Attempting to mark as read: $notificationId');
    await _notificationService.markAsRead(notificationId);
    print('NotificationScreen: markAsRead call completed for: $notificationId');
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'assignment':
      case 'trip_assignment':
        return FontAwesomeIcons.clipboard;
      case 'trip':
        return FontAwesomeIcons.car;
      case 'admin_message':
        return FontAwesomeIcons.truck; // Use truck icon for admin messages
      case 'payment':
        return FontAwesomeIcons.dollarSign;
      case 'alert':
        return FontAwesomeIcons.exclamationTriangle;
      case 'message':
        return FontAwesomeIcons.message;
      default:
        return FontAwesomeIcons.truck; // Default to truck icon
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'assignment':
        return Colors.blue;
      case 'trip':
        return Colors.green;
      case 'payment':
        return Colors.orange;
      case 'alert':
        return Colors.red;
      case 'message':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top image and header with animation
            Stack(
              children: [
                FadeSlideAnimation(
                  duration: const Duration(milliseconds: 1000),
                  beginOffset: const Offset(0, 0.3),
                  curve: Curves.linear,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: Image.asset(
                      'assets/images/DashBoard.jpg',
                      width: double.infinity,
                      height: size.height * 0.34,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: size.height * 0.20,
                  child: FadeSlideAnimation(
                    duration: const Duration(milliseconds: 1000),
                    beginOffset: const Offset(-0.6, 0),
                    curve: Curves.easeOut,
                    child: StreamBuilder<List<NotificationModel>>(
                      stream: _notificationService.getNotificationsStream(),
                      builder: (context, snapshot) {
                        final notificationCount = snapshot.data?.length ?? 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.bell,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$notificationCount notification${notificationCount != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<List<NotificationModel>>(
                stream: _notificationService.getNotificationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.exclamationTriangle,
                            size: 80,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Error loading notifications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return FadeSlideAnimation(
                        duration: Duration(milliseconds: 600 + index * 100),
                        beginOffset: const Offset(0, 0.2),
                        curve: Curves.easeOut,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: notification.isRead ? 2 : 4,
                            color: notification.isRead
                                ? Colors.white
                                : const Color(0xFFFFF8E1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: notification.isRead
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 1,
                                    ),
                            ),
                            child: Dismissible(
                              key: Key(notification.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                _notificationService.deleteNotification(
                                  notification.id,
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  FontAwesomeIcons.trash,
                                  color: Colors.white,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                onTap: () {
                                  // Mark as read when tapped
                                  if (!notification.isRead) {
                                    _markAsRead(notification.id);
                                  }

                                  // Navigate to assigned trips if it's a trip-related notification
                                  if (notification.type == 'trip_assignment' ||
                                      notification.type == 'assignment' ||
                                      notification.type == 'trip') {
                                    Navigator.pushNamed(
                                      context,
                                      '/assigned_trip',
                                    );
                                  }
                                },
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getIconColor(
                                      notification.type,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getIcon(notification.type),
                                    color: _getIconColor(notification.type),
                                    size: 24,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontWeight: notification.isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      notification.message,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatTimestamp(notification.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
