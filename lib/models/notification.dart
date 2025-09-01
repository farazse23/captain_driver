import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final String senderId;
  final DateTime createdAt; // maps from 'timestamp' or 'createdAt'
  final bool isRead; // maps from 'read' or 'isRead'

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.priority,
    required this.senderId,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    final dynamic ts = map['timestamp'] ?? map['createdAt'];
    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is DateTime) {
      created = ts;
    } else if (ts is String) {
      created = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? map['body'] ?? '',
      type: map['type'] ?? '',
      createdAt: created,
      priority: map['priority'] ?? '',
      senderId: map['senderId'] ?? '',
      isRead: (map['isRead'] ?? map['read'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'senderId': senderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
