// lib/views/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'donation_screen.dart';

import 'payment_page.dart';
import '../viewmodels/payment_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'edit_profile_page.dart';
import 'package:bookloop_unimet/views/chat_list_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_user_management_page.dart';
import 'admin_material_management_page.dart';
import '../viewmodels/admin_user_management_viewmodel.dart';
import '../viewmodels/admin_material_viewmodel.dart';
import '../services/admin_material_service.dart';
import 'favorites_list_page.dart';
import 'material_detail_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  bool _hasNewNotifications = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProfileViewModel>().cargarPerfil());
  }

  Future<void> _openEdit(BuildContext context) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );

    if (ok != true) return;
    if (!mounted) return;

    await context.read<ProfileViewModel>().cargarPerfil();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Perfil actualizado"),
        backgroundColor: unimetBlue,
      ),
    );
  }

  void _goHome(BuildContext context) {
    final email =
        (context.read<ProfileViewModel>().email ?? '').toLowerCase().trim();
    final route = email.startsWith('admin') ? '/home_admin' : '/home_page';
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
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
          builder: (_) => const _AdminDashboardShellFromProfile(),
        ),
      );
      return;
    } else if (value == 'perfiles') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AdminUserManagementViewModel(),
            child: const AdminUserManagementPage(),
          ),
        ),
      );
      return;
    } else if (value == 'materiales') {
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

  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Sesión cerrada"),
        backgroundColor: unimetBlue,
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
              child: const Text("Entendido",
                  style: TextStyle(color: unimetOrange)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final String emailActual =
        ((vm.email ?? FirebaseAuth.instance.currentUser?.email) ?? '')
            .toLowerCase()
            .trim();
    final bool effectiveIsAdmin = emailActual.startsWith('admin');
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: effectiveIsAdmin
                    ? const [unimetOrange, Color(0xFFD67628)]
                    : const [unimetBlue, Color(0xFF2C5E8C)],
              ),
            ),
          ),
          _BackgroundBlobs(isAdmin: effectiveIsAdmin),
          SafeArea(
            child: Column(
              children: [
                _ProfileHeader(
                  onEdit: () => _openEdit(context),
                  onHome: () => _goHome(context),
                  onProfile: () => Navigator.pushNamed(context, '/profile'),
                  onNotifications: () {
                    setState(() => _hasNewNotifications = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatListPage(isAdmin: effectiveIsAdmin),
                      ),
                    );
                  },
                  onCreate: () => Navigator.pushNamed(context, '/publish'),
                  onLogout: () => _handleLogout(context),
                  hasNewNotifications: _hasNewNotifications,
                  isAdmin: effectiveIsAdmin,
                  onAdminMenu: () => _mostrarMenuAdmin(context),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 980 : double.infinity,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _ProfileCard(
                          vm: vm,
                          onEdit: () => _openEdit(context),
                        ),
                      ),
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
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final VoidCallback onCreate;
  final VoidCallback onLogout;
  final bool hasNewNotifications;
  final bool isAdmin;
  final VoidCallback onAdminMenu;

  static const Color unimetOrange = Color(0xFFF28B31);

  const _ProfileHeader({
    required this.onEdit,
    required this.onHome,
    required this.onProfile,
    required this.onNotifications,
    required this.onCreate,
    required this.onLogout,
    required this.hasNewNotifications,
    required this.isAdmin,
    required this.onAdminMenu,
  });

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
                "BookLoop",
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
                  color: unimetOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Publicar material',
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.home_outlined,
                    color: Colors.white, size: 28),
                onPressed: onHome,
                tooltip: 'Inicio',
              ),
              const SizedBox(width: 10),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined,
                        color: Colors.white, size: 28),
                    onPressed: onNotifications,
                    tooltip: 'Mis chats y notificaciones',
                  ),
                  if (hasNewNotifications)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF1B3A57), width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: const Icon(Icons.person_outline,
                    color: Colors.white, size: 28),
                onPressed: () {},
                tooltip: 'Ya estás en Perfil',
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(
                    Icons.settings_suggest,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onAdminMenu,
                  tooltip: 'Mostrar menú',
                ),
              PopupMenuButton<String>(
                            
                            icon: const Icon(Icons.more_vert, color: Colors.white, size: 28), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            onSelected: (value) async {
                              if (value == 'donate') {
                                
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => const DonationScreen())
                                );
                              } else if (value == 'logout') {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                  
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); 
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              // donaciones
                              const PopupMenuItem(
                                value: 'donate',
                                child: Row(
                                  children: [
                                    Icon(Icons.volunteer_activism, color: Color(0xFFF28B31)), 
                                    SizedBox(width: 10),
                                    Text('Realizar donación'),
                                  ],
                                ),
                              ),
                              // cerrar sesion
                              const PopupMenuItem(
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

class _ProfileCard extends StatelessWidget {
  final ProfileViewModel vm;
  final VoidCallback onEdit;

  static const Color unimetBlue = Color(0xFF1B3A57);

  const _ProfileCard({required this.vm, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopProfileRow(vm: vm, onEdit: onEdit),

              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final raw = snapshot.data!.data();
                  if (raw == null) return const SizedBox.shrink();
                  final data = raw as Map<String, dynamic>;
                  final int exchanges = data['free_exchanges'] ?? 0;
                  if (exchanges < 0) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: exchanges > 2
                          ? Colors.blue.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: exchanges > 2
                            ? Colors.blue.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          exchanges > 2
                              ? Icons.info_outline
                              : Icons.warning_amber_rounded,
                          color: exchanges > 2
                              ? Colors.blue.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Intercambios restantes: $exchanges",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: exchanges > 2
                                      ? Colors.blue.shade900
                                      : Colors.red.shade900,
                                ),
                              ),
                              const Text(
                                "Al agotarse, deberás realizar una donación para continuar.",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),
              const _SectionTitle(title: "Datos personales"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ChipInfo(label: "Cédula", value: vm.cedula ?? "—"),
                  _ChipInfo(label: "Carrera", value: vm.carrera ?? "—"),
                ],
              ),

              const SizedBox(height: 22),
              const _SectionTitle(title: "Mis Libros"),
              const SizedBox(height: 10),
              _MyBooksRow(
                uid: FirebaseAuth.instance.currentUser?.uid,
                email: vm.email,
                username: vm.username,
              ),

              const SizedBox(height: 22),

              // =====================
              // SECCIONES (2x2)
              // =====================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    child: _LoanCardStream(
                      kind: _LoanKind.bajoMiCuidado,
                      title: "Bajo mi cuidado",
                      emptyText: "Sin libros bajo tu cuidado",
                      highlightColor: Color(0xFFBFD7F2),
                      infoText:
                          "Estos son los libros que has pedido prestados y actualmente están bajo tu cuidado.",
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _LoanCardStream(
                      kind: _LoanKind.reservados,
                      title: "Reservados",
                      emptyText: "No has reservado ningún libro",
                      highlightColor: Color(0xFFE5E5E5),
                      infoText:
                          "Estos son los libros que has pedido, pero el préstamo todavía no se ha concretado (está en negociación/confirmación).",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    child: _LoanCardStream(
                      kind: _LoanKind.misPrestamos,
                      title: "Mis préstamos",
                      emptyText: "No tienes préstamos activos",
                      highlightColor: Color(0xFFF7D2A6),
                      infoText:
                          "Estos son los libros que tú has prestado a otra persona y están activos en este momento.",
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _LoanCardStream(
                      kind: _LoanKind.historial,
                      title: "Historial de Préstamos",
                      emptyText: "Aún no hay historial",
                      highlightColor: Color(0xFFF2C27A),
                      infoText:
                          "Estos son los libros que pediste prestado en el pasado y ya fueron devueltos.",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (vm.isLoading) ...[
                const SizedBox(height: 14),
                const Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: unimetBlue,
                    ),
                  ),
                ),
              ],
              if (!vm.isLoading && vm.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopProfileRow extends StatelessWidget {
  final ProfileViewModel vm;
  final VoidCallback onEdit;

  const _TopProfileRow({required this.vm, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final email = (vm.email ?? "").trim();
    final emailLower = email.toLowerCase();

    final n = (vm.nombre ?? "").trim();
    final a = (vm.apellido ?? "").trim();
    String nombreMostrar;
    if (n.isEmpty && a.isEmpty) {
      nombreMostrar = "Nombre";
    } else if (n.isEmpty) {
      nombreMostrar = a;
    } else if (a.isEmpty) {
      nombreMostrar = n;
    } else {
      nombreMostrar = "$n $a";
    }

    String tipo;
    if (emailLower.startsWith('admin')) {
      tipo = "Administrador";
    } else if (emailLower.endsWith('@unimet.edu.ve')) {
      tipo = "Docente";
    } else if (emailLower.endsWith('@correo.unimet.edu.ve')) {
      tipo = "Estudiante";
    } else {
      tipo = "Usuario";
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: Colors.grey[200],
          child: Text(
            (vm.avatarEmoji ?? "🙂"),
            style: const TextStyle(fontSize: 34),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreMostrar,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3A57).withAlpha(15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: const Color(0xFF1B3A57).withAlpha(31)),
                    ),
                    child: Text(
                      "Usuario: ${vm.username}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1B3A57),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                email.isEmpty ? "usuario@correo.unimet.edu.ve" : email,
                style: const TextStyle(
                    decoration: TextDecoration.underline, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(tipo,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DonationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.favorite, size: 16, color: Colors.white),
                label: const Text("Realizar donación", style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28B31),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, color: Colors.black54),
          label: const Text("Editar perfil"),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesListPage()),
            );
          },
          icon: const Icon(Icons.favorite, color: Colors.black54),
          label: const Text("Ver mis favoritos"),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500));
  }
}

