import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
    _messages.add({
      'role': 'model',
      'text': '¡Hola! Soy tu asistente de bienestar. ¿En qué puedo ayudarte hoy?',
    });
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

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
        _messages.add({
          'role': 'model',
          'text': 'Lo siento, ha ocurrido un error. Por favor, intenta de nuevo.'
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  // ¡¡¡FUNCIÓN CORREGIDA!!!
  // Llama a la Cloud Function 'callGeminiApi' y procesa la respuesta JSON
  Future<String> _getGeminiResponse(String userMessage) async {
    // Solo enviamos el mensaje del usuario, ya que el prompt del sistema
    // está configurado directamente en el código de la Cloud Function en Python.
    final prompt = userMessage;

    try {
      // Llama a la función invocable
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('callGeminiApi');

      // Envía el prompt y espera un Mapa (JSON) como respuesta
      final result = await callable.call<Map<String, dynamic>>(
        <String, dynamic>{'prompt': prompt},
      );

      // EXTRAE EL TEXTO DE LA RESPUESTA JSON
      // result.data es ahora un Mapa, y accedemos a la clave 'text'.
      return result.data['text'] ?? 'No se recibió una respuesta válida.';
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          'Error al llamar a la función Cloud: ${e.code} - ${e.message}');
      return 'Lo siento, el asistente no está disponible en este momento. (Error: ${e.code})';
    } catch (e) {
      debugPrint('Error inesperado al llamar a la función: $e');
      return 'Lo siento, ha ocurrido un error inesperado.';
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
          if (_isLoading)
            const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator()),
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
          color: isUserMessage
              ? Theme.of(context).primaryColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style:
              TextStyle(color: isUserMessage ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}