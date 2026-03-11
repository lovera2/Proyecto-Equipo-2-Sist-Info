import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'edit_profile_page.dart';
import 'package:bookloop_unimet/views/chat_list_page.dart';

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
    final email = (context.read<ProfileViewModel>().email ?? '').toLowerCase().trim();
    final route = email.startsWith('admin') ? '/home_admin' : '/home_page';
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
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
              child: const Text("Entendido", style: TextStyle(color: unimetOrange)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [unimetBlue, Color(0xFF2C5E8C)],
              ),
            ),
          ),
          const _BackgroundBlobs(),
          SafeArea(
            child: Column(
              children: [
                _ProfileHeader(
                  onEdit: () => _openEdit(context),
                  onHome: () => _goHome(context),
                  onProfile: () => Navigator.pushNamed(context, '/profile'),
                  onNotifications: () {
                    setState(() {
                      _hasNewNotifications = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatListPage()),
                    );
                  },
                  onCreate: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Publicar/Crear en desarrollo")),
                    );
                  },
                  onLogout: () => _handleLogout(context),
                  hasNewNotifications: _hasNewNotifications,
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
                        child: _ProfileCard(vm: vm, onEdit: () => _openEdit(context)),
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

  static const Color unimetOrange = Color(0xFFF28B31);

  const _ProfileHeader({
    required this.onEdit,
    required this.onHome,
    required this.onProfile,
    required this.onNotifications,
    required this.onCreate,
    required this.onLogout,
    required this.hasNewNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo y Título (igual que Home)
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

          // Botones de acción (igual que Home)
          Row(
            children: [
              // Publicar
              Container(
                decoration: BoxDecoration(
                  color: unimetOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/publish'),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Publicar material',
                ),
              ),
              const SizedBox(width: 10),

              // Inicio (volver al Home)
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                onPressed: onHome,
                tooltip: 'Inicio',
              ),
              const SizedBox(width: 10),

              // Notificaciones / Chats (con punto rojo)
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
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
                          border: Border.all(color: const Color(0xFF1B3A57), width: 1.5),
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

              // Perfil (ya estamos en Perfil)
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                onPressed: () {},
                tooltip: 'Ya estás en Perfil',
              ),

              // Menú (Cerrar sesión)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                onSelected: (value) {
                  if (value == 'logout') onLogout();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Color(0xFF1B3A57)),
                        SizedBox(width: 10),
                        Text("Cerrar Sesión"),
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
              const SizedBox(height: 20),
              const _SectionTitle(title: "Mis Libros"),
              const SizedBox(height: 10),
              _MyBooksRow(
                uid: FirebaseAuth.instance.currentUser?.uid,
                email: vm.email,
                username: vm.username,
              ),
              const SizedBox(height: 10),
              if (vm.isLoading) ...[
                const SizedBox(height: 14),
                const Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: unimetBlue),
                  ),
                ),
              ],
              if (!vm.isLoading && vm.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(vm.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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

    // Nombre para mostrar
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

    // Rol para mostrar (derivado del correo)
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3A57).withAlpha(15), // ~6%
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF1B3A57).withAlpha(31)), // ~12%
                    ),
                    child: Text(
                      "Usuario: ${vm.username}",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1B3A57), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              Text(
                email.isEmpty ? "usuario@correo.unimet.edu.ve" : email,
                style: const TextStyle(decoration: TextDecoration.underline, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(tipo, style: const TextStyle(fontSize: 14, color: Colors.black54)),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Favoritos en desarrollo")),
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
    return Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500));
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
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
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

enum _LoanKind { bajoMiCuidado, reservados, misPrestamos }

class _MyBooksRow extends StatelessWidget {
  final String? uid;
  final String? email;
  final String? username;

  const _MyBooksRow({
    required this.uid,
    required this.email,
    required this.username,
  });

