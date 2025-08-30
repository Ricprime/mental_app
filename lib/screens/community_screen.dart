// lib/screens/community_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// --- CORRECCIÓN: Se usa la ruta relativa correcta ---
import '../widgets/image_upload_widget.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  String? _postImageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          _buildFeedContent(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        tooltip: 'Crear publicación',
        child: const Icon(Icons.add),
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.asset(
          'assets/images/community_header.jpg',
          fit: BoxFit.cover,
          color: Colors.black.withOpacity(0.3),
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

  Widget _buildFeedContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverFillRemaining(child: _EmptyFeedView());
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCreatePostDialog(BuildContext context) {
    _postImageUrl = null;
    _postController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Compartir en la Comunidad'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _postController,
                      decoration: const InputDecoration(hintText: 'Escribe tus pensamientos...'),
                      autofocus: true,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    if (_postImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_postImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 10),
                    ImageUploadWidget(
                      purpose: ImageUploadPurpose.communityPost,
                      onImageUploaded: (imageUrl, purpose) {
                         if (purpose == ImageUploadPurpose.communityPost) {
                           setDialogState(() {
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
    Navigator.of(context).pop();

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'text': _postController.text.trim(),
        'authorId': user.uid,
        'authorName': user.displayName ?? user.email?.split('@')[0] ?? 'Anónimo',
        'authorPhotoUrl': user.photoURL,
        'createdAt': Timestamp.now(),
        'imageUrl': _postImageUrl,
        'likes': [],
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

class _EmptyFeedView extends StatelessWidget {
  const _EmptyFeedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mindfulness_inspiration.jpg',
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = post['createdAt'] as Timestamp?;
    final date = timestamp != null ? DateFormat('dd MMM, HH:mm').format(timestamp.toDate()) : '';
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
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.primaryColor.withAlpha(50),
                  backgroundImage: authorPhotoUrl != null ? NetworkImage(authorPhotoUrl) : null,
                  child: authorPhotoUrl == null 
                    ? Text(authorName.substring(0, 1).toUpperCase(), style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold))
                    : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(date, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(post['text'] ?? '', style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
            if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : Container(height: 220, color: Colors.grey[200]),
                  errorBuilder: (context, error, stack) =>
                      Container(height: 220, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}, color: Colors.grey[700]),
                IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}, color: Colors.grey[700]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}