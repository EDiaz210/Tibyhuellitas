import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:tibyhuellitas/core/error/exceptions.dart' as custom;
import 'package:tibyhuellitas/core/repositories/chat_repository.dart';

abstract class GeminiService {
  Future<String> chat(String message, {String? context});
  Stream<String> streamChat(String message, {String? context});
  Future<List<ChatMessage>> getConversationHistory(String userId);
  Future<void> clearConversation(String userId);
}

class GeminiServiceImpl implements GeminiService {
  final String apiKey;
  final ChatRepository chatRepository;
  final String? userId;
  
  late final GenerativeModel _model;
  late ChatSession _chatSession;
  
  final String _systemPrompt = '''Eres el Asistente TIBYHUELLITAS, un ayudante amigable especializado en cuidado de mascotas y adopción.
Tu misión es ayudar a adoptantes y refugios a:
- Responder preguntas sobre salud, nutrición y comportamiento de mascotas
- Dar consejos sobre cuidados básicos de perros, gatos y otros animales
- Aconsejar sobre el proceso de adopción y responsabilidad de las mascotas
- Proporcionar información sobre diferentes razas y sus características
- Dar recomendaciones para integrar una mascota a un hogar

Siempre:
- Sé empático, comprensivo y entusiasta
- Responde siempre en español
- Proporciona consejos prácticos y seguros
- Si la pregunta es grave sobre salud, recomienda ver a un veterinario
- Sé conciso pero informativo
- Usa emojis ocasionalmente para ser más amigable''';

  GeminiServiceImpl({
    required this.apiKey,
    required this.chatRepository,
    this.userId,
  }) {
    _initializeModel();
  }

  void _initializeModel() {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );
      _initializeChat();
    } catch (e) {
      print('Error initializing Gemini model: $e');
    }
  }

  void _initializeChat() {
    try {
      _chatSession = _model.startChat(
        history: [
          Content.text(_systemPrompt),
          Content.model([TextPart('Entendido. Soy el Asistente TIBYHUELLITAS. ¿En qué te puedo ayudar?')]),
        ],
      );
    } catch (e) {
      print('Error initializing chat session: $e');
    }
  }

  @override
  Future<String> chat(String message, {String? context}) async {
    try {
      if (apiKey.isEmpty) {
        throw custom.ServerException(
          message: 'Clave API de Gemini no configurada',
        );
      }

      // Ensure chat session is initialized
      if (_chatSession == null) {
        _initializeChat();
      }

      final userMessage = context != null
          ? '$message\n\n(Contexto de mascota: $context)'
          : message;

      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );

      if (response.text == null || response.text!.isEmpty) {
        throw custom.ServerException(message: 'Respuesta vacía de Gemini');
      }

      return response.text!;
    } on custom.ServerException {
      rethrow;
    } catch (e) {
      print('Error in Gemini chat: $e');
      throw custom.ServerException(message: 'Error al comunicarse con la IA: ${e.toString()}');
    }
  }

  @override
  Stream<String> streamChat(String message, {String? context}) async* {
    try {
      if (apiKey.isEmpty) {
        throw custom.ServerException(
          message: 'Clave API de Gemini no configurada.',
        );
      }

      final userMessage = context != null
          ? '$message\n\n(Contexto de mascota: $context)'
          : message;

      yield* _chatSession
          .sendMessageStream(Content.text(userMessage))
          .map((response) => response.text ?? '');
    } catch (e) {
      print('Error in Gemini stream chat: $e');
      throw custom.ServerException(message: 'Error en streaming: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getConversationHistory(String userId) async {
    try {
      return await chatRepository.getConversationHistory(userId);
    } catch (e) {
      print('Error loading conversation history: $e');
      return [];
    }
  }

  @override
  Future<void> clearConversation(String userId) async {
    try {
      await chatRepository.clearConversation(userId);
    } catch (e) {
      print('Error clearing conversation: $e');
    }
  }

  Future<void> _saveMessage(String userId, String sender, String message) async {
    try {
      final chatMessage = ChatMessage(
        id: '',
        userId: userId,
        sender: sender,
        message: message,
        createdAt: DateTime.now(),
      );
      await chatRepository.saveMessage(chatMessage);
    } catch (e) {
      print('Error saving message to database: $e');
    }
  }
}