class _ChipInfo extends StatelessWidget {
  final String label;
  final String value;

  const _ChipInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
                text: "$label: ",
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _CoversRow extends StatelessWidget {
  const _CoversRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _CoverPlaceholder(icon: Icons.menu_book),
          _CoverPlaceholder(icon: Icons.book_outlined),
          _CoverPlaceholder(icon: Icons.auto_stories_outlined),
          _CoverPlaceholder(icon: Icons.import_contacts_outlined),
          _CoverPlaceholder(icon: Icons.collections_bookmark_outlined),
        ],
      ),
    );
  }
}

enum _LoanKind { bajoMiCuidado, reservados, misPrestamos, historial }

class _MyBooksRow extends StatelessWidget {
  final String? uid;
  final String? email;
  final String? username;

  const _MyBooksRow({
    required this.uid,
    required this.email,
    required this.username,
  });

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

  bool _isMine(Map<String, dynamic> data) {
    final u = (uid ?? '').trim();
    if (u.isEmpty) return false;

    final userId = (data['userId'] ?? '').toString().trim();
    final ownerId = (data['ownerId'] ?? '').toString().trim();

    final e = (email ?? '').trim().toLowerCase();
    final ownerEmail =
        (data['ownerEmail'] ?? '').toString().trim().toLowerCase();
    final emailField = (data['email'] ?? '').toString().trim().toLowerCase();

    final un = (username ?? '').trim().toLowerCase();
    final ownerUsername =
        (data['ownerUsername'] ?? '').toString().trim().toLowerCase();
    final ownerUser = (data['ownerUser'] ?? '').toString().trim().toLowerCase();

    if (userId.isNotEmpty && userId == u) return true;
    if (ownerId.isNotEmpty && ownerId == u) return true;
    if (e.isNotEmpty && (ownerEmail == e || emailField == e)) return true;
    if (un.isNotEmpty && (ownerUsername == un || ownerUser == un)) return true;

    return false;
  }

