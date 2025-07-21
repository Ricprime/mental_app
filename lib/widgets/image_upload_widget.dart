import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// El enum que creaste. ¡Es una idea excelente para la reutilización!
enum ImageUploadPurpose { profile, communityPost }

// El callback ahora solo necesita devolver la URL, el widget padre ya sabe el propósito.
typedef OnImageUploadedCallback = void Function(
    String imageUrl, ImageUploadPurpose purpose);

class ImageUploadWidget extends StatefulWidget {
  final OnImageUploadedCallback onImageUploaded;
  final ImageUploadPurpose purpose;
  final String? initialImageUrl; // Para mostrar la foto de perfil actual

  const ImageUploadWidget({
    super.key,
    required this.onImageUploaded,
    required this.purpose,
    this.initialImageUrl, // Opcional
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isUploading = false;

  // <<< MEJORA UX: Unificamos la selección y subida en una sola acción.
  // El usuario solo tiene que hacer un clic para todo el proceso.
  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Debes iniciar sesión para subir una imagen.');
      return;
    }

    // 1. Seleccionar la imagen
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return; // El usuario canceló

    setState(() {
      _isUploading = true;
    });

    try {
      // 2. Subir la imagen (usando tu lógica de rutas, que es perfecta)
      final imageFile = File(pickedFile.path);
      String storagePath;
      if (widget.purpose == ImageUploadPurpose.profile) {
        // Para la foto de perfil, siempre sobrescribimos el mismo archivo para no dejar basura.
        storagePath = 'user_profiles/${user.uid}/profile_picture.jpg';
      } else {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        storagePath = 'community_posts/${user.uid}/$fileName';
      }

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 3. Notificar al widget padre con la URL
      if (mounted) {
        widget.onImageUploaded(downloadUrl, widget.purpose);
      }
    } catch (e) {
      _showMessage('Error al subir la imagen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // <<< MEJORA UI: El widget ahora se dibuja de forma diferente según su propósito.
    if (widget.purpose == ImageUploadPurpose.profile) {
      return _buildProfileAvatar();
    } else {
      return _buildPostImageButton();
    }
  }

  // --- UI para la FOTO DE PERFIL ---
  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: widget.initialImageUrl != null
              ? NetworkImage(widget.initialImageUrl!)
              : null,
          child: _isUploading
              ? const CircularProgressIndicator()
              : (widget.initialImageUrl == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey.shade500)
                  : null),
        ),
        Material(
          color: Theme.of(context).primaryColor,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            onTap: _isUploading ? null : _pickAndUploadImage,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        )
      ],
    );
  }

  // --- UI para AÑADIR IMAGEN A UN POST ---
  Widget _buildPostImageButton() {
    return OutlinedButton.icon(
      onPressed: _isUploading ? null : _pickAndUploadImage,
      icon: _isUploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.add_photo_alternate_outlined),
      label: Text(_isUploading ? 'Subiendo...' : 'Añadir Imagen'),
    );
  }
}
