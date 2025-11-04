import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class InAppMessage {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionTitle;
  final String? actionUrl;
  final Map<String, String>? customData;
  final DateTime createdAt;
  final String? createdBy;
  final bool isRead;

  InAppMessage({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionTitle,
    this.actionUrl,
    this.customData,
    required this.createdAt,
    this.createdBy,
    required this.isRead,
  });

  factory InAppMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else {
        createdAt = DateTime.now();
      }
    } else if (data['createdAtFallback'] != null) {
      try {
        createdAt = DateTime.parse(data['createdAtFallback']);
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
      debugPrint(
          'Warning: createdAt is null for message ${doc.id}, using current time');
    }

    return InAppMessage(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      actionTitle: data['actionTitle'],
      actionUrl: data['actionUrl'],
      customData: data['customData'] != null
          ? Map<String, String>.from(data['customData'])
          : null,
      createdAt: createdAt,
      createdBy: data['createdBy'],
      isRead: data['isRead'] ?? false,
    );
  }

  InAppMessage copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? actionTitle,
    String? actionUrl,
    Map<String, String>? customData,
    DateTime? createdAt,
    String? createdBy,
    bool? isRead,
  }) {
    return InAppMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      actionTitle: actionTitle ?? this.actionTitle,
      actionUrl: actionUrl ?? this.actionUrl,
      customData: customData ?? this.customData,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'InAppMessage{id: $id, title: $title, body: $body, isRead: $isRead}';
  }
}
