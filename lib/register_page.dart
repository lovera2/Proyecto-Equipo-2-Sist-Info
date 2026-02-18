import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  // Colores institucionales definidos para el proyecto
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: unimetBlue, // Fondo azul según el diseño de registro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                "¡Crea tu cuenta usando un correo Unimet!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 40),
              
              // Disposición en fila para las opciones de rol (Docente y Estudiante)
              Row(
                children: [
                  _buildRoleCard("Docente", Icons.person_outline),
                  const SizedBox(width: 20),
                  _buildRoleCard("Estudiante", Icons.school_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Componente reutilizable para las tarjetas de rol del Hito 1
  Widget _buildRoleCard(String title, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 80, color: unimetBlue),
            const SizedBox(height: 10),
            Text(
              title, 
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: unimetBlue
              )
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                hintText: "E-mail", 
                labelStyle: TextStyle(fontSize: 12)
              )
            ),
            const TextField(
              obscureText: true, 
              decoration: InputDecoration(hintText: "Contraseña")
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: unimetOrange),
              child: const Text(
                "Crear cuenta", 
                style: TextStyle(color: Colors.white, fontSize: 12)
              ),
            ),
          ],
        ),
      ),
    );
  }
}