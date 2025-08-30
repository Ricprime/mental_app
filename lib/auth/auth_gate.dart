import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ¡RUTAS CORREGIDAS! Ahora usa rutas relativas para ir a la carpeta 'screens'.
import '../screens/terms_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/main_menu_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _areTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('terms_accepted') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _areTermsAccepted(),
      builder: (context, termsSnapshot) {
        if (termsSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (termsSnapshot.data == false) {
          return const TermsScreen();
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.hasData) {
              return const MainMenuScreen();
            } else {
              return const WelcomeScreen();
            }
          },
        );
      },
    );
  }
}
