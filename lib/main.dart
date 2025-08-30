// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// --- CORRECCIÓN: Se usan rutas relativas para importar tus propios archivos ---
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'auth/auth_gate.dart';

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
class MentalpApp extends StatelessWidget {
  const MentalpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mentalp',

      // Aplicamos el tema que definimos en app_theme.dart
      theme: AppTheme.lightTheme,

      // El punto de entrada de la app es AuthGate
      home: const AuthGate(),
    );
  }
}
