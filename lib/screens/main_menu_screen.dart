import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mental_app/screens/daily_mood_screen.dart';
import 'package:mental_app/screens/mood_history_screen.dart'; // Import corregido
import 'package:mental_app/screens/community_screen.dart';
import 'package:mental_app/screens/private_chat_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String _quote = "Cargando cita...";
  String _author = "";

  @override
  void initState() {
    super.initState();
    _loadAndSetRandomQuote();
  }

  Future<void> _loadAndSetRandomQuote() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/quotes.json');
      final List<dynamic> quotesList = json.decode(jsonString);

      if (quotesList.isNotEmpty) {
        final randomQuote = quotesList[Random().nextInt(quotesList.length)];
        setState(() {
          _quote = '"${randomQuote['text']}"';
          _author = '- ${randomQuote['author']}';
        });
      }
    } catch (e) {
      setState(() {
        _quote = "No se pudieron cargar las citas.";
        _author = "";
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.email?.split('@')[0] ?? 'Usuario'}'),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context),
              tooltip: 'Cerrar Sesión'
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Cita Motivadora ---
            Text(
              _quote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              _author,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 50),

            // --- Botones de Navegación ---
            _MenuButton(
              icon: Icons.add_reaction_outlined,
              text: 'Registrar Ánimo Diario',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyMoodScreen()));
              },
            ),
            const SizedBox(height: 15),

            // --- BOTÓN AÑADIDO ---
            _MenuButton(
              icon: Icons.timeline,
              text: 'Ver Mi Historial y Gráfica',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MoodHistoryScreen()));
              },
            ),
            const SizedBox(height: 15),
            _MenuButton(
              icon: Icons.people_alt_outlined,
              text: 'Comunidad',
              onPressed: () {
                // DESCOMENTA O AÑADE ESTA LÍNEA
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen()));
              },
            ),
            const SizedBox(height: 15),
            _MenuButton(
              icon: Icons.support_agent,
              text: 'Asistente Personal (Chat)',
              onPressed: () {
                // AÑADE O DESCOMENTA ESTA LÍNEA
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivateChatScreen()));
              },
            ),
          ], // Cierre correcto de la lista de children del Column
        ), // Cierre correcto del Column
      ), // Cierre correcto del Padding
    ); // Cierre correcto del Scaffold
  }
}

// Widget auxiliar para no repetir código de botones
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _MenuButton({required this.icon, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(text),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}