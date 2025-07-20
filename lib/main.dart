import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
// ¡IMPORTANTE! Ruta corregida para auth_gate.dart a formato de paquete
import '../auth/auth_gate.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase usando las opciones de la plataforma actual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activa Firebase App Check con el proveedor Play Integrity para Android.
  // Esto ayuda a verificar que las solicitudes provienen de tu aplicación real.
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // Ejecuta la aplicación principal de Flutter
  runApp(
      const MentalpApp()); // Nombre de la clase principal de la app cambiado a MentalpApp
}

// Nombre de la clase principal de la app cambiado a MentalpApp para consistencia
class MentalpApp extends StatelessWidget {
  const MentalpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Desactiva el banner de "DEBUG" en la esquina superior derecha en modo de depuración.
      debugShowCheckedModeBanner: false,
      // Título de la aplicación, visible en el gestor de tareas del dispositivo.
      title: 'Mentalp', // Nombre de la aplicación

      // --- TEMA VISUAL DE LA APP ---
      theme: ThemeData(
        // Define un esquema de color basado en un color semilla, para Material 3.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        // Habilita las características de diseño de Material 3.
        useMaterial3: true,
        // Color de fondo predeterminado para los Scaffold (pantallas).
        scaffoldBackgroundColor: Colors.white,

        // Tema para la AppBar (barra superior de la aplicación).
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Fondo blanco para la AppBar.
          elevation: 0, // Sin sombra debajo de la AppBar.
          iconTheme: IconThemeData(
              color: Colors.black87), // Color de los iconos en la AppBar.
          titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold), // Estilo del texto del título.
        ),

        // Tema para los ElevatedButtons (botones elevados/rellenos).
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent, // Fondo azul para los botones.
            foregroundColor:
                Colors.white, // Color del texto y los iconos en los botones.
            padding:
                const EdgeInsets.symmetric(vertical: 16), // Relleno vertical.
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)), // Bordes redondeados.
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold), // Estilo del texto.
          ),
        ),

        // Tema para los OutlinedButtons (botones con borde).
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blueAccent, // Color del texto y los iconos.
            side: const BorderSide(
                color: Colors.blueAccent, width: 1.5), // Borde azul.
            padding:
                const EdgeInsets.symmetric(vertical: 16), // Relleno vertical.
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)), // Bordes redondeados.
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold), // Estilo del texto.
          ),
        ),

        // Tema para los campos de entrada de texto (TextField, TextFormField).
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Bordes redondeados.
            borderSide: const BorderSide(color: Colors.grey), // Borde gris.
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                12), // Bordes redondeados cuando está enfocado.
            borderSide: const BorderSide(
                color: Colors.blueAccent,
                width: 2), // Borde azul más grueso cuando está enfocado.
          ),
          labelStyle: const TextStyle(
              color: Colors.grey), // Estilo del texto de la etiqueta.
        ),
      ),

      // --- PUNTO DE ENTRADA DE LA APP ---
      // El widget AuthGate decide qué pantalla mostrar al usuario (login o principal).
      home: const AuthGate(),
    );
  }
}
