import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/profile_viewmodel.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _carreraCtrl;

  bool _initialized = false;

  String _emoji = "🙂";

  final List<String> _emojis = const [
    "🙂","😄","😎","🤓","🧠","📚","🦉","🐯","🦊","🐼","🐸","🐵",
    "🧑‍🎓","👩‍🎓","👨‍🎓","🧑‍🏫","👩‍🏫","👨‍🏫","🧑‍💻","👩‍💻","👨‍💻",
    "🦄","🐙","🐝","🦋","🌟","🔥","⚡","🍀","🎯","🏆"
  ];

  @override
  void initState() {
    super.initState();

    _nombreCtrl = TextEditingController(text: '');
    _apellidoCtrl = TextEditingController(text: '');
    _cedulaCtrl = TextEditingController(text: '');
    _carreraCtrl = TextEditingController(text: '');

    Future.microtask(_initFromVm);
  }

  Future<void> _initFromVm() async {
    final vm = context.read<ProfileViewModel>();

    //Limpieza de UI antes de pedir datos
    setState(() => _initialized = false);
    _nombreCtrl.text = '';
    _apellidoCtrl.text = '';
    _cedulaCtrl.text = '';
    _carreraCtrl.text = '';
    _emoji = "🙂";

    //Obtención de datos
    await vm.cargarPerfil();
    if (!mounted) return;

    _nombreCtrl.text = vm.nombre ?? '';
    _apellidoCtrl.text = vm.apellido ?? '';
    _cedulaCtrl.text = vm.cedula ?? '';
    _carreraCtrl.text = vm.carrera ?? '';

    final em = (vm.avatarEmoji ?? '').trim();
    _emoji = em.isEmpty ? "🙂" : em;

    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cedulaCtrl.dispose();
    _carreraCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarEmoji() async {
    final elegido = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Selecciona tu emoji"),
          content: SizedBox(
            width: 420,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: _emojis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                final e = _emojis[i];
                return InkWell(
                  onTap: () => Navigator.pop(context, e),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
          ],
        );
      },
    );

    if (elegido == null) return;
    setState(() => _emoji = elegido);
  }

  Future<void> _guardar() async {
    final vm = context.read<ProfileViewModel>();

    final okForm = _formKey.currentState?.validate() ?? false;
    if (!okForm) return;

    final ok = await vm.actualizarPerfil(
      nombre: _nombreCtrl.text,
      apellido: _apellidoCtrl.text,
      cedula: _cedulaCtrl.text,
      carrera: _carreraCtrl.text,
      avatarEmoji: _emoji,
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? "Error guardando perfil"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/profile', (route) => false);
  }

  void _cancelar() {
    Navigator.of(context).pushNamedAndRemoveUntil('/profile', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final usuario = vm.username;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Perfil - BookLoop', style: TextStyle(color: Colors.white)),
        backgroundColor: unimetBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancelar,
        ),
      ),
      body: Stack(
        children: [
          const _EditProfileBackground(),
          if (!_initialized || vm.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;

                      final info1 = _InfoBanner(
                        icon: Icons.assignment_turned_in_outlined,
                        title: "Completa tus datos personales",
                        message:
                            "Por favor llena tu nombre, apellido, cédula y carrera. Esto ayuda a que los préstamos y reservas se vean más claros para otros unimetanos.",
                      );

                      final info2 = _InfoBanner(
                        icon: Icons.alternate_email,
                        title: "Tu usuario de BookLoop viene de tu correo",
                        message:
                            "Tu usuario se genera automáticamente con lo que va antes del @ en tu email (ej: $usuario). Por seguridad y consistencia, ese usuario no se puede cambiar.",
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: info1),
                            const SizedBox(width: 12),
                            Expanded(child: info2),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          info1,
                          const SizedBox(height: 12),
                          info2,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.grey[200],
                            child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Avatar (emoji)", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: vm.isSaving ? null : _seleccionarEmoji,
                                  icon: const Icon(Icons.emoji_emotions_outlined, color: unimetBlue),
                                  label: const Text("Elegir emoji", style: TextStyle(color: unimetBlue)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombreCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: "Nombre",
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return "Campo obligatorio";
                                if (value.length < 2) return "Mínimo 2 caracteres";
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _apellidoCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: "Apellido",
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return "Campo obligatorio";
                                if (value.length < 2) return "Mínimo 2 caracteres";
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _cedulaCtrl,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Cédula",
                                prefixIcon: Icon(Icons.credit_card),
                                hintText: "Ej: 12345678",
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return "Campo obligatorio";
                                if (!RegExp(r'^\d{6,10}$').hasMatch(value)) {
                                  return "Solo números (6 a 10 dígitos)";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _carreraCtrl,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: "Carrera",
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return "Campo obligatorio";
                                if (value.length < 3) return "Mínimo 3 caracteres";
                                return null;
                              },
                            ),
                            if (vm.errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(vm.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: vm.isSaving ? null : _cancelar,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: unimetBlue),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Cancelar", style: TextStyle(color: unimetBlue)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: vm.isSaving ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: unimetOrange,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: vm.isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Guardar", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    const Color tint = Color(0x101B3A57);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A1B3A57)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A1B3A57)),
            ),
            child: Icon(icon, color: const Color(0xFF1B3A57)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B3A57),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.black87,
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


class _EditProfileBackground extends StatelessWidget {
  const _EditProfileBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF7F9FD),
                  Color(0xFFF1F5FC),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: _SoftPatternPainter(),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}

class _SoftPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = const Color(0x1A1B3A57);
    final blobPaint = Paint()..color = const Color(0x0D1B3A57);

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.18), 140, blobPaint);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.30), 170, blobPaint);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.82), 160, blobPaint);

    const step = 90.0;
    for (double y = 20; y < size.height; y += step) {
      for (double x = 20; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}