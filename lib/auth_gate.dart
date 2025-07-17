import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importa las pantallas que necesita el AuthGate
import 'package:mental_app/screens/terms_screen.dart';
import 'package:mental_app/screens/welcome_screen.dart';
import 'package:mental_app/screens/main_menu_screen.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Función para comprobar si los términos fueron aceptados
  Future<bool> _areTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('terms_accepted') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _areTermsAccepted(),
      builder: (context, termsSnapshot) {
        // Mientras espera, muestra un indicador de carga
        if (termsSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si los términos NO han sido aceptados, muestra la pantalla de términos
        if (termsSnapshot.data == false) {
          return const TermsScreen();
        }

        // Si los términos SÍ fueron aceptados, comprueba el estado del login
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            // Si el usuario está logueado, va al menú principal
            if (authSnapshot.hasData) {
              return const MainMenuScreen();
            }
            // Si no, va a la pantalla de bienvenida (con botones de login/registro)
            else {
              return const WelcomeScreen();
            }
          },
        );
      },
    );
  }
}