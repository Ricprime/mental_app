import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Mapa para convertir el ánimo en un valor numérico para la gráfica
  final Map<String, double> _moodValues = {
    'Enfadado': 1.0,
    'Triste': 2.0,
    'Calmado': 3.0,
    'Normal': 4.0,
    'Feliz': 5.0,
  };

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Mi Historial')),
          body: const Center(child: Text('Inicia sesión para ver tu historial.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Historial y Gráfica')),
      body: StreamBuilder<QuerySnapshot>(
        // El Stream escucha los cambios en Firestore en tiempo real
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('moods')
            .orderBy('createdAt', descending: false) // Orden ascendente para la gráfica
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aún no tienes registros de ánimo.'));
          }

          // Procesamos los datos para la gráfica y la lista
          final moodDocs = snapshot.data!.docs;
          final List<FlSpot> spots = [];
          for (int i = 0; i < moodDocs.length; i++) {
            final doc = moodDocs[i].data() as Map<String, dynamic>;
            final mood = doc['mood'] as String;
            final value = _moodValues[mood] ?? 3.0; // Valor por defecto
            spots.add(FlSpot(i.toDouble(), value));
          }

          return Column(
            children: [
              // --- Contenedor de la Gráfica ---
              Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: leftTitleWidgets,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: bottomTitleWidgets, // Usando la función corregida
                          reservedSize: 30,
                          interval: 1,
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
                    minX: 0,
                    maxX: (moodDocs.length - 1).toDouble(),
                    minY: 1,
                    maxY: 5,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).primaryColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(),

              // --- Lista del Historial ---
              Expanded(
                child: ListView.builder(
                  itemCount: moodDocs.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = moodDocs.length - 1 - index;
                    final doc = moodDocs[reversedIndex].data() as Map<String, dynamic>;
                    final mood = doc['mood'] ?? 'N/A';
                    final notes = doc['notes'] ?? '';
                    final timestamp = doc['createdAt'] as Timestamp?;
                    final date = timestamp != null ? DateFormat('dd/MM/yyyy, HH:mm').format(timestamp.toDate()) : 'Fecha desconocida';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(_getMoodIcon(mood), size: 40, color: _getMoodColor(mood)),
                        title: Text(mood, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Fecha: $date\nNotas: ${notes.isEmpty ? "Sin notas" : notes}'),
                        isThreeLine: notes.isNotEmpty,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Funciones auxiliares para la gráfica y la lista ---

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 12);
    String text;
    switch (value.toInt()) {
      case 1: text = 'Enfadado'; break;
      case 2: text = 'Triste'; break;
      case 3: text = 'Calmado'; break;
      case 4: text = 'Normal'; break;
      case 5: text = 'Feliz'; break;
      default: return Container();
    }
    return Text(text, style: style, textAlign: TextAlign.left);
  }

  // VERSIÓN CORREGIDA Y SIMPLIFICADA
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final docs = (context as Element).findAncestorWidgetOfExactType<StreamBuilder<QuerySnapshot>>()?.initialData?.docs;
    if (docs == null || value.toInt() >= docs.length) {
      return Container();
    }
    final timestamp = (docs[value.toInt()].data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
    final dateText = timestamp != null ? DateFormat('dd/MM').format(timestamp.toDate()) : '';

    // Se devuelve directamente el widget Text con un poco de padding,
    // evitando SideTitleWidget para resolver el error de compilación.
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(dateText, style: const TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  IconData _getMoodIcon(String mood) {
    const moodIcons = {
      'Feliz': Icons.sentiment_very_satisfied,
      'Normal': Icons.sentiment_satisfied,
      'Triste': Icons.sentiment_dissatisfied,
      'Enfadado': Icons.sentiment_very_dissatisfied,
      'Calmado': Icons.sentiment_neutral,
    };
    return moodIcons[mood] ?? Icons.device_unknown;
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Feliz': return Colors.green;
      case 'Normal': return Colors.lightGreen;
      case 'Calmado': return Colors.blue;
      case 'Triste': return Colors.grey;
      case 'Enfadado': return Colors.red;
      default: return Colors.black;
    }
  }
}
