import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardView extends StatelessWidget {
  final VoidCallback onBack;

  const AdminDashboardView({super.key, required this.onBack});
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.transparent, 
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: onBack,
                ),
                const Text(
                  "Estadísticas Dashboard",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Resumen de Actividad", 
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildKpiCard("Usuarios", "150", Icons.people, Colors.blue),
                        _buildKpiCard("Intercambios", "45", Icons.swap_horiz, Colors.green),
                        _buildKpiCard("Libros", "320", Icons.book, unimetOrange),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text("Libros por Categoría", 
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 20),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 5,
                              centerSpaceRadius: 40,
                              sections: [
                                _buildPieSection("Faces", 35, Colors.blue),
                                _buildPieSection("Ingeniería", 25, unimetOrange),
                                _buildPieSection("Humanidades", 20, Colors.purple),
                                _buildPieSection("Derecho", 20, Colors.redAccent),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildLegend(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: unimetBlue)),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(String label, double value, Color color) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${value.toInt()}%',
      radius: 60,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildLegend() {
    final categories = ['Faces', 'Ingeniería', 'Humanidades', 'Derecho'];
    final colors = [Colors.blue, unimetOrange, Colors.purple, Colors.redAccent];

    return Wrap(
      spacing: 20,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(categories.length, (i) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(categories[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: unimetBlue)),
        ],
      )),
    );
  }
}