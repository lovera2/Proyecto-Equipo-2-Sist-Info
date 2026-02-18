import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Chicos, aquí puse los colores que acordamos en las láminas:
  // El azul marino para fondos y el naranja Unimet para lo que resalte.
  static const Color unimetBlue = Color(0xFF1B3A57);   //
  static const Color unimetOrange = Color(0xFFF28B31); //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mi Perfil - BookLoop', style: TextStyle(color: Colors.white)),
        backgroundColor: unimetBlue,
        elevation: 0, // Quitamos la sombra para que se vea más moderno y plano
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Este es el encabezado azul con las curvas de abajo, como en el diseño.
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
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: unimetBlue),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Nombre del Estudiante", 
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "usuario.unimet@correo.unimet.edu.ve", 
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Aquí van los botones principales. 
            // Usamos el naranja para el botón de acción principal para que llame la atención.
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

                  // Este botón es secundario, por eso solo tiene el borde azul.
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