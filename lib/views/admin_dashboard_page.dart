import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Firebase
import 'package:fl_chart/fl_chart.dart'; // Para los gráficos

class AdminDashboardView extends StatelessWidget {
  final VoidCallback onBack; // Para el botón de regresar

  const AdminDashboardView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón para regresar a la vista anterior
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: onBack,
              ),
              const Text(
                "Estadísticas en Tiempo Real",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildRealTimeStats(),
                const SizedBox(height: 25),
                _buildChartContainer("Distribución por Carrera", _buildBarChart()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealTimeStats() {
    return StreamBuilder(
      // Ejemplo: Escuchando la colección de intercambios
      stream: FirebaseFirestore.instance.collection('intercambios').snapshots(),
      builder: (context, snapshot) {
        int totalIntercambios = snapshot.data?.docs.length ?? 0;
        
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.4,
          children: [
            _statCard("Intercambios", totalIntercambios.toString(), Icons.swap_calls, Colors.orange),
            _statCard("Usuarios Activos", "450", Icons.person, Colors.blue), // Hardcoded o de otra colección
            _statCard("Libros", "1.2k", Icons.book, Colors.green),
            _statCard("Alertas", "3", Icons.warning, Colors.red),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B3A57))),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3A57))),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.orange)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 15, color: Colors.blue)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 10, color: Colors.green)]),
        ],
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}