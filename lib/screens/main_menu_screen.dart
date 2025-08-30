// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- CORRECCIÓN: Rutas relativas para los archivos de la app ---
import 'daily_mood_screen.dart';
import 'mood_history_screen.dart';
import 'community_screen.dart';
import 'private_chat_screen.dart';
import '../auth/auth_gate.dart';


class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, ${user?.displayName ?? 'Usuario'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthGate()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _MenuCard(
            title: 'Registro Diario',
            subtitle: '¿Cómo te sientes hoy?',
            icon: Icons.sentiment_satisfied_alt_rounded,
            color: theme.colorScheme.primary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyMoodScreen()));
            },
          ),
          _MenuCard(
            title: 'Mi Historial',
            subtitle: 'Visualiza tu progreso',
            icon: Icons.bar_chart_rounded,
            color: theme.colorScheme.secondary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MoodHistoryScreen()));
            },
          ),
          _MenuCard(
            title: 'Comunidad',
            subtitle: 'Conecta y comparte',
            icon: Icons.people_alt_rounded,
            color: Colors.orange.shade400,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen()));
            },
          ),
          _MenuCard(
            title: 'Asistente Personal',
            subtitle: 'Habla con tu guía de bienestar',
            icon: Icons.support_agent_rounded,
            color: Colors.purple.shade300,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivateChatScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}