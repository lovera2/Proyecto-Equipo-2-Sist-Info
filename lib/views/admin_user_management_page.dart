import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'chat_list_page.dart';
import 'profile_page.dart';

import '../viewmodels/admin_user_management_viewmodel.dart';
import '../viewmodels/admin_material_viewmodel.dart';
import '../services/admin_material_service.dart';
import 'admin_dashboard_page.dart';
import 'admin_material_management_page.dart';
import 'home(admin)_page.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);
  static const Color adminOrange = Color(0xFFE58A34);

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminUserManagementViewModel>().cargarUsuarios();
    });
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

  Future<void> _confirmarSuspension(BuildContext context) async {
    final vm = context.read<AdminUserManagementViewModel>();
    final usuario = vm.usuarioSeleccionado;
    if (usuario == null) return;

    final nombre = _nombreCompleto(usuario);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Suspender cuenta',
          style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Deseas suspender la cuenta de $nombre?\n\n'
          'Mientras esté suspendida, no podrá iniciar sesión ni usar la plataforma.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Suspender',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final mensaje = await vm.suspenderUsuarioSeleccionado();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje ?? 'Cuenta suspendida correctamente'),
        backgroundColor: mensaje != null &&
                mensaje.toLowerCase().contains('no se puede')
            ? Colors.red
            : unimetBlue,
      ),
    );
  }

  Future<void> _confirmarReactivacion(BuildContext context) async {
    final vm = context.read<AdminUserManagementViewModel>();
    final usuario = vm.usuarioSeleccionado;
    if (usuario == null) return;

    final nombre = _nombreCompleto(usuario);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Reactivar cuenta',
          style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold),
        ),
        content: Text('¿Deseas reactivar la cuenta de $nombre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reactivar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final mensaje = await vm.reactivarUsuarioSeleccionado();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje ?? 'Cuenta reactivada correctamente'),
        backgroundColor: unimetBlue,
      ),
    );
  }

  Future<void> _confirmarEliminacion(BuildContext context) async {
    final vm = context.read<AdminUserManagementViewModel>();
    final usuario = vm.usuarioSeleccionado;
    if (usuario == null) return;

    final nombre = _nombreCompleto(usuario);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Vas a proceder a eliminar la cuenta de $nombre.\n\n'
          'Esta acción borra también todos los materiales publicados por este usuario y es permanente.\n\n'
          'Además, borra todo rastro del usuario en la aplicación, incluyendo el material que haya publicado, y no puede realizarse si tiene préstamos o solicitudes activas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final mensaje = await vm.eliminarUsuarioSeleccionado();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje ?? 'Cuenta eliminada correctamente'),
        backgroundColor: mensaje != null &&
                mensaje.toLowerCase().contains('no se puede')
            ? Colors.red
            : unimetBlue,
      ),
    );
  }

  String _nombreCompleto(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final nombre = (mapa['nombre'] ?? '').toString().trim();
    final apellido = (mapa['apellido'] ?? '').toString().trim();

    if (nombre.isEmpty && apellido.isEmpty) return 'Usuario';
    if (nombre.isEmpty) return apellido;
    if (apellido.isEmpty) return nombre;
    return '$nombre $apellido';
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final h = MediaQuery.of(dialogContext).size.height;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Términos y Condiciones",
            style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 520,
            height: h * 0.62,
            child: const SingleChildScrollView(
              child: Text(
                "Al usar BookLoop aceptas lo siguiente:\n\n"
                "1) Acceso y verificación\n"
                "• Solo se permite el uso de correos institucionales UNIMET (docente y estudiante).\n"
                "• La cuenta es personal e intransferible.\n\n"
                "2) Uso responsable\n"
                "• Mantén un trato respetuoso en publicaciones y mensajes.\n"
                "• Está prohibido publicar contenido ofensivo, engañoso o spam.\n"
                "• BookLoop puede limitar o suspender cuentas ante evidencias de abuso.\n\n"
                "3) Préstamos y devoluciones\n"
                "• Al solicitar/aceptar un préstamo te comprometes a cumplir fecha, condiciones y lugar acordados.\n"
                "• Quien recibe el material es responsable de cuidarlo y devolverlo en el estado acordado.\n"
                "• En caso de pérdida o daño, las partes deben coordinar una solución (reposición o acuerdo).\n\n"
                "4) Seguridad y reportes\n"
                "• BookLoop puede limitar funciones (publicar/solicitar) si detecta patrones de incumplimiento.\n\n"
                "5) Privacidad y datos\n"
                "• Se almacenan datos mínimos para operar la plataforma.\n"
                "• No se publican datos sensibles.\n\n"
                "6) Alcance del servicio\n"
                "• BookLoop es una herramienta de coordinación; no garantiza la disponibilidad de material.\n"
                "• La UNIMET y el equipo de BookLoop no se responsabilizan por acuerdos fuera de la plataforma.\n",
                style: TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Entendido", style: TextStyle(color: unimetOrange)),
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
          const _AdminBackgroundBlobs(),
          SafeArea(
            child: Consumer<AdminUserManagementViewModel>(
              builder: (context, vm, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdminTopHeader(
                      onGoHome: () => _goHome(context),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Gestión de usuarios',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Administra cuentas, consulta su información y controla el acceso a la plataforma.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final esCompacto = constraints.maxWidth < 1100;

                            if (esCompacto) {
                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 520,
                                      child: _UsersListPanel(
                                        searchController: _searchController,
                                        onSearchChanged: vm.setBusqueda,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _UserDetailPanel(
                                      onSuspender: () =>
                                          _confirmarSuspension(context),
                                      onReactivar: () =>
                                          _confirmarReactivacion(context),
                                      onEliminar: () =>
                                          _confirmarEliminacion(context),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _UsersListPanel(
                                    searchController: _searchController,
                                    onSearchChanged: vm.setBusqueda,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 5,
                                  child: _UserDetailPanel(
                                    onSuspender: () =>
                                        _confirmarSuspension(context),
                                    onReactivar: () =>
                                        _confirmarReactivacion(context),
                                    onEliminar: () =>
                                        _confirmarEliminacion(context),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    _AdminFooter(onTerms: () => _showTermsDialog(context)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersListPanel extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  const _UsersListPanel({
    required this.searchController,
    required this.onSearchChanged,
  });

  String _nombreCompleto(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final nombre = (mapa['nombre'] ?? '').toString().trim();
    final apellido = (mapa['apellido'] ?? '').toString().trim();

    if (nombre.isEmpty && apellido.isEmpty) return 'Usuario';
    if (nombre.isEmpty) return apellido;
    if (apellido.isEmpty) return nombre;
    return '$nombre $apellido';
  }

  String _estado(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final status = (mapa['status'] ?? 'activo').toString().trim().toLowerCase();
    return status == 'suspendido' ? 'Suspendido' : 'Activo';
  }

  Color _estadoBg(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final status = (mapa['status'] ?? 'activo').toString().trim().toLowerCase();
    return status == 'suspendido' ? Colors.red.shade100 : Colors.green.shade100;
  }

  Color _estadoText(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final status = (mapa['status'] ?? 'activo').toString().trim().toLowerCase();
    return status == 'suspendido' ? Colors.red.shade700 : Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminUserManagementViewModel>();
    final usuarios = vm.usuariosFiltrados;
    final seleccionado = vm.usuarioSeleccionado;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Usuarios',
                  style: TextStyle(
                    color: unimetBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, correo o usuario',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6B7280),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE58A34),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: unimetOrange),
                  )
                : usuarios.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            vm.errorMessage != null && vm.errorMessage!.trim().isNotEmpty
                                ? vm.errorMessage!
                                : 'No se encontraron usuarios',
                            style: TextStyle(
                              color: vm.errorMessage != null && vm.errorMessage!.trim().isNotEmpty
                                  ? Colors.red
                                  : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: usuarios.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final usuario = usuarios[index];
                          final seleccionadoMap =
                              seleccionado is Map<String, dynamic>
                                  ? seleccionado
                                  : <String, dynamic>{};
                          final usuarioMap = usuario is Map<String, dynamic>
                              ? usuario
                              : <String, dynamic>{};
                          final activo = seleccionado != null &&
                              (seleccionadoMap['uid'] ?? '').toString() ==
                                  (usuarioMap['uid'] ?? '').toString();

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => vm.seleccionarUsuario(usuario),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: activo
                                    ? unimetBlue.withOpacity(0.08)
                                    : const Color(0xFFF9FAFC),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: activo
                                      ? unimetBlue.withOpacity(0.35)
                                      : Colors.grey.withOpacity(0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        unimetOrange.withOpacity(0.15),
                                    child: Text(
                                      (usuarioMap['avatarEmoji'] ?? '🙂')
                                          .toString(),
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nombreCompleto(usuario),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: unimetBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          (usuarioMap['email'] ?? 'Sin correo')
                                              .toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _estadoBg(usuario),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _estado(usuario),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _estadoText(usuario),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserDetailPanel extends StatelessWidget {
  String _usuarioTexto(Map<String, dynamic> usuarioMap) {
    final username = (usuarioMap['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;

    final email = (usuarioMap['email'] ?? '').toString().trim();
    if (email.contains('@')) {
      return email.split('@').first.trim();
    }

    return 'No definido';
  }
  final VoidCallback onSuspender;
  final VoidCallback onReactivar;
  final VoidCallback onEliminar;

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  static const int maxNombreLen = 20;
  static const int maxApellidoLen = 20;
  static const int maxCarreraLen = 45;

  const _UserDetailPanel({
    required this.onSuspender,
    required this.onReactivar,
    required this.onEliminar,
  });

  String _nombreCompleto(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final nombre = (mapa['nombre'] ?? '').toString().trim();
    final apellido = (mapa['apellido'] ?? '').toString().trim();

    if (nombre.isEmpty && apellido.isEmpty) return 'Usuario';
    if (nombre.isEmpty) return apellido;
    if (apellido.isEmpty) return nombre;
    return '$nombre $apellido';
  }

  String _rolUsuario(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final email = (mapa['email'] ?? '').toString().toLowerCase().trim();

    if (email.startsWith('admin')) return 'Administrador';
    if (email.endsWith('@unimet.edu.ve')) return 'Docente';
    if (email.endsWith('@correo.unimet.edu.ve')) return 'Estudiante';

    final role = (mapa['role'] ?? mapa['rol'] ?? '').toString().trim();
    if (role.isNotEmpty) return role;

    return 'Usuario';
  }

  String _estadoUsuario(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final status = (mapa['status'] ?? 'activo').toString().trim().toLowerCase();
    return status == 'suspendido' ? 'Suspendido' : 'Activo';
  }

  Color _estadoBg(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final status = (mapa['status'] ?? 'activo').toString().trim().toLowerCase();
    return status == 'suspendido' ? Colors.red.shade100 : Colors.green.shade100;
  }

  Color _estadoText(dynamic usuario) {
    final mapa =
        (usuario is Map<String, dynamic>) ? usuario : <String, dynamic>{};
    final status = (mapa['status'] ?? 'activo').toString().trim().toLowerCase();
    return status == 'suspendido' ? Colors.red.shade700 : Colors.green.shade700;
  }

  String _fechaTexto(dynamic fecha) {
    if (fecha == null) return '—';

    try {
      final dt = fecha.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      try {
        final dt = DateTime.parse(fecha.toString());
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        return fecha.toString();
      }
    }
  }

  void _mostrarInfoActividad(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Actividad activa',
          style: TextStyle(
            color: unimetBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Indica si el usuario tiene préstamos o solicitudes activas dentro de la plataforma. '
          'Mientras tenga transacciones abiertas, no puede suspenderse ni eliminarse.',
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

  Future<void> _mostrarDialogoEditarUsuario(
    BuildContext context,
    AdminUserManagementViewModel vm,
    Map<String, dynamic> usuarioMap,
  ) async {
    final formKey = GlobalKey<FormState>();

    final nombreController =
        TextEditingController(text: (usuarioMap['nombre'] ?? '').toString());
    final apellidoController = TextEditingController(
      text: (usuarioMap['apellido'] ?? '').toString(),
    );
    final usernameController =
        TextEditingController(text: _usuarioTexto(usuarioMap));
    final cedulaController =
        TextEditingController(text: (usuarioMap['cedula'] ?? '').toString());
    final carreraController =
        TextEditingController(text: (usuarioMap['carrera'] ?? '').toString());

    String? mensajeLocal;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          void mostrarErrorLocal(String msg) {
            setDialogState(() => mensajeLocal = msg);
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Editar usuario',
              style: TextStyle(
                color: unimetBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        inputFormatters: [
                          _SnackRejectingFormatter(
                            allowPattern: RegExp(
                              r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü'\-\s]",
                            ),
                            onReject: () => mostrarErrorLocal(
                              'El nombre no acepta números ni símbolos.',
                            ),
                          ),
                          _MaxLengthSnackFormatter(
                            maxLength: maxNombreLen,
                            onMaxReached: () => mostrarErrorLocal(
                              'El nombre admite máximo $maxNombreLen caracteres.',
                            ),
                          ),
                        ],
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Campo obligatorio';
                          if (value.length < 2) return 'Mínimo 2 caracteres';
                          if (value.length > maxNombreLen) {
                            return 'Máximo $maxNombreLen caracteres';
                          }
                          if (!RegExp(
                            r"^[A-Za-zÁÉÍÓÚáéíóúÑñÜü]+(?:[ '\-][A-Za-zÁÉÍÓÚáéíóúÑñÜü]+)*$",
                          ).hasMatch(value)) {
                            return 'Solo letras y espacios';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: apellidoController,
                        inputFormatters: [
                          _SnackRejectingFormatter(
                            allowPattern: RegExp(
                              r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü'\-\s]",
                            ),
                            onReject: () => mostrarErrorLocal(
                              'El apellido no acepta números ni símbolos.',
                            ),
                          ),
                          _MaxLengthSnackFormatter(
                            maxLength: maxApellidoLen,
                            onMaxReached: () => mostrarErrorLocal(
                              'El apellido admite máximo $maxApellidoLen caracteres.',
                            ),
                          ),
                        ],
                        decoration: const InputDecoration(labelText: 'Apellido'),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Campo obligatorio';
                          if (value.length < 2) return 'Mínimo 2 caracteres';
                          if (value.length > maxApellidoLen) {
                            return 'Máximo $maxApellidoLen caracteres';
                          }
                          if (!RegExp(
                            r"^[A-Za-zÁÉÍÓÚáéíóúÑñÜü]+(?:[ '\-][A-Za-zÁÉÍÓÚáéíóúÑñÜü]+)*$",
                          ).hasMatch(value)) {
                            return 'Solo letras y espacios';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameController,
                        inputFormatters: [
                          _SnackRejectingFormatter(
                            allowPattern: RegExp(r'[A-Za-z0-9._]'),
                            onReject: () => mostrarErrorLocal(
                              'El usuario solo acepta letras, números, punto y guion bajo.',
                            ),
                          ),
                          _MaxLengthSnackFormatter(
                            maxLength: 20,
                            onMaxReached: () => mostrarErrorLocal(
                              'El usuario admite máximo 20 caracteres.',
                            ),
                          ),
                        ],
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Campo obligatorio';
                          if (value.length < 3) return 'Mínimo 3 caracteres';
                          if (value.length > 20) return 'Máximo 20 caracteres';
                          if (!RegExp(r'^[A-Za-z0-9._]+$').hasMatch(value)) {
                            return 'Solo letras, números, punto y guion bajo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cedulaController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          _SnackRejectingFormatter(
                            allowPattern: RegExp(r'[0-9]'),
                            onReject: () => mostrarErrorLocal(
                              'La cédula solo acepta números.',
                            ),
                          ),
                          _MaxLengthSnackFormatter(
                            maxLength: 8,
                            onMaxReached: () => mostrarErrorLocal(
                              'La cédula admite máximo 8 dígitos.',
                            ),
                          ),
                        ],
                        decoration: const InputDecoration(labelText: 'Cédula'),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Campo obligatorio';
                          if (!RegExp(r'^\d{6,8}$').hasMatch(value)) {
                            return 'Solo números (6 a 8 dígitos)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: carreraController,
                        inputFormatters: [
                          _SnackRejectingFormatter(
                            allowPattern: RegExp(
                              r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü\s/\-\.]",
                            ),
                            onReject: () => mostrarErrorLocal(
                              'La carrera no acepta números ni símbolos como @.',
                            ),
                          ),
                          _MaxLengthSnackFormatter(
                            maxLength: maxCarreraLen,
                            onMaxReached: () => mostrarErrorLocal(
                              'La carrera admite máximo $maxCarreraLen caracteres.',
                            ),
                          ),
                        ],
                        decoration: const InputDecoration(labelText: 'Carrera'),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Campo obligatorio';
                          if (value.length < 3) return 'Mínimo 3 caracteres';
                          if (value.length > maxCarreraLen) {
                            return 'Máximo $maxCarreraLen caracteres';
                          }
                          if (!RegExp(
                            r"^(?=.*[A-Za-zÁÉÍÓÚáéíóúÑñÜü])[A-Za-zÁÉÍÓÚáéíóúÑñÜü\s/\-\.]+$",
                          ).hasMatch(value)) {
                            return 'Solo letras y separadores (/, -, .)';
                          }
                          return null;
                        },
                      ),
                      if (mensajeLocal != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            mensajeLocal!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: unimetBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setDialogState(() => mensajeLocal = null);
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'Guardar cambios',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    final mensaje = await vm.editarUsuarioSeleccionado(
      nombre: nombreController.text,
      apellido: apellidoController.text,
      username: usernameController.text,
      cedula: cedulaController.text,
      carrera: carreraController.text,
    );

    if (!context.mounted) return;

    if (mensaje != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'No se pudo guardar',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario actualizado correctamente'),
        backgroundColor: unimetBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminUserManagementViewModel>();
    final usuario = vm.usuarioSeleccionado;
    final usuarioMap =
        usuario is Map<String, dynamic> ? usuario : <String, dynamic>{};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: usuario == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'Selecciona un usuario para ver su información',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compacto = constraints.maxWidth < 760;

                        if (compacto) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 34,
                                    backgroundColor:
                                        unimetOrange.withOpacity(0.18),
                                    child: Text(
                                      (usuarioMap['avatarEmoji'] ?? '🙂')
                                          .toString(),
                                      style:
                                          const TextStyle(fontSize: 30),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _estadoBg(usuario),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _estadoUsuario(usuario),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _estadoText(usuario),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _nombreCompleto(usuario),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: unimetBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (usuarioMap['email'] ?? 'Sin correo')
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor:
                                  unimetOrange.withOpacity(0.18),
                              child: Text(
                                (usuarioMap['avatarEmoji'] ?? '🙂').toString(),
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nombreCompleto(usuario),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: unimetBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (usuarioMap['email'] ?? 'Sin correo')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _estadoBg(usuario),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _estadoUsuario(usuario),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _estadoText(usuario),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Información del usuario',
                      style: TextStyle(
                        color: unimetBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final anchoDisponible = constraints.maxWidth;
                        final double anchoTarjeta;
                        if (anchoDisponible >= 1000) {
                          anchoTarjeta = (anchoDisponible - 24) / 3;
                        } else if (anchoDisponible >= 640) {
                          anchoTarjeta = (anchoDisponible - 12) / 2;
                        } else {
                          anchoTarjeta = anchoDisponible;
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: anchoTarjeta,
                              child: _InfoBox(
                                label: 'Usuario',
                                value: _usuarioTexto(usuarioMap),
                              ),
                            ),
                            SizedBox(
                              width: anchoTarjeta,
                              child: _InfoBox(
                                label: 'Rol',
                                value: _rolUsuario(usuario),
                              ),
                            ),
                            SizedBox(
                              width: anchoTarjeta,
                              child: _InfoBox(
                                label: 'Cédula',
                                value: (usuarioMap['cedula'] ?? '—').toString(),
                              ),
                            ),
                            SizedBox(
                              width: anchoTarjeta,
                              child: _InfoBox(
                                label: 'Carrera',
                                value: (usuarioMap['carrera'] ?? '—').toString(),
                              ),
                            ),
                            SizedBox(
                              width: anchoTarjeta,
                              child: _InfoBox(
                                label: 'Fecha de registro',
                                value: _fechaTexto(
                                  usuarioMap['fechaRegistro'] ??
                                      usuarioMap['fecha_registro'],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: anchoTarjeta,
                              child: _InfoBox(
                                label: 'Libros publicados',
                                value: (usuarioMap['librosPublicados'] ?? 0)
                                    .toString(),
                              ),
                            ),
                            SizedBox(
                              width: anchoTarjeta,
                              child: _InfoBox(
                                label: 'Actividad activa',
                                value: ((usuarioMap['tieneActividadActiva'] ??
                                            false) ==
                                        true)
                                    ? 'Sí'
                                    : 'No',
                                trailing: IconButton(
                                  onPressed: () =>
                                      _mostrarInfoActividad(context),
                                  icon: const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                  tooltip: 'Qué significa actividad activa',
                                  splashRadius: 18,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Edición rápida',
                      style: TextStyle(
                        color: unimetBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: vm.isProcessing
                          ? null
                          : () => _mostrarDialogoEditarUsuario(
                                context,
                                vm,
                                usuarioMap,
                              ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar información del usuario'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: unimetBlue,
                        side: BorderSide(color: unimetBlue.withOpacity(0.25)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Acciones administrativas',
                      style: TextStyle(
                        color: unimetBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if ((usuarioMap['tieneActividadActiva'] ?? false) == true)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Text(
                          'Este usuario no puede ni suspenderse ni eliminarse hasta cerrar las transacciones activas.',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    Builder(
                      builder: (context) {
                        final statusActual = (usuarioMap['status'] ?? 'activo')
                            .toString()
                            .trim()
                            .toLowerCase();
                        final estaSuspendido = statusActual == 'suspendido';

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (!estaSuspendido)
                              ElevatedButton.icon(
                                onPressed:
                                    vm.isProcessing ? null : onSuspender,
                                icon: const Icon(
                                  Icons.pause_circle_outline,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Suspender cuenta',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            if (estaSuspendido)
                              ElevatedButton.icon(
                                onPressed:
                                    vm.isProcessing ? null : onReactivar,
                                icon: const Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Reactivar cuenta',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: vm.isProcessing ? null : onEliminar,
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Eliminar cuenta',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (vm.isProcessing) ...[
                      const SizedBox(height: 18),
                      const Center(
                        child: CircularProgressIndicator(color: unimetOrange),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoBox({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1B3A57),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
class _AdminTopHeader extends StatelessWidget {
  final VoidCallback onGoHome;

  const _AdminTopHeader({required this.onGoHome});

  static const Color adminOrange = Color(0xFFE58A34);

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _mostrarMenuAdmin(BuildContext context) async {
    final value = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 90, 20, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const _AdminDashboardShellFromUsers(),
        ),
      );
      return;
    }

    if (value == 'perfiles') {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Ya estás en Gestión de Usuarios.'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    if (value == 'materiales') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
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
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
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
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 28,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder: (context) => const [
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

class _AdminBackgroundBlobs extends StatelessWidget {
  const _AdminBackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AdminBlobPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _AdminBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.10), 120, p);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.34), 170, p);
    canvas.drawCircle(Offset(size.width * 0.30, size.height * 0.86), 150, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdminFooter extends StatelessWidget {
  final VoidCallback onTerms;

  const _AdminFooter({required this.onTerms});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Text(
            '© BookLoop • UNIMET',
            style: TextStyle(color: Colors.white70, fontSize: 12),
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

class _SnackRejectingFormatter extends TextInputFormatter {
  final RegExp allowPattern;
  final VoidCallback onReject;

  _SnackRejectingFormatter({
    required this.allowPattern,
    required this.onReject,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final original = newValue.text;
    final filtered = StringBuffer();

    bool rejected = false;
    for (final rune in original.runes) {
      final ch = String.fromCharCode(rune);
      if (allowPattern.hasMatch(ch)) {
        filtered.write(ch);
      } else {
        rejected = true;
      }
    }

    if (rejected) {
      onReject();
    }

    final resultText = filtered.toString();
    if (resultText == original) return newValue;

    final base = newValue.selection.baseOffset;
    final extent = newValue.selection.extentOffset;
    final clampedBase = base.clamp(0, resultText.length);
    final clampedExtent = extent.clamp(0, resultText.length);

    return TextEditingValue(
      text: resultText,
      selection: TextSelection(
        baseOffset: clampedBase,
        extentOffset: clampedExtent,
      ),
      composing: TextRange.empty,
    );
  }
}

class _MaxLengthSnackFormatter extends TextInputFormatter {
  final int maxLength;
  final VoidCallback onMaxReached;

  _MaxLengthSnackFormatter({
    required this.maxLength,
    required this.onMaxReached,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= maxLength) return newValue;

    onMaxReached();

    final truncated = newValue.text.substring(0, maxLength);
    final base = newValue.selection.baseOffset.clamp(0, truncated.length);
    final extent = newValue.selection.extentOffset.clamp(0, truncated.length);

    return TextEditingValue(
      text: truncated,
      selection: TextSelection(baseOffset: base, extentOffset: extent),
      composing: TextRange.empty,
    );
  }
}
class _AdminDashboardShellFromUsers extends StatelessWidget {
  const _AdminDashboardShellFromUsers();

  static const Color unimetOrange = Color(0xFFF28B31);

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
                colors: [unimetOrange, Color(0xFFD67628)],
              ),
            ),
          ),
          const _AdminBackgroundBlobs(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AdminDashboardView(
                    onBack: () => Navigator.pop(context),
                    onOpenMenu: () async {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}