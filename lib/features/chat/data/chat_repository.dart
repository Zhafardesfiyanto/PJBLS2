import '../domain/message_model.dart';

/// Abstract repository for chat operations
abstract class ChatRepository {
  /// Watch class messages
  Stream<List<MessageModel>> watchClassMessages(String classId);

  /// Watch assignment messages
  Stream<List<MessageModel>> watchAssignmentMessages(String assignmentId);

  /// Send message
  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String chatContext, // classId atau assignmentId
    required ChatType type,
  });

  /// Delete message
  Future<void> deleteMessage(String messageId, String chatContext, ChatType type);
}