import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/repositories/chat_repository.dart';

class PetCareAssistantWidget extends StatefulWidget {
  final GeminiService geminiService;
  final String? petContext;

  const PetCareAssistantWidget({
    Key? key,
    required this.geminiService,
    this.petContext,
  }) : super(key: key);

  @override
  State<PetCareAssistantWidget> createState() =>
      _PetCareAssistantWidgetState();
}

class _PetCareAssistantWidgetState extends State<PetCareAssistantWidget> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late String _userId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Obtener userId del usuario autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _userId = user.id;
        
        // Cargar historial previo
        final history = await widget.geminiService.getConversationHistory(_userId);
        
        setState(() {
          if (history.isEmpty) {
            // Welcome message solo si no hay historial
            _messages.add(ChatMessage(
              text: '¡Hola! 👋 Soy el Asistente TIBYHUELLITAS.\n\n¿En qué puedo ayudarte hoy?',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          } else {
            // Cargar historial desde BD
            for (var msg in history) {
              _messages.add(ChatMessage(
                text: msg.message,
                isUser: msg.sender == 'user',
                timestamp: msg.createdAt,
              ));
            }
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: '¡Hola! 👋 Soy el Asistente TIBYHUELLITAS.\n\n¿En qué puedo ayudarte hoy?',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Guardar mensaje del usuario en BD
      await _saveChatMessage(_userId, 'user', message);

      final response = await widget.geminiService.chat(
        message,
        context: widget.petContext,
      );

      final assistantMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Guardar respuesta de la IA en BD
      await _saveChatMessage(_userId, 'assistant', response);

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveChatMessage(String userId, String sender, String message) async {
    try {
      final chatMsg = ChatMessage(
        id: '',
        userId: userId,
        text: message,
        isUser: sender == 'user',
        timestamp: DateTime.now(),
        sender: sender,
      );
      
      final supabase = Supabase.instance.client;
      await supabase.from('chat_messages').insert(chatMsg.toJson());
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _messageController.clear();
        setState(() => _messages.clear());
        await _initializeChat();
      },
      child: Column(
        children: [
        // Chat messages
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pets,
                        size: 80,
                        color: const Color(0xFF1ABC9C).withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '¡Hola! 👋',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Soy tu asistente de mascotas.\n¿En qué puedo ayudarte?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _ChatBubble(message: message);
                  },
                ),
        ),
        
        // Loading indicator
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[500]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Escribiendo...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Input field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu pregunta...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6B35),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  enabled: !_isLoading,
                  onSubmitted: _sendMessage,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => _sendMessage(_messageController.text),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

class ChatMessage {
  final String? id;
  final String? userId;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String sender;

  ChatMessage({
    this.id,
    this.userId,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    String? sender,
  }) : sender = sender ?? (isUser ? 'user' : 'assistant');

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'sender': sender,
    'message': text,
  };
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: message.isUser
                  ? const Color(0xFFFF6B35)
                  : (message.isError
                      ? Colors.red[50]
                      : Colors.grey[100]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: message.isUser
                        ? Colors.white
                        : (message.isError
                            ? Colors.red[800]
                            : Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: message.isUser
                        ? Colors.white.withOpacity(0.7)
                        : (message.isError
                            ? Colors.red[600]?.withOpacity(0.7)
                            : Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
