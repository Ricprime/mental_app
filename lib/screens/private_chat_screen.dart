// import 'dart:convert'; // Ya no es necesario si solo usas cloud_functions para llamadas a API
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // Ya no es necesario para la llamada a Gemini
import 'package:cloud_functions/cloud_functions.dart'; // ¡IMPORTANTE! Nuevo import para Cloud Functions

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({super.key});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Añade el mensaje de bienvenida inicial del asistente
    _messages.add(const { // Añadido const
      'role': 'model',
      'text': '¡Hola! Soy tu asistente de bienestar. ¿En qué puedo ayudarte hoy?',
    });
  }

  // Función para enviar el mensaje y obtener respuesta de Gemini
  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) {
      return;
    }

    final userMessage = _textController.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': userMessage});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _getGeminiResponse(userMessage);
      setState(() {
        _messages.add({'role': 'model', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.add(const {'role': 'model', 'text': 'Lo siento, ha ocurrido un error. Por favor, intenta de nuevo.'}); // Añadido const
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Llama a la Cloud Function 'callGeminiApi'
  Future<String> _getGeminiResponse(String userMessage) async {
    const systemPrompt = "Eres un asistente de bienestar personal, amigable y empático llamado MentalApp Assistant. Tu objetivo es escuchar, ofrecer apoyo y guiar al usuario en su reflexión. No des consejos médicos. Mantén las respuestas concisas y conversacionales.";
    final fullPrompt = "$systemPrompt\n\nMensaje del usuario: $userMessage";

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('callGeminiApi');

      final result = await callable.call<String>(
        <String, dynamic>{'prompt': fullPrompt},
      );

      // result.data ya es un String si la función Cloud devuelve texto plano,
      // la aserción '!' ya no es necesaria aquí.
      return result.data; // Eliminado '!'
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Error al llamar a la función Cloud: ${e.code} - ${e.message} - ${e.details}');
      throw Exception('Error al conectar con el asistente. Por favor, intenta de nuevo más tarde.');
    } catch (e) {
      debugPrint('Error inesperado al llamar a la función: $e');
      throw Exception('Ha ocurrido un error inesperado. Por favor, intenta de nuevo.');
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente Personal')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUserMessage = message['role'] == 'user';
                return _ChatBubble(
                  text: message['text']!,
                  isUserMessage: isUserMessage,
                );
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}


class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  const _ChatBubble({required this.text, required this.isUserMessage});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUserMessage ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUserMessage ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}