  bool _isMine(Map<String, dynamic> data) {
    final u = (uid ?? '').trim();
    if (u.isEmpty) return false;

    final userId = (data['userId'] ?? '').toString().trim();
    final ownerId = (data['ownerId'] ?? '').toString().trim();

    final e = (email ?? '').trim().toLowerCase();
    final ownerEmail = (data['ownerEmail'] ?? '').toString().trim().toLowerCase();
    final emailField = (data['email'] ?? '').toString().trim().toLowerCase();

    final un = (username ?? '').trim().toLowerCase();
    final ownerUsername = (data['ownerUsername'] ?? '').toString().trim().toLowerCase();
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

    final isBase64 = !url.startsWith('http') && !url.startsWith('https') && !url.startsWith('blob');

    if (isBase64) {
      try {
        return Image.memory(
          base64Decode(url),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, color: Colors.grey),
        );
      } catch (_) {
        return const Icon(Icons.menu_book, color: Colors.grey);
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, color: Colors.grey),
    );
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

          final all = snapshot.data!.docs
              .map((d) => d.data() as Map<String, dynamic>)
              .where(_isMine)
              .toList();

          if (all.isEmpty) {
            return const _CoversRow();
          }

          final items = all.take(5).toList();

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final data = items[index];
              final imageUrl = (data['imageUrl'] ?? '').toString();

              final title = (data['title'] ?? '').toString().trim();
              final author = (data['author'] ?? '').toString().trim();

              final tooltipText = [
                if (title.isNotEmpty) 'Título: $title',
                if (author.isNotEmpty) 'Autor: $author',
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
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.25,
                ),
                child: Container(
                  width: 78,
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
              );
            },
          );
        },
      ),
    );
  }
}

class _LoanCardStream extends StatelessWidget {
  final _LoanKind kind;
  final String title;
  final String emptyText;
  final Color highlightColor;

  const _LoanCardStream({
    required this.kind,
    required this.title,
    required this.emptyText,
    required this.highlightColor,
  });

