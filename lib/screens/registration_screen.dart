import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() { _isLoading = true; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Cierra la pantalla de registro. El AuthGate se encargará de mostrar el menú.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error de registro')));
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text('Únete a la comunidad', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text('Crea tu cuenta para empezar a cuidarte', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 40),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo Electrónico'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña (mín. 6 caracteres)'), obscureText: true),
            const SizedBox(height: 40),
            _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _register, child: const Text('REGISTRARME')),
          ],
        ),
      ),
    );
  }
}