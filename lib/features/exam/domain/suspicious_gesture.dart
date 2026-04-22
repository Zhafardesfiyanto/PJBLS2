import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for suspicious gestures during exam mode
class SuspiciousGesture {
  final String type; // 'swipe_out' | 'screenshot' | 'app_switch' | 'notification_panel'
  final DateTime timestamp;

  const SuspiciousGesture({
    required this.type,
    required this.timestamp,
  });

  /// Create SuspiciousGesture from Firestore map
  factory SuspiciousGesture.fromFirestore(Map<String, dynamic> data) {
    return SuspiciousGesture(
      type: data['type'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Convert SuspiciousGesture to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Create a copy with updated fields
  SuspiciousGesture copyWith({
    String? type,
    DateTime? timestamp,
  }) {
    return SuspiciousGesture(
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuspiciousGesture &&
        other.type == type &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return type.hashCode ^ timestamp.hashCode;
  }

  @override
  String toString() {
    return 'SuspiciousGesture(type: $type, timestamp: $timestamp)';
  }
}