  // Helper: cover image widget for a given imageUrl (base64 or network)
  Widget _coverImage(String raw) {
    final url = raw.trim();
    if (url.isEmpty) {
      return const Icon(Icons.menu_book, color: Colors.grey);
    }
    final isBase64 = !url.startsWith('http') && !url.startsWith('https') && !url.startsWith('blob');
    if (isBase64) {
      try {
        return Image.memory(
          base64Decode(url),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, color: Colors.grey),
        );
      } catch (_) {
        return const Icon(Icons.menu_book, color: Colors.grey);
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, color: Colors.grey),
    );
  }

  // Helper: fetch material docs for given materialIds, returns list of {materialId, imageUrl, title, author}
  Future<List<Map<String, dynamic>>> _fetchMaterials(List<String> materialIds) async {
    final firestore = FirebaseFirestore.instance;
    final List<Map<String, dynamic>> results = [];
    for (final id in materialIds) {
      if (id.isEmpty) continue;
      try {
        final doc = await firestore.collection('materials').doc(id).get();
        final data = doc.data() ?? {};
        results.add({
          'materialId': id,
          'imageUrl': (data['imageUrl'] ?? '').toString(),
          'title': (data['title'] ?? '').toString(),
          'author': (data['author'] ?? '').toString(),
        });
      } catch (_) {
        results.add({
          'materialId': id,
          'imageUrl': '',
          'title': '',
          'author': '',
        });
      }
    }
    return results;
  }

  // Helper: covers row for up to 5 materials, with tooltip
  Widget _coversBody(List<Map<String, dynamic>> materials) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final m = materials[index];
          final imageUrl = (m['imageUrl'] ?? '').toString();
          final title = (m['title'] ?? '').toString().trim();
          final author = (m['author'] ?? '').toString().trim();
          final tooltipText = [
            if (title.isNotEmpty) 'Título: $title',
            if (author.isNotEmpty) 'Autor: $author',
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
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.25,
            ),
            child: Container(
              width: 78,
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _LoanCard(title: title, subtitle: emptyText, highlightColor: highlightColor);
    }

    final vm = context.read<ProfileViewModel>();
    // Nota: usamos una consulta amplia por "participants" y luego filtramos en cliente
    // para no depender de estructura extra en Firestore.
    // Traemos los chats donde participo. Evitamos `orderBy` para no depender de índices compuestos.
    // Ordenamos en cliente por lastUpdate.
    final chatsQ = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .limit(80);

    return StreamBuilder<QuerySnapshot>(
      stream: chatsQ.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoanCard(
            title: title,
            subtitle: 'No se pudo cargar (revisa índices/permisos en Firestore)',
            highlightColor: highlightColor,
          );
        }
        if (!snapshot.hasData) {
          return _LoanCard(title: title, subtitle: emptyText, highlightColor: highlightColor);
        }

        final docs = snapshot.data!.docs;
        final ordered = [...docs];
        ordered.sort((a, b) {
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

        // Ahora, en vez de contar, filtramos los chats que corresponden a este tipo de préstamo,
        // y extraemos los materialIds para mostrar hasta 5 portadas (como "Mis Libros").
        final matchedMaterialIds = <String>[];
        for (final d in ordered) {
          final data = d.data() as Map<String, dynamic>;
          final participants = (data['participants'] as List?) ?? const [];
          if (participants.isEmpty) continue;
          final rawStatus = (data['status'] ?? '').toString();
          final statusNorm = vm.normalizarStatus(rawStatus);
          // IMPORTANTE (regla del proyecto):
          // participants[0] = dueño (propietario)
          // participants[1] = solicitante (quien pidió el libro)
          final propietarioId = participants.first.toString().trim();
          final solicitanteId = participants.length > 1 ? participants[1].toString().trim() : '';

          final yoSoyPropietario = propietarioId == uid;
          final yoSoySolicitante = solicitanteId.isNotEmpty && solicitanteId == uid;
          final activo = (statusNorm == 'rentado' || statusNorm == 'devolucion_pendiente');
          if (kind == _LoanKind.reservados) {
            // Reservados = yo soy solicitante y el chat sigue en pendiente.
            if (yoSoySolicitante && statusNorm == 'pendiente') {
              final materialId = (data['materialId'] ?? '').toString().trim();
              if (materialId.isNotEmpty && !matchedMaterialIds.contains(materialId)) {
                matchedMaterialIds.add(materialId);
              }
            }
          } else if (kind == _LoanKind.bajoMiCuidado) {
            // Bajo mi cuidado = yo soy solicitante y el préstamo ya está activo.
            if (yoSoySolicitante && activo) {
              final materialId = (data['materialId'] ?? '').toString().trim();
              if (materialId.isNotEmpty && !matchedMaterialIds.contains(materialId)) {
                matchedMaterialIds.add(materialId);
              }
            }
          } else if (kind == _LoanKind.misPrestamos) {
            // Mis préstamos = yo soy propietario y el préstamo está activo.
            if (yoSoyPropietario && activo) {
              final materialId = (data['materialId'] ?? '').toString().trim();
              if (materialId.isNotEmpty && !matchedMaterialIds.contains(materialId)) {
                matchedMaterialIds.add(materialId);
              }
            }
          }
        }
        final ids = matchedMaterialIds.take(5).toList();
        if (ids.isEmpty) {
          // Si no hay materiales, muestra el card vacío como antes.
          return _LoanCard(title: title, subtitle: emptyText, highlightColor: highlightColor);
        }
        // Si hay materiales, muestra la fila de portadas (como "Mis Libros") en la tarjeta.
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchMaterials(ids),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Mientras carga, muestra placeholder igual que antes (gris + "Cargando...")
              return _LoanCard(
                title: title,
                subtitle: "Cargando...",
                highlightColor: highlightColor,
              );
            }
            if (snapshot.hasError) {
              return _LoanCard(
                title: title,
                subtitle: 'No se pudo cargar',
                highlightColor: highlightColor,
              );
            }
            final materials = snapshot.data ?? [];
            return _LoanCard(
              title: title,
              highlightColor: highlightColor,
              body: _coversBody(materials),
              subtitle: '', // not used if body is present
            );
          },
        );
      },
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final IconData icon;
  const _CoverPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.grey),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color highlightColor;
  final Widget? body;

  const _LoanCard({
    required this.title,
    required this.subtitle,
    required this.highlightColor,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(10)),
          child: body != null
              ? body!
              : Row(
                  children: [
                    Container(
                      width: 55,
                      height: 72,
                      decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                  ],
                ),
        ),
      ],
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
    final p1 = Paint()..color = Colors.white.withAlpha(13); // ~5%
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 100, p1);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.5), 150, p1);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.8), 120, p1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

