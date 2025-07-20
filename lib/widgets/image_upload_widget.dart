import 'dart:io'; // Necesario para la clase File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imágenes
import 'package:firebase_storage/firebase_storage.dart'; // Para subir a Firebase Storage
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el usuario actual

// Definimos un enumerador para el tipo de uso de la imagen
enum ImageUploadPurpose { profile, communityPost }

class ImageUploadWidget extends StatefulWidget {
  // Función que se llamará cuando la imagen se suba con éxito.
  // Recibe la URL de descarga y el propósito de la subida.
  final Function(String imageUrl, ImageUploadPurpose purpose) onImageUploaded;
  final ImageUploadPurpose purpose; // Propósito de la subida (perfil o post)

  const ImageUploadWidget({
    super.key,
    required this.onImageUploaded,
    required this.purpose,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _imageFile; // Almacena la imagen seleccionada temporalmente
  String?
      _currentImageUrl; // Almacena la URL de la imagen que ya está en uso (ej. foto de perfil actual)
  bool _isUploading = false; // Estado para mostrar un indicador de carga

  // Instancia de ImagePicker para seleccionar imágenes
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Aquí podrías cargar una imagen existente si es para un perfil
    // Por ejemplo, si el widget se usa para la foto de perfil,
    // podrías pasar la URL actual del perfil a través de un constructor.
    // Por ahora, lo dejamos simple.
  }

  // Función para seleccionar una imagen de la galería
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Guarda el archivo seleccionado
        // No limpiamos _currentImageUrl aquí, ya que podría ser la foto de perfil actual
      });
    }
  }

  // Función para subir la imagen seleccionada a Firebase Storage
  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      _showMessage('Por favor, selecciona una imagen primero.');
      return;
    }

    // Obtener el usuario actual. Es crucial para las reglas de seguridad de Storage.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Debes iniciar sesión para subir imágenes.');
      return;
    }

    setState(() {
      _isUploading = true; // Inicia el estado de carga
    });

    try {
      String storagePath;
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}';

      // Definir la ruta de almacenamiento en función del propósito
      if (widget.purpose == ImageUploadPurpose.profile) {
        storagePath =
            'user_profiles/${user.uid}/profile_picture.jpg'; // Ruta fija para foto de perfil
      } else {
        // ImageUploadPurpose.communityPost
        storagePath =
            'community_posts/${user.uid}/$fileName'; // Ruta para posts (con UID del usuario)
      }

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Subir el archivo
      final uploadTask = storageRef.putFile(_imageFile!);

      // Esperar a que la subida se complete y obtener la URL de descarga
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _currentImageUrl = downloadUrl; // Actualiza la URL mostrada
        _imageFile = null; // Limpia el archivo temporal
        _isUploading = false; // Finaliza el estado de carga
      });

      _showMessage('Imagen subida con éxito!');
      print('URL de descarga: $downloadUrl');

      // Llama a la función de callback para que la pantalla padre guarde la URL en Firestore
      widget.onImageUploaded(downloadUrl, widget.purpose);
    } on FirebaseException catch (e) {
      setState(() {
        _isUploading = false; // Finaliza el estado de carga en caso de error
      });
      _showMessage('Error al subir la imagen: ${e.message}');
      print('Error de Firebase Storage: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() {
        _isUploading = false; // Finaliza el estado de carga en caso de error
      });
      _showMessage('Error desconocido al subir la imagen: $e');
      print('Error desconocido: $e');
    }
  }

  // Pequeña función para mostrar mensajes al usuario (como un Snackbar)
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Muestra la imagen seleccionada, la URL actual o un placeholder
            _imageFile != null
                ? Image.file(
                    _imageFile!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  )
                : (_currentImageUrl != null
                    ? Image.network(
                        _currentImageUrl!,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
                        width: 200,
                        color: Colors.grey[300],
                        child: Icon(Icons.image,
                            size: 100, color: Colors.grey[600]),
                      )),
            const SizedBox(height: 20),
            // Botón para seleccionar imagen
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Seleccionar Imagen'),
            ),
            const SizedBox(height: 10),
            // Botón para subir imagen, deshabilitado durante la carga
            _isUploading
                ? const CircularProgressIndicator() // Indicador de carga
                : ElevatedButton.icon(
                    onPressed: _uploadImage,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Subir Imagen'),
                  ),
            const SizedBox(height: 20),
            // Muestra la URL de la imagen subida (solo para depuración)
            if (_currentImageUrl != null)
              SelectableText(
                'URL: $_currentImageUrl',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
          ],
        ),
      ),
    );
  }
}
