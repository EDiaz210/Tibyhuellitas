import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String sender; // 'user' o 'assistant'
  final String message;
  final String? petContext;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.sender,
    required this.message,
    this.petContext,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      userId: json['user_id'],
      sender: json['sender'],
      message: json['message'],
      petContext: json['pet_context'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'sender': sender,
    'message': message,
    'pet_context': petContext,
  };
}

abstract class ChatRepository {
  Future<void> saveMessage(ChatMessage message);
  Future<List<ChatMessage>> getConversationHistory(String userId, {int limit = 50});
  Future<void> deleteMessage(String messageId);
  Future<void> clearConversation(String userId);
}

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient supabase;

  ChatRepositoryImpl({required this.supabase});

  @override
  Future<void> saveMessage(ChatMessage message) async {
    try {
      await supabase.from('chat_messages').insert(message.toJson());
    } catch (e) {
      print('Error saving chat message: $e');
      throw Exception('No se pudo guardar el mensaje: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getConversationHistory(String userId, {int limit = 50}) async {
    try {
      final response = await supabase
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(limit);

      return (response as List)
          .map((item) => ChatMessage.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching chat history: $e');
      return [];
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await supabase
          .from('chat_messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  @override
  Future<void> clearConversation(String userId) async {
    try {
      await supabase
          .from('chat_messages')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing conversation: $e');
    }
  }
}
