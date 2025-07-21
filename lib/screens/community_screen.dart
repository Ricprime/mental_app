import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mentalp/widgets/image_upload_widget.dart'; // Importamos tu widget

// --- Pantalla Principal de la Comunidad ---
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  String? _postImageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Lógica de Creación de Post (Tu código original, movido al final por legibilidad) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ya no necesitamos una AppBar aquí, el header visual la reemplaza.
      body: CustomScrollView(
        slivers: [
          _buildHeader(context), // Header visual que hemos diseñado.
          _buildFeedContent(), // Contenido del feed (los posts).
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        tooltip: 'Crear publicación',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- WIDGETS DE LA INTERFAZ ---

  // 1. Cabecera visual de la pantalla de comunidad.
  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.asset(
          'assets/images/community_header.jpg', // <<< IMAGEN DE CABECERA
          fit: BoxFit.cover,
          color: Colors.black
              .withOpacity(0.3), // Ligero oscurecimiento para legibilidad
          colorBlendMode: BlendMode.darken,
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Un espacio para compartir',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 2. Contenido del feed que se actualiza en tiempo real.
  Widget _buildFeedContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
              child: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverFillRemaining(
              child: _EmptyFeedView()); // Vista para cuando no hay posts
        }

        final posts = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              return _PostCard(post: post);
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }

  // 3. Vista que se muestra cuando el feed está vacío.
  Widget _EmptyFeedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mindfulness_inspiration.jpg', // <<< IMAGEN DE INSPIRACIÓN
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 24),
            Text(
              'La comunidad te espera',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no hay publicaciones. ¡Sé el primero en compartir tus pensamientos y conectar con otros!',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA Y DIÁLOGO PARA CREAR POSTS ---

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Usamos un StatefulBuilder para que solo el contenido del diálogo se actualice
  void _showCreatePostDialog(BuildContext context) {
    _postImageUrl = null; // Reinicia la imagen al abrir
    _postController.clear(); // Limpia el texto anterior

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder permite que el diálogo tenga su propio estado interno
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Compartir en la Comunidad'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _postController,
                      decoration: const InputDecoration(
                          hintText: 'Escribe tus pensamientos...'),
                      autofocus: true,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    // Vista previa de la imagen y widget de subida
                    if (_postImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_postImageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 10),
                    ImageUploadWidget(
                      purpose: ImageUploadPurpose.communityPost,
                      onImageUploaded: (imageUrl, purpose) {
                        if (purpose == ImageUploadPurpose.communityPost) {
                          setDialogState(() {
                            // Actualiza solo el estado del diálogo
                            _postImageUrl = imageUrl;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
      },
    );
  }

  Future<void> _createPost() async {
    final user = _auth.currentUser;
    if (user == null || _postController.text.trim().isEmpty) {
      _showMessage('Debes iniciar sesión y escribir un mensaje.');
      return;
    }
    Navigator.of(context)
        .pop(); // Cierra el diálogo inmediatamente para dar feedback al usuario

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'text': _postController.text.trim(),
        'authorId': user.uid,
        'authorName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Anónimo',
        'authorPhotoUrl':
            user.photoURL, // Guardamos la foto de perfil del usuario
        'createdAt': Timestamp.now(),
        'imageUrl': _postImageUrl,
        'likes': [], // Preparamos el campo para futuros likes
      });
      _showMessage('Post creado con éxito!');
    } catch (e) {
      _showMessage('Error al crear el post: $e');
    } finally {
      _postImageUrl = null;
      _postController.clear();
    }
  }
}

// --- WIDGET PARA CADA TARJETA DE POST (REDiseñado) ---
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = post['createdAt'] as Timestamp?;
    final date = timestamp != null
        ? DateFormat('dd MMM, HH:mm').format(timestamp.toDate())
        : '';
    final authorName = post['authorName'] ?? 'Anónimo';
    final authorPhotoUrl = post['authorPhotoUrl'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del post con avatar, nombre y fecha
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.primaryColor.withAlpha(50),
                  backgroundImage: authorPhotoUrl != null
                      ? NetworkImage(authorPhotoUrl)
                      : null,
                  child: authorPhotoUrl == null
                      ? Text(authorName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(date,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Contenido del post (texto e imagen)
            Text(post['text'] ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
            if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
                  // Añadimos un indicador de carga más sutil
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(height: 220, color: Colors.grey[200]),
                  errorBuilder: (context, error, stack) => Container(
                      height: 220,
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Barra de acciones (preparada para el futuro)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {},
                    color: Colors.grey[700]),
                IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {},
                    color: Colors.grey[700]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
