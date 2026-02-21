import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/profile_viewmodel.dart';

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
    final vm=context.watch<ProfileViewModel>();

    final String nombreMostrado=vm.nombre ?? "Nombre del Estudiante";
    final String emailMostrado=vm.email ?? "usuario.unimet@correo.unimet.edu.ve";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mi Perfil - BookLoop', style: TextStyle(color: Colors.white)),
        backgroundColor: unimetBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: unimetBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: unimetBlue),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    nombreMostrado,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    emailMostrado,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  if(vm.isLoading) ...[
                    const SizedBox(height: 12),
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ],

                  if(!vm.isLoading && vm.errorMessage!=null) ...[
                    const SizedBox(height: 12),
                    Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Conectar con la lógica de edición
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text("Editar Información", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: unimetOrange,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navegar a la lista de libros del usuario
                    },
                    icon: const Icon(Icons.book, color: unimetBlue),
                    label: const Text("Mis Libros Publicados", style: TextStyle(color: unimetBlue)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: unimetBlue),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}