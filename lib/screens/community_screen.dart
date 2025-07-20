import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
import '/widgets/image_upload_widget.dart'; // Tu widget de subida de imágenes

class CommunityScreen extends StatefulWidget {
  // Cambiado a StatefulWidget para manejar el estado de la imagen
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  String?
      _postImageUrl; // Para almacenar la URL de la imagen del post antes de publicarlo
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instancia de FirebaseAuth

  // Función para mostrar mensajes al usuario (SnackBar)
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Función que se llama desde ImageUploadWidget cuando la imagen se sube con éxito
  void _handlePostImageUpload(String imageUrl, ImageUploadPurpose purpose) {
    if (purpose == ImageUploadPurpose.communityPost) {
      setState(() {
        _postImageUrl = imageUrl; // Guarda la URL temporalmente para el post
      });
      _showMessage('Imagen lista para el post!');
    }
  }

  // Función para crear un nuevo post en Firestore
  Future<void> _createPost() async {
    final user = _auth.currentUser;
    if (user == null || _postController.text.trim().isEmpty) {
      // trim() para evitar posts solo con espacios
      _showMessage('Debes iniciar sesión y escribir un mensaje.');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'text': _postController.text.trim(), // Guarda el texto del post
        'authorId': user.uid,
        'authorName': user.email?.split('@')[0] ??
            'Anónimo', // Obtiene el nombre de usuario
        'createdAt': Timestamp.now(), // Marca de tiempo del servidor
        'imageUrl':
            _postImageUrl, // Guarda la URL de la imagen (puede ser null)
      });

      _postController.clear(); // Limpia el campo de texto
      setState(() {
        _postImageUrl = null; // Limpia la URL de la imagen después de publicar
      });
      Navigator.of(context).pop(); // Cierra el diálogo
      _showMessage('Post creado con éxito!');
    } catch (e) {
      _showMessage('Error al crear el post: $e');
      print(
          'Error al crear el post: $e'); // Imprime el error en la consola para depuración
    }
  }

  // Muestra un diálogo para crear un nuevo post
  void _showCreatePostDialog(BuildContext context) {
    // Reinicia la URL de la imagen del post cuando se abre el diálogo
    setState(() {
      _postImageUrl = null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Compartir en la Comunidad'),
          content: SingleChildScrollView(
            // Permite desplazamiento si el contenido es largo
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Ajusta el tamaño del diálogo al contenido
              children: [
                TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                      hintText: 'Escribe tus pensamientos...'),
                  autofocus: true,
                  maxLines: 5,
                ),
                const SizedBox(height: 20),
                // Widget de subida de imagen para el post
                ImageUploadWidget(
                  purpose:
                      ImageUploadPurpose.communityPost, // Indica el propósito
                  onImageUploaded:
                      _handlePostImageUpload, // Callback al subir la imagen
                ),
                // Muestra una vista previa de la imagen seleccionada para el post
                if (_postImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.network(_postImageUrl!,
                        height: 100, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _postImageUrl = null; // Limpia la URL si se cancela el post
                });
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _createPost,
              child: const Text('Publicar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Comunidad Mentalp')), // Título de la AppBar
      // Usamos un StreamBuilder para que la lista de posts se actualice en tiempo real
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true) // Lo más nuevo, primero
            .limit(50) // Limitamos a 50 posts para no sobrecargar
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // Indicador de carga
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}')); // Muestra errores
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text(
                    'Aún no hay publicaciones. ¡Sé el primero!')); // Mensaje si no hay posts
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              return _PostCard(post: post); // Muestra cada post en una tarjeta
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showCreatePostDialog(context), // Abre el diálogo para crear post
        tooltip: 'Crear publicación',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget para mostrar cada tarjeta de publicación
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final timestamp = post['createdAt'] as Timestamp?;
    final date = timestamp != null
        ? DateFormat('dd/MM/yy, HH:mm').format(timestamp.toDate())
        : 'Ahora';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Muestra el nombre del autor del post
            Text(
              post['authorName'] ?? 'Anónimo',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            // Muestra el texto del post
            Text(
              post['text'] ?? 'Sin contenido',
              style: const TextStyle(fontSize: 16),
            ),
            // Muestra la imagen del post si existe
            if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty) ...[
              const SizedBox(height: 10),
              Image.network(
                post['imageUrl'],
                fit: BoxFit.cover,
                width: double
                    .infinity, // La imagen ocupa todo el ancho de la tarjeta
                height: 200, // Altura fija para las imágenes de post
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    height: 200,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Muestra la fecha y hora del post
                Text(
                  'Publicado: $date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
