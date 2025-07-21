import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <<< AÑADIDO: Para guardar datos del usuario
import 'package:mentalp/widgets/image_upload_widget.dart'; // <<< AÑADIDO: Nuestro widget de subida

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController(); // <<< AÑADIDO: Para el nombre de usuario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _profileImageUrl; // <<< AÑADIDO: Para almacenar la URL de la foto de perfil
  bool _isLoading = false;

  // <<< AÑADIDO: Callback que recibe la URL desde ImageUploadWidget
  void _handleImageUpload(String imageUrl, ImageUploadPurpose purpose) {
    if (purpose == ImageUploadPurpose.profile) {
      setState(() {
        _profileImageUrl = imageUrl;
      });
    }
  }

  Future<void> _register() async {
    // --- MEJORA: Validaciones más completas ---
    if (_profileImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, sube una foto de perfil.')));
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, introduce tu nombre.')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Crear el usuario en Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) return;

      // 2. Actualizar el perfil de FirebaseAuth (nombre y foto)
      await user.updateDisplayName(_nameController.text.trim());
      await user.updatePhotoURL(_profileImageUrl);

      // 3. Guardar la información adicional del usuario en Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'photoURL': _profileImageUrl,
        'createdAt': Timestamp.now(),
      });

      // 4. Navegar a la pantalla principal
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);

    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error de registro')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Para acceder a nuestro tema global

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent, // <<< MEJORA UI: AppBar transparente
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // <<< MEJORA UI: Textos usando el tema global para consistencia
            Text('Únete a la comunidad', style: theme.textTheme.headlineLarge),
            Text('Crea tu cuenta para empezar a cuidarte', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 40),

            // <<< AÑADIDO: Widget para subir la foto de perfil
            Center(
              child: ImageUploadWidget(
                purpose: ImageUploadPurpose.profile,
                onImageUploaded: _handleImageUpload,
              ),
            ),
            const SizedBox(height: 40),

            // <<< AÑADIDO: Campo para el nombre de usuario
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre de Usuario')),
            const SizedBox(height: 20),

            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo Electrónico'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña (mín. 6 caracteres)'), obscureText: true),
            const SizedBox(height: 40),
            
            // <<< MEJORA UI: El botón ahora usa el estilo del tema global
            _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : ElevatedButton(onPressed: _register, child: const Text('REGISTRARME')),
          ],
        ),
      ),
    );
  }
}