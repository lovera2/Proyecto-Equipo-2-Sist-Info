import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'home(admin)_page.dart';
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

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeAdminPage(),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  String _normalizarCategoriaLocal(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  String _normalizarStatus(String raw) {
    return raw
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  bool _esStatusTerminalChat(String statusNormalizado) {
    return [
      'rechazado',
      'cancelado',
      'cerrado',
      'finalizado',
      'completado',
      'devuelto',
    ].contains(statusNormalizado);
  }

  String _labelStatus(String statusNormalizado) {
    switch (statusNormalizado) {
      case 'pendiente':
      case 'solicitado':
      case 'esperando_confirmacion':
      case 'reservado':
        return 'reservado';
      case 'rentado':
      case 'en_prestamo':
        return 'en_prestamo';
      case 'devolucion_pendiente':
        return 'devolucion_pendiente';
      case 'rechazado':
      case 'cancelado':
      case 'cerrado':
      case 'finalizado':
      case 'completado':
      case 'devuelto':
        return 'disponible';
      default:
        return statusNormalizado.isEmpty ? 'desconocido' : statusNormalizado;
    }
  }

  String _resolverStatusEfectivo({
    required String materialStatus,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> chats,
  }) {
    String statusMaterialNormalizado = _normalizarStatus(materialStatus);

    for (final doc in chats) {
      final chatStatus = _normalizarStatus((doc.data()['status'] ?? '').toString());
      if (!_esStatusTerminalChat(chatStatus)) {
        return _labelStatus(chatStatus);
      }
    }

    return _labelStatus(statusMaterialNormalizado);
  }

  Stream<String> _streamStatusEfectivoMaterial(String materialId) {
    final materialRef = FirebaseFirestore.instance
        .collection('materials')
        .doc(materialId);

    final chatsRef = FirebaseFirestore.instance
        .collection('chats')
        .where('materialId', isEqualTo: materialId);

    late final StreamController<String> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? materialSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? chatsSub;

    String materialStatus = 'desconocido';
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chats = [];

    void emitirStatus() {
      if (!controller.isClosed) {
        controller.add(
          _resolverStatusEfectivo(
            materialStatus: materialStatus,
            chats: chats,
          ),
        );
      }
    }

    controller = StreamController<String>(
      onListen: () {
        materialSub = materialRef.snapshots().listen((materialSnap) {
          final materialData = materialSnap.data();
          materialStatus =
              (materialData?['status'] ?? 'desconocido').toString();
          emitirStatus();
        });

        chatsSub = chatsRef.snapshots().listen((chatsSnap) {
          chats = chatsSnap.docs;
          emitirStatus();
        });
      },
      onCancel: () async {
        await materialSub?.cancel();
        await chatsSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<String> _obtenerStatusEfectivoActual(String materialId) async {
    final materialSnap = await FirebaseFirestore.instance
        .collection('materials')
        .doc(materialId)
        .get();

    final chatsSnap = await FirebaseFirestore.instance
        .collection('chats')
        .where('materialId', isEqualTo: materialId)
        .get();

    final materialData = materialSnap.data();
    final materialStatus = (materialData?['status'] ?? 'desconocido').toString();

    return _resolverStatusEfectivo(
      materialStatus: materialStatus,
      chats: chatsSnap.docs,
    );
  }

  Future<String> _obtenerStatusEfectivoMaterialEnCategoria(
    Map<String, dynamic> material,
  ) async {
    final materialId = (material['id'] ?? '').toString();
    if (materialId.isEmpty) return 'desconocido';
    return _obtenerStatusEfectivoActual(materialId);
  }

  Future<Map<String, String>?> _buscarPrimerBloqueoCategoria(
    String categoria,
  ) async {
    final snapshot = await FirebaseFirestore.instance.collection('materials').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final categoriaMaterial = (data['category'] ?? '').toString();

      if (_normalizarCategoriaLocal(categoriaMaterial) !=
          _normalizarCategoriaLocal(categoria)) {
        continue;
      }

      final material = Map<String, dynamic>.from(data);
      material['id'] = doc.id;

      final statusEfectivo = await _obtenerStatusEfectivoMaterialEnCategoria(material);

      if (_normalizarStatus(statusEfectivo) != 'disponible') {
        return {
          'titulo': (material['title'] ?? 'Este libro').toString(),
          'status': statusEfectivo,
        };
      }
    }

    return null;
  }

  Future<void> _mostrarBloqueoEliminacion(
    BuildContext context,
    String titulo,
    String statusActual,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Acción denegada',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'No puedes eliminar "$titulo" porque actualmente su estado es "$statusActual".\n\nSolo se pueden eliminar libros que estén realmente disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
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

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final h = MediaQuery.of(dialogContext).size.height;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Términos y Condiciones',
            style: TextStyle(
              color: unimetBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 520,
            height: h * 0.62,
            child: const SingleChildScrollView(
              child: Text(
                'Al usar BookLoop aceptas lo siguiente:\n\n'
                '1) Acceso y verificación\n'
                '• Solo se permite el uso de correos institucionales UNIMET (docente y estudiante).\n'
                '• La cuenta es personal e intransferible.\n\n'
                '2) Uso responsable\n'
                '• Mantén un trato respetuoso en publicaciones y mensajes.\n'
                '• Está prohibido publicar contenido ofensivo, engañoso o spam.\n'
                '• BookLoop puede limitar o suspender cuentas ante evidencias de abuso.\n\n'
                '3) Préstamos y devoluciones\n'
                '• Al solicitar/aceptar un préstamo te comprometes a cumplir fecha, condiciones y lugar acordados.\n'
                '• Quien recibe el material es responsable de cuidarlo y devolverlo en el estado acordado.\n'
                '• En caso de pérdida o daño, las partes deben coordinar una solución (reposición o acuerdo).\n\n'
                '4) Seguridad y reportes\n'
                '• BookLoop puede limitar funciones (publicar/solicitar) si detecta patrones de incumplimiento.\n\n'
                '5) Privacidad y datos\n'
                '• Se almacenan datos mínimos para operar la plataforma.\n'
                '• No se publican datos sensibles.\n\n'
                '6) Alcance del servicio\n'
                '• BookLoop es una herramienta de coordinación; no garantiza la disponibilidad de material.\n'
                '• La UNIMET y el equipo de BookLoop no se responsabilizan por acuerdos fuera de la plataforma.\n',
                style: TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Entendido',
                style: TextStyle(color: adminOrange),
              ),
            ),
          ],
        );
      },
    );
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
                  onGoHome: () => _goHome(context),
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
                        'Administra el catálogo de libros, consulta su información, controla la disponibilidad y gestiona las categorías.',
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
                _Footer(onTerms: () => _showTermsDialog(context)),
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
              const Icon(Icons.category, color: unimetBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gestión de categorías',
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
            'Las categorías base no se pueden borrar. Las categorías creadas solo pueden eliminarse si ninguno de sus libros está reservado, en préstamo o comprometido en una solicitud activa.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (vm.categorias.isEmpty)
            const Text(
              'No hay categorías registradas.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  vm.categorias.map((categoria) {
                    final esBase = vm.esCategoriaBase(categoria);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            esBase
                                ? Colors.grey.shade200
                                : unimetBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              esBase
                                  ? Colors.grey.shade300
                                  : unimetBlue.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            categoria,
                            style: TextStyle(
                              color: esBase ? Colors.black54 : unimetBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!esBase) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap:
                                  () => _mostrarDialogoRenombrarCategoria(
                                    context,
                                    vm,
                                    categoria,
                                  ),
                              borderRadius: BorderRadius.circular(30),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: unimetBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap:
                                  () => _confirmarEliminarCategoria(
                                    context,
                                    vm,
                                    categoria,
                                  ),
                              borderRadius: BorderRadius.circular(30),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
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
    String? mensajeError;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: const Text(
                  'Agregar categoría',
                  style: TextStyle(
                    color: unimetBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Medicina, Arquitectura...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (mensajeError != null) {
                          setDialogState(() => mensajeError = null);
                        }
                      },
                    ),
                    if (mensajeError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          mensajeError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: adminOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final texto = controller.text.trim();

                      if (texto.isEmpty) {
                        setDialogState(() {
                          mensajeError =
                              'Debes escribir un nombre para crear la categoría.';
                        });
                        return;
                      }

                      final normalizadaNueva = _normalizarCategoriaLocal(texto);
                      final yaExisteEnVista = vm.categorias.any(
                        (categoria) =>
                            _normalizarCategoriaLocal(categoria) ==
                            normalizadaNueva,
                      );

                      if (yaExisteEnVista) {
                        setDialogState(() {
                          mensajeError =
                              'Esa categoría ya existe. No se puede crear una categoría con el mismo nombre.';
                        });
                        return;
                      }

                      try {
                        await vm.agregarCategoria(texto);

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Categoría creada correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        final mensaje = e.toString().replaceFirst(
                          'Exception: ',
                          '',
                        );

                        setDialogState(() {
                          if (mensaje.toLowerCase().contains(
                            'esa categoría ya existe',
                          )) {
                            mensajeError =
                                'Esa categoría ya existe. No se puede crear una categoría con el mismo nombre.';
                          } else {
                            mensajeError = mensaje;
                          }
                        });
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _mostrarDialogoRenombrarCategoria(
    BuildContext context,
    AdminMaterialViewModel vm,
    String categoriaActual,
  ) {
    final controller = TextEditingController(text: categoriaActual);
    String? mensajeError;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: const Text(
                  'Renombrar categoría',
                  style: TextStyle(
                    color: unimetBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Nuevo nombre de la categoría',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (mensajeError != null) {
                          setDialogState(() => mensajeError = null);
                        }
                      },
                    ),
                    if (mensajeError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          mensajeError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: unimetBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final nuevoNombre = controller.text.trim();

                      if (nuevoNombre.isEmpty) {
                        setDialogState(() {
                          mensajeError =
                              'Debes escribir un nombre válido para la categoría.';
                        });
                        return;
                      }

                      final normalizadaActual = _normalizarCategoriaLocal(
                        categoriaActual,
                      );
                      final normalizadaNueva = _normalizarCategoriaLocal(
                        nuevoNombre,
                      );

                      final yaExisteEnVista = vm.categorias.any(
                        (categoria) =>
                            _normalizarCategoriaLocal(categoria) ==
                                normalizadaNueva &&
                            _normalizarCategoriaLocal(categoria) !=
                                normalizadaActual,
                      );

                      if (yaExisteEnVista) {
                        setDialogState(() {
                          mensajeError =
                              'Ya existe una categoría con ese nombre.';
                        });
                        return;
                      }

                      try {
                        await vm.renombrarCategoria(
                          categoriaActual,
                          nuevoNombre,
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Categoría renombrada correctamente',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        final mensaje = e.toString().replaceFirst(
                          'Exception: ',
                          '',
                        );

                        setDialogState(() {
                          if (mensaje.toLowerCase().contains('ya existe')) {
                            mensajeError =
                                'Ya existe una categoría con ese nombre.';
                          } else {
                            mensajeError = mensaje;
                          }
                        });
                      }
                    },
                    child: const Text('Guardar cambios'),
                  ),
                ],
              );
            },
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
              'Eliminar categoría',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Se eliminará la categoría "$categoria" y todos los libros asociados.\n\n'
              'Esta acción solo se permitirá si ninguno de los libros de esa categoría está reservado, en préstamo o comprometido en una solicitud activa.',
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
                    final bloqueo = await _buscarPrimerBloqueoCategoria(categoria);

                    if (bloqueo != null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No se puede eliminar la categoría "$categoria" porque contiene uno o más libros reservados, en préstamo o comprometidos en una solicitud activa.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await vm.eliminarCategoria(categoria);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Categoría "$categoria" eliminada correctamente',
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
                      StreamBuilder<String>(
                        stream: _streamStatusEfectivoMaterial(
                          (libro['id'] ?? '').toString(),
                        ),
                        builder: (context, snapshot) {
                          final statusActual = snapshot.data ??
                              (libro['status'] ?? 'desconocido').toString();
                          return _statusChip(statusActual);
                        },
                      ),
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
                  child: StreamBuilder<String>(
                    stream: _streamStatusEfectivoMaterial(
                      (libro['id'] ?? '').toString(),
                    ),
                    builder: (context, snapshot) {
                      final statusActual = snapshot.data ??
                          (libro['status'] ?? 'desconocido').toString();
                      final puedeEliminar =
                          _normalizarStatus(statusActual) == 'disponible';

                      return ElevatedButton.icon(
                        onPressed:
                            puedeEliminar
                                ? () => _confirmarEliminacion(context, vm)
                                : () => _mostrarBloqueoEliminacion(
                                      context,
                                      (libro['title'] ?? 'Este libro').toString(),
                                      statusActual,
                                    ),
                        icon: const Icon(Icons.delete),
                        label: const Text("Eliminar Libro"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              puedeEliminar
                                  ? Colors.red.shade600
                                  : Colors.grey.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
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
    final statusNormalizado = _normalizarStatus(status);

    final bool esDisponible = statusNormalizado == 'disponible';
    final bool esReservado = [
      'pendiente',
      'solicitado',
      'esperando_confirmacion',
      'reservado',
    ].contains(statusNormalizado);
    final bool esPrestamo = [
      'rentado',
      'en_prestamo',
      'devolucion_pendiente',
    ].contains(statusNormalizado);

    final Color colorBg =
        esDisponible
            ? Colors.green.shade50
            : (esReservado ? Colors.amber.shade50 : Colors.red.shade50);

    final Color colorTxt =
        esDisponible
            ? Colors.green.shade700
            : (esReservado ? Colors.amber.shade800 : Colors.red.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _labelStatus(statusNormalizado).replaceAll('_', ' ').toUpperCase(),
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Editar Material',
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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
                        'El título y el autor no pueden estar vacíos',
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
                };

                try {
                  await vm.actualizarMaterial(libro['id'], updatedData);

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Material actualizado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Guardar',
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
    final libro = vm.materialSeleccionado;
    if (libro == null) return;

    final materialId = (libro['id'] ?? '').toString();
    final titulo = (libro['title'] ?? 'Este libro').toString();
    final statusActual = await _obtenerStatusEfectivoActual(materialId);

    if (!context.mounted) return;

    if (_normalizarStatus(statusActual) != 'disponible') {
      await _mostrarBloqueoEliminacion(context, titulo, statusActual);
      return;
    }

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
  static const Color adminOrange = Color(0xFFE58A34);
  final VoidCallback onGoHome;
  final VoidCallback onOpenDashboard;

  const _AdminTopHeader({
    required this.onGoHome,
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
              // Publicar (naranja)
              Container(
                decoration: BoxDecoration(
                  color: adminOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/publish'),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Publicar material',
                ),
              ),
              const SizedBox(width: 10),

              // Inicio
              IconButton(
                icon: const Icon(
                  Icons.home_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                tooltip: 'Inicio',
                onPressed: onGoHome,
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChatListPage(isAdmin: true),
                    ),
                  );
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

// El AdminMaterialManagementPage es una pantalla de administración que permite a los administradores gestionar los materiales disponibles en la plataforma. Incluye funcionalidades para visualizar, editar, eliminar materiales y gestionar categorías, con una interfaz intuitiva y moderna adaptada a las necesidades de los administradores.