// lib/screens/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- CORRECCIÓN: Se usa la ruta relativa correcta ---
import '../widgets/image_upload_widget.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _profileImageUrl;
  bool _isLoading = false;

  void _handleImageUpload(String imageUrl, ImageUploadPurpose purpose) {
    if (purpose == ImageUploadPurpose.profile) {
      setState(() {
        _profileImageUrl = imageUrl;
      });
    }
  }

  Future<void> _register() async {
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
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) return;

      await user.updateDisplayName(_nameController.text.trim());
      await user.updatePhotoURL(_profileImageUrl);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'photoURL': _profileImageUrl,
        'createdAt': Timestamp.now(),
      });

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);

    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error de registro')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text('Únete a la comunidad', style: theme.textTheme.headlineLarge),
            Text('Crea tu cuenta para empezar a cuidarte', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 40),
            Center(
              child: ImageUploadWidget(
                purpose: ImageUploadPurpose.profile,
                onImageUploaded: _handleImageUpload,
              ),
            ),
            const SizedBox(height: 40),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre de Usuario')),
            const SizedBox(height: 20),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo Electrónico'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña (mín. 6 caracteres)'), obscureText: true),
            const SizedBox(height: 40),
            _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : ElevatedButton(onPressed: _register, child: const Text('REGISTRARME')),
          ],
        ),
      ),
    );
  }
}