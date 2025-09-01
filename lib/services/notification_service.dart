import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _cachedDriverDocId;

  // Cached streams to prevent multiple listeners
  Stream<List<NotificationModel>>? _notificationsStream;
  Stream<int>? _unreadCountStream;

  Future<String?> _getDriverDocId() async {
    if (_cachedDriverDocId != null) return _cachedDriverDocId;
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Prefer matching by email (your drivers docs use email field)
      final q = await _firestore
          .collection('drivers')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        _cachedDriverDocId = q.docs.first.id;
        return _cachedDriverDocId;
      }
    } catch (_) {}

    return null;
  }

  // Get real-time stream of notifications for current driver
  Stream<List<NotificationModel>> getNotificationsStream() {
    if (_notificationsStream != null) {
      return _notificationsStream!;
    }

    _notificationsStream = _createNotificationsStream().asBroadcastStream();
    return _notificationsStream!;
  }

  Stream<List<NotificationModel>> _createNotificationsStream() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield <NotificationModel>[];
      return;
    }

    final driverDocId = await _getDriverDocId();
    if (driverDocId == null) {
      yield <NotificationModel>[];
      return;
    }

    yield* _firestore
        .collection('drivers')
        .doc(driverDocId)
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount() {
    if (_unreadCountStream != null) {
      return _unreadCountStream!;
    }

    _unreadCountStream = _createUnreadCountStream().asBroadcastStream();
    return _unreadCountStream!;
  }

  Stream<int> _createUnreadCountStream() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield 0;
      return;
    }

    final driverDocId = await _getDriverDocId();
    if (driverDocId == null) {
      yield 0;
      return;
    }

    // Listen to all notifications and count unread ones locally
    yield* _firestore
        .collection('drivers')
        .doc(driverDocId)
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          int unreadCount = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            // Check both possible read fields
            final isRead = data['isRead'] ?? false;
            final read = data['read'] ?? false;

            // If neither field is true, it's unread
            if (!isRead && !read) {
              unreadCount++;
            }
          }
          return unreadCount;
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final driverDocId = await _getDriverDocId();
      if (driverDocId == null) return;

      print('Marking notification as read: $notificationId');

      await _firestore
          .collection('drivers')
          .doc(driverDocId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'isRead': true,
            'read': true,
            'readAt':
                FieldValue.serverTimestamp(), // Add timestamp for debugging
          });

      print('Successfully marked notification as read: $notificationId');
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final driverDocId = await _getDriverDocId();
    if (driverDocId == null) return;
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('drivers')
        .doc(driverDocId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true, 'read': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final driverDocId = await _getDriverDocId();
      if (driverDocId == null) return;
      final docRef = _firestore
          .collection('drivers')
          .doc(driverDocId)
          .collection('notifications')
          .doc(notificationId);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      }
    } catch (e) {}
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final driverDocId = await _getDriverDocId();
    if (driverDocId == null) return;
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('drivers')
        .doc(driverDocId)
        .collection('notifications')
        .get();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Reset cached streams (call this when user changes or logs out)
  void resetStreams() {
    _notificationsStream = null;
    _unreadCountStream = null;
    _cachedDriverDocId = null;
  }
}
