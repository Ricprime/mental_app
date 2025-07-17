import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyMoodScreen extends StatefulWidget {
  const DailyMoodScreen({super.key});

  @override
  State<DailyMoodScreen> createState() => _DailyMoodScreenState();
}

class _DailyMoodScreenState extends State<DailyMoodScreen> {
  String? _selectedMood;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String _dailyQuestion = "Cargando pregunta del día...";

  @override
  void initState() {
    super.initState();
    _loadRandomQuestion();
  }

  // Carga el JSON de preguntas y elige una al azar
  Future<void> _loadRandomQuestion() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/questions.json');
      final List<dynamic> questionsList = json.decode(jsonString);
      if (questionsList.isNotEmpty) {
        final randomQuestion = questionsList[Random().nextInt(questionsList.length)];
        setState(() {
          _dailyQuestion = randomQuestion['question'];
        });
      }
    } catch (e) {
      setState(() {
        _dailyQuestion = "¿Qué ha sido lo más destacable de tu día?";
      });
    }
  }

  // Mapa de ánimos con iconos para la UI
  final Map<String, IconData> _moods = {
    'Feliz': Icons.sentiment_very_satisfied,
    'Normal': Icons.sentiment_satisfied,
    'Triste': Icons.sentiment_dissatisfied,
    'Enfadado': Icons.sentiment_very_dissatisfied,
    'Calmado': Icons.sentiment_neutral,
  };

  Future<void> _saveMood() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona un estado de ánimo.')));
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado.");

      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('moods').add({
        'mood': _selectedMood,
        'notes': _notesController.text.trim(),
        'createdAt': Timestamp.now(),
        'question_prompt': _dailyQuestion, // Guardamos la pregunta que se le hizo
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Ánimo guardado con éxito!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo te sientes hoy?')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Selecciona tu estado de ánimo:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 15.0,
              runSpacing: 15.0,
              children: _moods.entries.map((entry) {
                final mood = entry.key;
                final icon = entry.value;
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
                        child: Icon(icon, size: 40, color: isSelected ? Colors.white : Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(mood, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // --- Pregunta del Día ---
            Text(
              _dailyQuestion,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // Campo de texto para las notas
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Escribe aquí tus pensamientos...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 40),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _saveMood,
              child: const Text('GUARDAR REGISTRO'),
            ),
          ],
        ),
      ),
    );
  }
}