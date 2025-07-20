import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ¡RUTA CORREGIDA! Apunta a la nueva carpeta 'widgets'.
import '../widgets/image_upload_widget.dart';
// ¡RUTAS CORREGIDAS! Ahora son relativas a la misma carpeta 'screens'.
import 'daily_mood_screen.dart';
import 'mood_history_screen.dart';
import 'community_screen.dart';
import 'private_chat_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String _quote = "Cargando cita...";
  String _author = "";
  String? _profileImageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadAndSetRandomQuote();
    _loadProfileImage();
  }

  Future<void> _loadAndSetRandomQuote() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/quotes.json');
      final List<dynamic> quotesList = json.decode(jsonString);
      if (quotesList.isNotEmpty) {
        final randomQuote = quotesList[Random().nextInt(quotesList.length)];
        if (mounted) {
          setState(() {
            _quote = '"${randomQuote['text']}"';
            _author = '- ${randomQuote['author']}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quote = "No se pudieron cargar las citas.";
          _author = "";
        });
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted &&
          userDoc.exists &&
          userDoc.data()!.containsKey('profileImageUrl')) {
        setState(() {
          _profileImageUrl = userDoc.data()!['profileImageUrl'] as String;
        });
      }
    }
  }

  Future<void> _handleProfileImageUpload(
      String imageUrl, ImageUploadPurpose purpose) async {
    if (purpose == ImageUploadPurpose.profile) {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'profileImageUrl': imageUrl},
          SetOptions(merge: true),
        );
        if (mounted) {
          setState(() {
            _profileImageUrl = imageUrl;
          });
          _showMessage('Foto de perfil actualizada!');
        }
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
              onPressed: _signOut,
              tooltip: 'Cerrar Sesión'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  ImageUploadWidget(
                    purpose: ImageUploadPurpose.profile,
                    onImageUploaded: _handleProfileImageUpload,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            Text(
              _quote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              _author,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 50),
            _MenuButton(
              icon: Icons.add_reaction_outlined,
              text: 'Registrar Ánimo Diario',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DailyMoodScreen())),
            ),
            const SizedBox(height: 15),
            _MenuButton(
              icon: Icons.timeline,
              text: 'Ver Mi Historial y Gráfica',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MoodHistoryScreen())),
            ),
            const SizedBox(height: 15),
            _MenuButton(
              icon: Icons.people_alt_outlined,
              text: 'Comunidad',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CommunityScreen())),
            ),
            const SizedBox(height: 15),
            _MenuButton(
              icon: Icons.support_agent,
              text: 'Asistente Personal (Chat)',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PrivateChatScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _MenuButton(
      {required this.icon, required this.text, required this.onPressed});

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
