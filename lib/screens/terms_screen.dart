import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mental_app/auth_gate.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  String _termsText = 'Cargando términos...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  // Carga el texto desde el archivo de assets
  Future<void> _loadTerms() async {
    try {
      final text = await rootBundle.loadString('assets/terminos.txt');
      setState(() {
        _termsText = text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _termsText = 'Error al cargar los términos. Asegúrate de que el archivo "assets/terminos.txt" existe.';
        _isLoading = false;
      });
    }
  }

  // Guarda la aceptación y reconstruye la app
  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);

    // Vuelve a cargar el AuthGate para que re-evalúe el estado
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        automaticallyImplyLeading: false, // Oculta el botón de volver
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_termsText),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _acceptTerms,
              child: const Text('ACEPTAR Y CONTINUAR'),
            ),
          ],
        ),
      ),
    );
  }
}