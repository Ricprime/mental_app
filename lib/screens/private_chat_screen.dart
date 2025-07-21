import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

// --- WIDGET PRINCIPAL DE LA PANTALLA DE CHAT ---
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
    // Mensaje de bienvenida inicial del asistente.
    _messages.add({
      'role': 'model',
      'text': '¡Hola! Soy tu asistente de bienestar. ¿En qué puedo ayudarte hoy?',
    });
  }

  // --- LÓGICA PARA ENVIAR UN MENSAJE ---
  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _textController.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': userMessage});
      _isLoading = true; // Bloquea el campo de entrada mientras se espera la respuesta.
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

  // Lógica para llamar a la Cloud Function (tu código original, que es correcto).
  Future<String> _getGeminiResponse(String userMessage) async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('callGeminiApi');
    try {
      final result = await callable.call<Map<String, dynamic>>(
        <String, dynamic>{'prompt': userMessage},
      );
      return result.data['text'] ?? 'No se recibió una respuesta válida.';
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Error Cloud Function: ${e.code} - ${e.message}');
      return 'Lo siento, el asistente no está disponible. (Error: ${e.code})';
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return 'Lo siento, ha ocurrido un error inesperado.';
    }
  }

  // Desplaza el scroll hasta el final de la lista.
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
    // Usamos los colores y fuentes de nuestro tema centralizado.
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Personal'),
        // Sombra sutil para dar profundidad cuando se hace scroll.
        scrolledUnderElevation: 1.0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0), // Añade espacio para el indicador de "escribiendo..."
              itemBuilder: (context, index) {
                // MEJORA UX: Muestra una burbuja de "escribiendo..." mientras se carga.
                if (index == _messages.length) {
                  return const _TypingIndicatorBubble();
                }

                final message = _messages[index];
                final isUserMessage = message['role'] == 'user';
                
                // MEJORA UI: El avatar solo se muestra junto a los mensajes del asistente.
                if (isUserMessage) {
                  return _ChatMessageBubble(
                    text: message['text']!,
                    isUserMessage: true,
                  );
                } else {
                  // Mensaje del Asistente con Avatar.
                  return _AssistantMessage(text: message['text']!);
                }
              },
            ),
          ),
          _buildInputField(theme),
        ],
      ),
    );
  }

  // --- WIDGET PARA EL CAMPO DE ENTRADA ---
  // Se ha mejorado el diseño para que coincida con el tema de la app.
  Widget _buildInputField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !_isLoading, // Deshabilita el campo mientras carga.
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: _isLoading ? 'Esperando respuesta...' : 'Escribe un mensaje...',
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              onPressed: _isLoading ? null : _sendMessage, // Deshabilita el botón mientras carga.
              style: IconButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET PARA EL MENSAJE COMPLETO DEL ASISTENTE (AVATAR + BURBUJA) ---
class _AssistantMessage extends StatelessWidget {
  final String text;
  const _AssistantMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/ai_avatar.jpg'), // <<< AQUÍ ESTÁ EL AVATAR
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ChatMessageBubble(
              text: text,
              isUserMessage: false,
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET PARA LA BURBUJA DE CHAT (REFACTORIZADO) ---
// Ahora es más limpio y se adapta al diseño.
class _ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  const _ChatMessageBubble({required this.text, required this.isUserMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isUserMessage ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUserMessage ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: isUserMessage ? const Radius.circular(0) : const Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isUserMessage ? Colors.white : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

// --- WIDGET INDICADOR DE "ESCRIBIENDO..." ---
class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: _AssistantMessage(text: "...") // Reutilizamos el widget del asistente
    );
  }
}