  Widget _coverImage(String raw) {
    final url = raw.trim();
    if (url.isEmpty) {
      return const Icon(Icons.menu_book, color: Colors.grey);
    }

    final isBase64 = !url.startsWith('http') &&
        !url.startsWith('https') &&
        !url.startsWith('blob');

    if (isBase64) {
      try {
        return Image.memory(
          base64Decode(url),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.menu_book, color: Colors.grey),
        );
      } catch (_) {
        return const Icon(Icons.menu_book, color: Colors.grey);
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.menu_book, color: Colors.grey),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String bookId, String bookTitle) async {
    
    //Mostrar círculo de carga para que la app no parezca "congelada" al tocar la papelera
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFFF28B31))),
    );

    try {
      final cleanBookId = bookId.trim();
      bool isLoanActive = false;
      bool materialNoDisponible = false;

      final materialSnapshot = await FirebaseFirestore.instance
          .collection('materials')
          .doc(cleanBookId)
          .get();

      if (materialSnapshot.exists) {
        final materialData = materialSnapshot.data() as Map<String, dynamic>;
        final materialStatus = _normalizarStatus(
          (materialData['status'] ?? 'disponible').toString(),
        );

        materialNoDisponible = materialStatus != 'disponible';
      }

      //Buscamos directamente el material exacto en los chats 
      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('materialId', isEqualTo: cleanBookId)
          .get();

      for (var doc in chatsSnapshot.docs) {
        final status = _normalizarStatus(
          (doc.data()['status'] ?? '').toString(),
        );

        if ([
          'pendiente',
          'solicitado',
          'esperando_confirmacion',
          'reservado',
          'rentado',
          'en_prestamo',
          'devolucion_pendiente',
        ].contains(status)) {
          isLoanActive = true;
          break;
        }
      }

      //Quitamos el círculo de carga porque ya verificamos
      if (context.mounted) Navigator.pop(context);

      if (isLoanActive || materialNoDisponible) {
        // MOSTRAR BLOQUEO Y ABORTAR ELIMINACIÓN
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text('Acción denegada', style: TextStyle(color: Color(0xFF1B3A57), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text('No puedes eliminar "$bookTitle" porque actualmente tiene una transacción activa o el material no se encuentra disponible.\n\nDebes rechazar la solicitud, cerrar la reserva o concluir el préstamo antes de eliminar el material.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido', style: TextStyle(color: Color(0xFFF28B31), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return; // Salimos de la función, NO se borra el libro
      }
      
    } catch (e) {
      // Si el internet o Firebase fallan, quitamos la carga y evitamos el borrado por seguridad
      if (context.mounted) Navigator.pop(context); 
      debugPrint("Error verificando base de datos: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al verificar el estado del libro. Revisa tu conexión.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return; 
    }

    //SI NO ESTÁ PRESTADO, PREGUNTAMOS SI ESTÁ SEGURO DE BORRAR 
    if (!context.mounted) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Eliminar publicación', style: TextStyle(color: Color(0xFF1B3A57))),
          content: Text('¿Estás seguro de que deseas eliminar "$bookTitle"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    //PROCESO FINAL DE ELIMINAR 
    if (confirm == true && context.mounted) {
      try {
        await FirebaseFirestore.instance.collection('materials').doc(bookId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación eliminada correctamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null || uid!.trim().isEmpty) {
      return const _CoversRow();
    }

    final q = FirebaseFirestore.instance
        .collection('materials')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return SizedBox(
      height: 110,
      child: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _CoversRow();
          }

          final myDocs = snapshot.data!.docs
              .where((d) => _isMine(d.data() as Map<String, dynamic>))
              .toList();

          if (myDocs.isEmpty) {
            return const _CoversRow();
          }

          final items = myDocs.take(5).toList();

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;
              final bookId = doc.id;

              final imageUrl = (data['imageUrl'] ?? '').toString();
              final title = (data['title'] ?? '').toString().trim();
              final author = (data['author'] ?? '').toString().trim();

              final tooltipText = [
                if (title.isNotEmpty) 'Título: $title',
                if (author.isNotEmpty) 'Autor: $author',
              ].join('\n');

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaterialDetailPage(
                        materialId: bookId,
                        materialData: data,
                      ),
                    ),
                  );
                },
                child: Tooltip(
                  message: tooltipText.isEmpty ? 'Material' : tooltipText,
                  waitDuration: const Duration(milliseconds: 350),
                  showDuration: const Duration(seconds: 3),
                  preferBelow: false,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3A57).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                      color: Colors.white, fontSize: 12, height: 1.25),
                  child: Container(
                    width: 78,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _coverImage(imageUrl),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: GestureDetector(
                            onTap: () => _confirmDelete(context, bookId, title),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4)
                                ],
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final IconData icon;
  const _CoverPlaceholder({required this.icon});

  static const double _coverW = 78;
  static const double _coverH = 96;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _coverW,
      height: _coverH,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Icon(icon, color: Colors.grey, size: 28),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color highlightColor;
  final Widget? body;
  final String? infoText;

  const _LoanCard({
    required this.title,
    required this.subtitle,
    required this.highlightColor,
    this.body,
    this.infoText,
  });

  void _showInfo(BuildContext context) {
    final msg = (infoText ?? '').trim();
    if (msg.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1B3A57)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1B3A57),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(msg, style: const TextStyle(height: 1.35)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Color(0xFFF28B31)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            if ((infoText ?? '').trim().isNotEmpty)
              IconButton(
                onPressed: () => _showInfo(context),
                icon: const Icon(Icons.info_outline,
                    size: 18, color: Colors.black54),
                tooltip: 'Información',
                splashRadius: 18,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 110),
            child: body != null
                ? body!
                : Row(
                    children: [
                      Container(
                        width: 78,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _LoanCardStream extends StatelessWidget {
  final _LoanKind kind;
  final String title;
  final String emptyText;
  final Color highlightColor;
  final String infoText;

  const _LoanCardStream({
    required this.kind,
    required this.title,
    required this.emptyText,
    required this.highlightColor,
    this.infoText = '',
  });

  static const double _coverW = 78;
  static const double _coverH = 96;

  String _normStatus(String raw) {
    final s = raw.toLowerCase().trim();
    return s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  Widget _coverImage(String raw) {
    final url = raw.trim();
    if (url.isEmpty) {
      return const Icon(Icons.menu_book, color: Colors.grey);
    }

    final isBase64 = !url.startsWith('http') &&
        !url.startsWith('https') &&
        !url.startsWith('blob');

    if (isBase64) {
      try {
        return Image.memory(
          base64Decode(url),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.menu_book, color: Colors.grey),
        );
      } catch (_) {
        return const Icon(Icons.menu_book, color: Colors.grey);
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.menu_book, color: Colors.grey),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMaterials(
      List<String> materialIds) async {
    final firestore = FirebaseFirestore.instance;
    final List<Map<String, dynamic>> results = [];

    for (final id in materialIds) {
      if (id.isEmpty) continue;
      try {
        final doc = await firestore.collection('materials').doc(id).get();
        final data = doc.data() ?? <String, dynamic>{};
        results.add({
          'materialId': id,
          'imageUrl': (data['imageUrl'] ?? '').toString(),
          'title': (data['title'] ?? '').toString(),
          'author': (data['author'] ?? '').toString(),
          'data': data,
        });
      } catch (_) {
        results.add({
          'materialId': id,
          'imageUrl': '',
          'title': '',
          'author': '',
          'data': <String, dynamic>{},
        });
      }
    }

    return results;
  }

  Widget _coversBody(BuildContext context, List<Map<String, dynamic>> materials) {
    return SizedBox(
      height: _coverH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final m = materials[index];
          final imageUrl = (m['imageUrl'] ?? '').toString();
          final t = (m['title'] ?? '').toString().trim();
          final a = (m['author'] ?? '').toString().trim();
          final id = (m['materialId'] ?? '').toString().trim();
          final fullData = (m['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};

          final tooltipText = [
            if (t.isNotEmpty) 'Título: $t',
            if (a.isNotEmpty) 'Autor: $a',
          ].join('\n');

          return Tooltip(
            message: tooltipText.isEmpty ? 'Material' : tooltipText,
            waitDuration: const Duration(milliseconds: 350),
            showDuration: const Duration(seconds: 3),
            preferBelow: false,
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A57).withOpacity(0.95),
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle:
                const TextStyle(color: Colors.white, fontSize: 12, height: 1.25),
            child: InkWell(
              onTap: () {
                if (id.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaterialDetailPage(
                      materialId: id,
                      materialData: fullData,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: _coverW,
                height: _coverH,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _coverImage(imageUrl),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return _LoanCard(
        title: title,
        subtitle: emptyText,
        highlightColor: highlightColor,
        infoText: infoText,
      );
    }

    // ===== HISTORIAL: completed_loans (borrowerId == uid) =====
    if (kind == _LoanKind.historial) {
      final histQ = FirebaseFirestore.instance
          .collection('completed_loans')
          .where('borrowerId', isEqualTo: uid)
          .limit(120);

      return StreamBuilder<QuerySnapshot>(
        stream: histQ.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoanCard(
              title: title,
              subtitle: 'No se pudo cargar (revisa permisos/índices)',
              highlightColor: highlightColor,
              infoText: infoText,
            );
          }
          if (!snapshot.hasData) {
            return _LoanCard(
              title: title,
              subtitle: emptyText,
              highlightColor: highlightColor,
              infoText: infoText,
            );
          }

          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final ma = (a.data() as Map<String, dynamic>?) ?? {};
            final mb = (b.data() as Map<String, dynamic>?) ?? {};
            final ta = ma['completedAt'];
            final tb = mb['completedAt'];

            DateTime da = DateTime.fromMillisecondsSinceEpoch(0);
            DateTime db = DateTime.fromMillisecondsSinceEpoch(0);
            if (ta is Timestamp) da = ta.toDate();
            if (tb is Timestamp) db = tb.toDate();
            return db.compareTo(da);
          });

          final matchedMaterialIds = <String>[];
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final materialId = (data['materialId'] ?? '').toString().trim();
            if (materialId.isEmpty) continue;
            if (!matchedMaterialIds.contains(materialId)) {
              matchedMaterialIds.add(materialId);
            }
          }

          final ids = matchedMaterialIds.take(5).toList();
          if (ids.isEmpty) {
            return _LoanCard(
              title: title,
              subtitle: emptyText,
              highlightColor: highlightColor,
              infoText: infoText,
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchMaterials(ids),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _LoanCard(
                  title: title,
                  subtitle: 'Cargando...',
                  highlightColor: highlightColor,
                  infoText: infoText,
                );
              }
              if (snap.hasError) {
                return _LoanCard(
                  title: title,
                  subtitle: 'No se pudo cargar',
                  highlightColor: highlightColor,
                  infoText: infoText,
                );
              }
              final materials = snap.data ?? [];
              return _LoanCard(
                title: title,
                subtitle: '',
                highlightColor: highlightColor,
                infoText: infoText,
                body: _coversBody(context, materials),
              );
            },
          );
        },
      );
    }

    // ===== SECCIONES ACTIVAS: chats =====
    final chatsQ = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .limit(120);

    return StreamBuilder<QuerySnapshot>(
      stream: chatsQ.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoanCard(
            title: title,
            subtitle: 'No se pudo cargar (revisa permisos/índices)',
            highlightColor: highlightColor,
            infoText: infoText,
          );
        }
        if (!snapshot.hasData) {
          return _LoanCard(
            title: title,
            subtitle: emptyText,
            highlightColor: highlightColor,
            infoText: infoText,
          );
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final ma = (a.data() as Map<String, dynamic>?) ?? {};
          final mb = (b.data() as Map<String, dynamic>?) ?? {};
          final ta = ma['lastUpdate'];
          final tb = mb['lastUpdate'];

          DateTime da = DateTime.fromMillisecondsSinceEpoch(0);
          DateTime db = DateTime.fromMillisecondsSinceEpoch(0);
          if (ta is Timestamp) da = ta.toDate();
          if (tb is Timestamp) db = tb.toDate();
          return db.compareTo(da);
        });

        final matchedMaterialIds = <String>[];

        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final participants = (data['participants'] as List?) ?? const [];
          if (participants.isEmpty) continue;

          final ownerIdField = (data['ownerId'] ?? '').toString().trim();
          final rawStatus = (data['status'] ?? '').toString();
          final status = _normStatus(rawStatus);

          final bool activo =
              (status == 'rentado' || status == 'devolucion_pendiente');

          // IMPORTANTE: “ESPERANDO_CONFIRMACION” debe ir a Reservados
          final bool reservado =
              (status == 'pendiente' || status == 'esperando_confirmacion');

          // Verificación + normalización de owner/solicitante
          final p0 = participants[0].toString().trim();
          final p1 =
              participants.length > 1 ? participants[1].toString().trim() : '';

          String ownerId = '';
          String requesterId = '';

          if (ownerIdField.isNotEmpty) {
            if (p0 == ownerIdField) {
              ownerId = p0;
              requesterId = p1;
            } else if (p1.isNotEmpty && p1 == ownerIdField) {
              ownerId = p1;
              requesterId = p0;
              debugPrint(
                  '[Profile] participants invertidos -> corregido (doc: ${d.id})');
            } else {
              ownerId = p0;
              requesterId = p1;
              debugPrint(
                  '[Profile] ownerId no coincide con participants (doc: ${d.id})');
            }
          } else {
            ownerId = p0;
            requesterId = p1;
          }

          final bool yoSoyOwner = (ownerId.isNotEmpty && ownerId == uid);
          final bool yoSoySolicitante =
              (requesterId.isNotEmpty && requesterId == uid);

          final materialId = (data['materialId'] ?? '').toString().trim();
          if (materialId.isEmpty) continue;

          bool match = false;

          if (kind == _LoanKind.bajoMiCuidado) {
            match = yoSoySolicitante && !yoSoyOwner && activo;
          } else if (kind == _LoanKind.misPrestamos) {
            match = yoSoyOwner && activo;
          } else if (kind == _LoanKind.reservados) {
            match = yoSoySolicitante && reservado;
          }

          if (match && !matchedMaterialIds.contains(materialId)) {
            matchedMaterialIds.add(materialId);
          }
        }

        final ids = matchedMaterialIds.take(5).toList();
        if (ids.isEmpty) {
          return _LoanCard(
            title: title,
            subtitle: emptyText,
            highlightColor: highlightColor,
            infoText: infoText,
          );
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchMaterials(ids),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _LoanCard(
                title: title,
                subtitle: 'Cargando...',
                highlightColor: highlightColor,
                infoText: infoText,
              );
            }
            if (snap.hasError) {
              return _LoanCard(
                title: title,
                subtitle: 'No se pudo cargar',
                highlightColor: highlightColor,
                infoText: infoText,
              );
            }
            final materials = snap.data ?? [];
            return _LoanCard(
              title: title,
              subtitle: '',
              highlightColor: highlightColor,
              infoText: infoText,
              body: _coversBody(context, materials),
            );
          },
        );
      },
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  final bool isAdmin;
  const _BackgroundBlobs({this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlobPainter(isAdmin: isAdmin),
      child: const SizedBox.expand(),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final bool isAdmin;
  _BlobPainter({this.isAdmin = false});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(isAdmin ? 0.05 : 0.06);
    final p2 = Paint()..color = Colors.white.withOpacity(isAdmin ? 0.03 : 0.035);

    if (isAdmin) {
      canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.18), 170, p1);
      canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.72), 220, p1);
      canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.10), 130, p2);
    } else {
      canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 100, p1);
      canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.5), 150, p1);
      canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.8), 120, p1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _AdminDashboardShellFromProfile extends StatelessWidget {
  const _AdminDashboardShellFromProfile();

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
          const _BackgroundBlobs(isAdmin: true),
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