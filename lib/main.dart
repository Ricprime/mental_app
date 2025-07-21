import 'package:flutter/material.dart';
import 'package:mentalp/theme/app_theme.dart'; // Importamos nuestro tema centralizado.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:mentalp/auth/auth_gate.dart';

// --- Falta de punto y coma corregido en la importación de welcome_screen.dart ---
import 'package:mentalp/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Se mantiene tu excelente lógica para inicializar Firebase de forma segura.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print("Firebase ya está inicializado. Continuando...");
    } else {
      rethrow;
    }
  } catch (e) {
    print("Error inesperado durante la inicialización de Firebase: $e");
    rethrow;
  }

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(const MentalpApp());
}

// --- Clase ÚNICA Y PRINCIPAL de la aplicación ---
// Hemos eliminado la clase 'MyApp' duplicada para evitar confusiones.
class MentalpApp extends StatelessWidget {
  const MentalpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mentalp',

      // --- TEMA VISUAL DE LA APP ---
      // ¡Aquí está la magia! Simplemente aplicamos el tema que definimos en app_theme.dart
      theme: AppTheme.lightTheme,

      // El punto de entrada de la app es AuthGate, que decide qué pantalla mostrar.
      // Esto está perfecto.
      home: const AuthGate(),
    );
  }
}
