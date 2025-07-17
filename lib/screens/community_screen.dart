import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad')),
      // Usamos un StreamBuilder para que la lista se actualice en tiempo real
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true) // Lo más nuevo, primero
            .limit(50) // Limitamos a 50 posts para no sobrecargar
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aún no hay publicaciones. ¡Sé el primero!'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              return _PostCard(post: post);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        tooltip: 'Crear publicación',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Muestra un diálogo para crear un nuevo post
  void _showCreatePostDialog(BuildContext context) {
    final textController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Compartir en la Comunidad'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Escribe tus pensamientos...'),
            autofocus: true,
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isEmpty || user == null) return;

                // Añade el post a Firestore
                FirebaseFirestore.instance.collection('posts').add({
                  'text': textController.text.trim(),
                  'authorId': user.uid,
                  'authorName': user.email?.split('@')[0] ?? 'Anónimo',
                  'createdAt': Timestamp.now(),
                });

                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Publicar'),
            ),
          ],
        );
      },
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
    final date = timestamp != null ? DateFormat('dd/MM/yy, HH:mm').format(timestamp.toDate()) : 'Ahora';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['text'] ?? 'Sin contenido',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Por: ${post['authorName'] ?? 'Anónimo'} • $date',
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