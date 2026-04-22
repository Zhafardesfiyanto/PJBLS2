import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for chat types
enum ChatType { class_, assignment }

/// Message model for chat functionality
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final bool isDeleted;
  final DateTime sentAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.isDeleted,
    required this.sentAt,
  });

  /// Create MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      content: data['content'] ?? '',
      isDeleted: data['isDeleted'] ?? false,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
    );
  }

  /// Convert MessageModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'isDeleted': isDeleted,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  /// Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    bool? isDeleted,
    DateTime? sentAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      isDeleted: isDeleted ?? this.isDeleted,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel &&
        other.id == id &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.senderPhotoUrl == senderPhotoUrl &&
        other.content == content &&
        other.isDeleted == isDeleted &&
        other.sentAt == sentAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        senderName.hashCode ^
        senderPhotoUrl.hashCode ^
        content.hashCode ^
        isDeleted.hashCode ^
        sentAt.hashCode;
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, senderName: $senderName, senderPhotoUrl: $senderPhotoUrl, content: $content, isDeleted: $isDeleted, sentAt: $sentAt)';
  }
}