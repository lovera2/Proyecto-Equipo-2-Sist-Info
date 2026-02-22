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

    // fuerza recarga (ya limpia los datos viejos en cargarPerfil)
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Perfil - BookLoop', style: TextStyle(color: Colors.white)),
        backgroundColor: unimetBlue,
        elevation: 0,
      ),
      body: !_initialized || vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
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
                          onPressed: vm.isSaving ? null : () => Navigator.pop(context),
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
    );
  }
}