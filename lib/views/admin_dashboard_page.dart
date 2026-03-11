import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardView extends StatelessWidget {
  final VoidCallback onBack;

  const AdminDashboardView({super.key, required this.onBack});
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  // --- Firestore helpers (KPIs y gráfica) ---
  // Nota: usamos get().size para mantener compatibilidad. Si el proyecto activa agregaciones,
  // se puede migrar a Query.count().
  Future<int> _countDocs(String collectionPath) async {
    final snap = await FirebaseFirestore.instance.collection(collectionPath).get();
    return snap.size;
  }

  // Normaliza categorías para evitar que un libro no aparezca por diferencias de mayúsculas/espacios.
  String _normCat(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'faces' || s == 'f.a.c.e.s') return 'Faces';
    if (s == 'ingenieria' || s == 'ingeniería') return 'Ingeniería';
    if (s == 'humanidades') return 'Humanidades';
    if (s == 'derecho') return 'Derecho';
    return raw.trim().isEmpty ? 'Otros' : raw.trim();
  }

  Future<Map<String, int>> _countMaterialsByCategory() async {
    final snap = await FirebaseFirestore.instance.collection('materials').get();

    final counts = <String, int>{
      'Faces': 0,
      'Ingeniería': 0,
      'Humanidades': 0,
      'Derecho': 0,
    };

    for (final doc in snap.docs) {
      final data = doc.data();
      final raw = (data['category'] ?? '').toString();
      final cat = _normCat(raw);

      if (counts.containsKey(cat)) {
        counts[cat] = (counts[cat] ?? 0) + 1;
      } else {
        // Si aparece una categoría nueva, la metemos en "Otros".
        counts['Otros'] = (counts['Otros'] ?? 0) + 1;
      }
    }

    return counts;
  }

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
                const SizedBox(width: 12),
                const Text(
                  "Estadísticas Dashboard",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Admin',
                  onSelected: (value) {
                    if (value == 'profiles') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: unimetOrange,
                          content: Text(
                            'En desarrollo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'dashboard',
                      child: Row(
                        children: [
                          Icon(Icons.dashboard, color: unimetBlue),
                          SizedBox(width: 10),
                          Text('Dashboard'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'profiles',
                      child: Row(
                        children: [
                          Icon(Icons.people, color: unimetBlue),
                          SizedBox(width: 10),
                          Text('Gestión de Perfiles'),
                        ],
                      ),
                    ),
                  ],
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
                        FutureBuilder<int>(
                          future: _countDocs('usuarios'),
                          builder: (context, snap) {
                            return _buildKpiCard(
                              "Usuarios",
                              snap.hasData ? snap.data!.toString() : "—",
                              Icons.people,
                              Colors.blue,
                              isLoading: !snap.hasData,
                            );
                          },
                        ),
                        FutureBuilder<int>(
                          future: _countDocs('chats'),
                          builder: (context, snap) {
                            return _buildKpiCard(
                              "Intercambios",
                              snap.hasData ? snap.data!.toString() : "—",
                              Icons.swap_horiz,
                              Colors.green,
                              isLoading: !snap.hasData,
                            );
                          },
                        ),
                        FutureBuilder<int>(
                          future: _countDocs('materials'),
                          builder: (context, snap) {
                            return _buildKpiCard(
                              "Libros",
                              snap.hasData ? snap.data!.toString() : "—",
                              Icons.book,
                              unimetOrange,
                              isLoading: !snap.hasData,
                            );
                          },
                        ),
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
                          child: FutureBuilder<Map<String, int>>(
                            future: _countMaterialsByCategory(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(color: unimetOrange),
                                );
                              }

                              final counts = snap.data!;
                              final faces = counts['Faces'] ?? 0;
                              final ing = counts['Ingeniería'] ?? 0;
                              final hum = counts['Humanidades'] ?? 0;
                              final der = counts['Derecho'] ?? 0;
                              final otros = counts['Otros'] ?? 0;

                              final total = faces + ing + hum + der + otros;
                              if (total == 0) {
                                return Center(
                                  child: Text(
                                    'No hay libros en la colección materials',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                );
                              }

                              double pct(int n) => (n * 100.0) / total;

                              final sections = <PieChartSectionData>[
                                if (faces > 0) _buildPieSection("Faces", pct(faces), Colors.blue),
                                if (ing > 0) _buildPieSection("Ingeniería", pct(ing), unimetOrange),
                                if (hum > 0) _buildPieSection("Humanidades", pct(hum), Colors.purple),
                                if (der > 0) _buildPieSection("Derecho", pct(der), Colors.redAccent),
                                if (otros > 0) _buildPieSection("Otros", pct(otros), Colors.grey),
                              ];

                              return PieChart(
                                PieChartData(
                                  sectionsSpace: 5,
                                  centerSpaceRadius: 40,
                                  sections: sections,
                                ),
                              );
                            },
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

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {bool isLoading = false}) {
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
          isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: unimetOrange),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: unimetBlue,
                  ),
                ),
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
    final categories = ['Faces', 'Ingeniería', 'Humanidades', 'Derecho', 'Otros'];
    final colors = [Colors.blue, unimetOrange, Colors.purple, Colors.redAccent, Colors.grey];

    return Wrap(
      spacing: 20,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(categories.length, (i) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            categories[i],
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: unimetBlue,
            ),
          ),
        ],
      )),
    );
  }
}