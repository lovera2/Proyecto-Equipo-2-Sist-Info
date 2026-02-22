import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/profile_viewmodel.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  void initState() {
    super.initState();
    // Carga de perfil apenas entra (sin romper UI)
    Future.microtask(() => context.read<ProfileViewModel>().cargarPerfil());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo parecido a otras vistas (gradiente + blobs)
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
                  onBack: () => Navigator.pop(context),
                  onEdit: () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfilePage()),
                    );

                    if (ok == true) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Perfil actualizado"),
                          backgroundColor: unimetBlue,
                        ),
                      );
                    }
                  },
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
                        child: _ProfileCard(vm: vm),
                      ),
                    ),
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

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onEdit;

  static const Color unimetOrange = Color(0xFFF28B31);

  const _ProfileHeader({
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: onBack,
          ),
          const SizedBox(width: 6),
          const Text(
            "BookLoop",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // Botón "crear" (solo UI)
          Container(
            decoration: BoxDecoration(
              color: unimetOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Crear / Publicar',
            ),
          ),
          const SizedBox(width: 10),

          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onSelected: (value) {
              if (value == 'edit') onEdit();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF1B3A57)),
                    SizedBox(width: 10),
                    Text("Editar perfil"),
                  ],
                ),
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

  static const Color unimetBlue = Color(0xFF1B3A57);

  const _ProfileCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopProfileRow(vm: vm),
            const SizedBox(height: 18),

            _SectionTitle(title: "Datos personales"),
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
            const _CoversRow(emptyText: "Aún no has publicado libros"),

            const SizedBox(height: 22),

            LayoutBuilder(
              builder: (context, constraints) {
                final isTwoCols = constraints.maxWidth >= 760;
                if (!isTwoCols) {
                  return Column(
                    children: const [
                      _LoanCard(
                        title: "Bajo mi cuidado",
                        subtitle: "Sin libros bajo tu cuidado",
                        highlightColor: Color(0xFFB9D4F2),
                      ),
                      SizedBox(height: 14),
                      _LoanCard(
                        title: "Reservados",
                        subtitle: "No has reservado ningún libro",
                        highlightColor: Color(0xFFE0E0E0),
                      ),
                      SizedBox(height: 14),
                      _LoanCard(
                        title: "Mis préstamos",
                        subtitle: "No tienes préstamos activos",
                        highlightColor: Color(0xFFFFD3A8),
                      ),
                      SizedBox(height: 14),
                      _LoanCard(
                        title: "Historial de Préstamos",
                        subtitle: "Aún no hay historial",
                        highlightColor: Color(0xFFF7C07A),
                      ),
                    ],
                  );
                }

                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _LoanCard(
                            title: "Bajo mi cuidado",
                            subtitle: "Sin libros bajo tu cuidado",
                            highlightColor: Color(0xFFB9D4F2),
                          ),
                          SizedBox(height: 14),
                          _LoanCard(
                            title: "Mis préstamos",
                            subtitle: "No tienes préstamos activos",
                            highlightColor: Color(0xFFFFD3A8),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: [
                          _LoanCard(
                            title: "Reservados",
                            subtitle: "No has reservado ningún libro",
                            highlightColor: Color(0xFFE0E0E0),
                          ),
                          SizedBox(height: 14),
                          _LoanCard(
                            title: "Historial de Préstamos",
                            subtitle: "Aún no hay historial",
                            highlightColor: Color(0xFFF7C07A),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
              Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopProfileRow extends StatelessWidget {
  final ProfileViewModel vm;

  static const Color unimetBlue = Color(0xFF1B3A57);

  const _TopProfileRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: Colors.grey[200],
          child: vm.fotoUrl == null || vm.fotoUrl!.trim().isEmpty
              ? const Icon(Icons.person, size: 48, color: unimetBlue)
              : ClipOval(
                  child: Image.network(
                    vm.fotoUrl!,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 48, color: unimetBlue),
                  ),
                ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vm.username,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                vm.email ?? "usuario.unimet@correo.unimet.edu.ve",
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Estudiante",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {},
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
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
    );
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
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _CoversRow extends StatelessWidget {
  final String emptyText;

  const _CoversRow({required this.emptyText});

  @override
  Widget build(BuildContext context) {
    // Placeholders (la lógica real de libros se conecta después)
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

class _CoverPlaceholder extends StatelessWidget {
  final IconData icon;
  const _CoverPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.grey),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color highlightColor;

  const _LoanCard({
    required this.title,
    required this.subtitle,
    required this.highlightColor,
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
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
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
    final p1 = Paint()..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 100, p1);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.5), 150, p1);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.8), 120, p1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}