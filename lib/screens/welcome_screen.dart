import 'package:flutter/material.dart';
// ¡IMPORTANTE! Rutas corregidas para apuntar a los archivos dentro de 'screens'.
import 'login_screen.dart';
import 'registration_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.spa, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text('Bienvenido a Mentalp',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Tu espacio seguro para el bienestar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegistrationScreen()));
                },
                child: const Text('CREAR CUENTA'),
              ),
              const SizedBox(height: 15),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                },
                child: const Text('INICIAR SESIÓN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
