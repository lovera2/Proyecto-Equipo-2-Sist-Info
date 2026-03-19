import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'admin_user_management_page.dart';
import '../viewmodels/admin_user_management_viewmodel.dart';
import '../viewmodels/admin_material_viewmodel.dart';
import '../services/admin_material_service.dart';

class AdminMaterialManagementPage extends StatefulWidget {
  const AdminMaterialManagementPage({super.key});

  @override
  State<AdminMaterialManagementPage> createState() =>
      _AdminMaterialManagementPageState();
}

class _AdminMaterialManagementPageState
    extends State<AdminMaterialManagementPage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color adminOrange = Color(0xFFE58A34);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AdminMaterialViewModel>().cargarMateriales(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSafeImage(
    String? source, {
    double width = 40,
    double height = 60,
  }) {
    if (source == null || source.trim().isEmpty) {
      return Icon(Icons.book, size: width * 0.8, color: Colors.grey);
    }
    try {
      if (source.startsWith('http://') || source.startsWith('https://')) {
        return Image.network(
          source,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => Icon(
                Icons.broken_image,
                size: width * 0.8,
                color: Colors.red,
              ),
        );
      }
      final cleanBase64 = source.contains(',') ? source.split(',').last : source;
      return Image.memory(
        base64Decode(cleanBase64),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Icon(
              Icons.broken_image,
              size: width * 0.8,
              color: Colors.red,
            ),
      );
    } catch (e) {
      return Icon(Icons.broken_image, size: width * 0.8, color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [adminOrange, Color(0xFFD57B2D)],
              ),
            ),
          ),
          const _BackgroundBlobs(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminTopHeader(
                  onBack: () => Navigator.pop(context),
                  onOpenDashboard:
                      () => Navigator.popUntil(context, (route) => route.isFirst),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Gestión de Materiales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Administra el catálogo de libros, consulta su información, controla la disponibilidad y gestiona las facultades.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Consumer<AdminMaterialViewModel>(
                      builder: (context, vm, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final esCompacto = constraints.maxWidth < 800;
                            if (esCompacto) {
                              return Column(
                                children: [
                                  Expanded(flex: 4, child: _buildListPanel(vm)),
                                  const SizedBox(height: 16),
                                  if (vm.materialSeleccionado != null)
                                    Expanded(
                                      flex: 6,
                                      child: _buildDetailPanel(vm, context),
                                    ),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 4, child: _buildListPanel(vm)),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 6,
                                  child:
                                      vm.materialSeleccionado == null
                                          ? Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                "Selecciona un libro para ver sus detalles",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          )
                                          : _buildDetailPanel(vm, context),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                _Footer(onTerms: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListPanel(AdminMaterialViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          _buildCategorySection(vm),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar libro...",
                prefixIcon: const Icon(Icons.search, color: unimetBlue),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: vm.filtrarMateriales,
            ),
          ),
          Expanded(
            child:
                vm.isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: adminOrange),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      itemCount: vm.materiales.length,
                      separatorBuilder:
                          (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                      itemBuilder: (context, index) {
                        final libro = vm.materiales[index];
                        final esSeleccionado =
                            vm.materialSeleccionado?['id'] == libro['id'];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _buildSafeImage(libro['imageUrl']),
                          ),
                          title: Text(
                            libro['title'] ?? 'Sin título',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${libro['author'] ?? 'Autor desconocido'} • ${libro['category'] ?? 'Sin categoría'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: esSeleccionado,
                          selectedTileColor: adminOrange.withOpacity(0.1),
                          onTap: () => vm.seleccionarMaterial(libro),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(AdminMaterialViewModel vm) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: unimetBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gestión de facultades',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: unimetBlue,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoAgregarCategoria(context, vm),
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Puedes crear, renombrar o eliminar facultades. Al renombrarlas, todos los libros asociados se actualizan automáticamente. La categoría Otros siempre debe existir.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (vm.categorias.isEmpty)
            const Text(
              'No hay facultades registradas.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  vm.categorias.map((categoria) {
                    final esOtros = categoria.trim().toLowerCase() == 'otros';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: unimetBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: unimetBlue.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            categoria,
                            style: const TextStyle(
                              color: unimetBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap:
                                esOtros
                                    ? null
                                    : () => _mostrarDialogoRenombrarCategoria(
                                      context,
                                      vm,
                                      categoria,
                                    ),
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.edit,
                                size: 18,
                                color: esOtros ? Colors.grey : unimetBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap:
                                esOtros
                                    ? null
                                    : () => _confirmarEliminarCategoria(
                                      context,
                                      vm,
                                      categoria,
                                    ),
                            borderRadius: BorderRadius.circular(30),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: esOtros ? Colors.grey : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  void _mostrarDialogoAgregarCategoria(
    BuildContext context,
    AdminMaterialViewModel vm,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Agregar facultad',
              style: TextStyle(
                color: unimetBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ej: Medicina, Arquitectura...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    await vm.agregarCategoria(controller.text);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Facultad creada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogoRenombrarCategoria(
    BuildContext context,
    AdminMaterialViewModel vm,
    String categoriaActual,
  ) {
    final controller = TextEditingController(text: categoriaActual);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Renombrar facultad',
              style: TextStyle(
                color: unimetBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Nuevo nombre de la facultad',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: unimetBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    await vm.renombrarCategoria(
                      categoriaActual,
                      controller.text,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Facultad renombrada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
    );
  }

  void _confirmarEliminarCategoria(
    BuildContext context,
    AdminMaterialViewModel vm,
    String categoria,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Eliminar facultad',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Se eliminará la facultad "$categoria" y todos los libros asociados.\n\n'
              'Solo se permitirá si todos los libros de esa facultad están disponibles.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await vm.eliminarCategoria(categoria);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Facultad "$categoria" eliminada correctamente',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailPanel(
    AdminMaterialViewModel vm,
    BuildContext context,
  ) {
    final libro = vm.materialSeleccionado!;
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildSafeImage(
                    libro['imageUrl'],
                    width: 100,
                    height: 150,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libro['title'] ?? 'Sin Título',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: unimetBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Autor: ${libro['author']}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _statusChip(libro['status'] ?? 'desconocido'),
                    ],
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(),
            ),
            const Text(
              "Información General",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: unimetBlue,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow("Categoría", libro['category']),
            const SizedBox(height: 8),
            _infoRow("Materia", libro['subject']),
            const SizedBox(height: 8),
            _infoRow("ID del Documento", libro['id']),
            const SizedBox(height: 8),
            _infoRow(
              "Condición/Estado",
              libro['condition'] ?? 'No especificada',
            ),
            const SizedBox(height: 20),
            const Text(
              "Descripción",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: unimetBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              libro['description'] ?? 'Sin descripción disponible',
              style: const TextStyle(color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoEdicion(context, vm, libro),
                    icon: const Icon(Icons.edit),
                    label: const Text("Editar Detalle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: unimetBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarEliminacion(context, vm),
                    icon: const Icon(Icons.delete),
                    label: const Text("Eliminar Libro"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final bool esDisponible = status.toLowerCase() == 'disponible';
    final Color colorBg =
        esDisponible ? Colors.green.shade50 : Colors.red.shade50;
    final Color colorTxt =
        esDisponible ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: colorTxt,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: unimetBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEdicion(
    BuildContext context,
    AdminMaterialViewModel vm,
    Map<String, dynamic> libro,
  ) {
    final titleCtrl = TextEditingController(text: libro['title']);
    final authorCtrl = TextEditingController(text: libro['author']);
    final categoryCtrl = TextEditingController(text: libro['category']);
    final subjectCtrl = TextEditingController(text: libro['subject']);
    final statusCtrl = TextEditingController(text: libro['status']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Editar Material",
            style: TextStyle(
              color: unimetBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Autor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Materia',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: statusCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: unimetBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    authorCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "El título y el autor no pueden estar vacíos",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final updatedData = {
                  'title': titleCtrl.text.trim(),
                  'author': authorCtrl.text.trim(),
                  'category': categoryCtrl.text.trim(),
                  'subject': subjectCtrl.text.trim(),
                  'status': statusCtrl.text.trim(),
                };

                try {
                  await vm.actualizarMaterial(libro['id'], updatedData);

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Material actualizado exitosamente"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error al actualizar: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                "Guardar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminacion(
    BuildContext context,
    AdminMaterialViewModel vm,
  ) async {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              "Eliminar material",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Esta acción no se puede deshacer. Solo se permiten borrar libros 'disponibles'.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await vm.eliminarSeleccionado();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Libro eliminado",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  "Eliminar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

class _AdminTopHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenDashboard;

  const _AdminTopHeader({
    required this.onBack,
    required this.onOpenDashboard,
  });

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _mostrarMenuAdmin(BuildContext context) async {
    final value = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 90, 20, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      items: const [
        PopupMenuItem(
          value: 'dashboard',
          child: Row(
            children: [
              Icon(Icons.dashboard, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Dashboard'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'perfiles',
          child: Row(
            children: [
              Icon(Icons.people, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Gestión de Usuarios'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'materiales',
          child: Row(
            children: [
              Icon(Icons.book, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Gestión de Material'),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'dashboard') {
      onOpenDashboard();
      return;
    } else if (value == 'perfiles') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChangeNotifierProvider(
                create: (_) => AdminUserManagementViewModel(),
                child: const AdminUserManagementPage(),
              ),
        ),
      );
    } else if (value == 'materiales') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChangeNotifierProvider(
                create: (_) => AdminMaterialViewModel(AdminMaterialService()),
                child: const AdminMaterialManagementPage(),
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                tooltip: 'Volver',
              ),
              const SizedBox(width: 4),
              const Icon(Icons.menu_book, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              const Text(
                'BookLoop ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3A57),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/publish'),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Publicar material',
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const ChatListPage()));
                },
                tooltip: 'Mis chats y notificaciones',
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
                },
                tooltip: 'Mi perfil',
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_suggest,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => _mostrarMenuAdmin(context),
                tooltip: 'Mostrar menú',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder:
                    (context) => const [
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Color(0xFF1B3A57)),
                            SizedBox(width: 10),
                            Text('Cerrar sesión'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onTerms;
  const _Footer({required this.onTerms});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Text(
            '© BookLoop • UNIMET',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const Spacer(),
          TextButton(
            onPressed: onTerms,
            child: const Text(
              'Términos y condiciones',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlobPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.1), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.3), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.9), 180, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}