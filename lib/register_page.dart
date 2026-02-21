import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget { // Cambiado a StatefulWidget
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores independientes para evitar que se copie en ambos campos los datos
  final TextEditingController _emailDocente = TextEditingController();
  final TextEditingController _passDocente = TextEditingController();
  
  final TextEditingController _emailEstudiante = TextEditingController();
  final TextEditingController _passEstudiante = TextEditingController();

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  void _intentarRegistro(TextEditingController eCont, TextEditingController pCont) {
    String email = eCont.text.trim();
    if (email.endsWith('@unimet.edu.ve') || email.endsWith('@correo.unimet.edu.ve')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Correo válido! Redirigiendo al pago..."))
      );
      // Aqui voy a disenar el campo para la pantalla de campo tentativa (no funcional, por ahora)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Usa tu correo @unimet.edu.ve"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: unimetBlue,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text("¡Crea tu cuenta usando un correo Unimet!", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildRoleCard("Docente", Icons.person_outline, _emailDocente, _passDocente),
                  const SizedBox(width: 20),
                  _buildRoleCard("Estudiante", Icons.school_outlined, _emailEstudiante, _passEstudiante),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, TextEditingController eCont, TextEditingController pCont) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, size: 80, color: unimetBlue),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: unimetBlue)),
            const SizedBox(height: 20),
            TextField(controller: eCont, decoration: const InputDecoration(hintText: "E-mail")),
            TextField(controller: pCont, obscureText: true, decoration: const InputDecoration(hintText: "Contraseña")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _intentarRegistro(eCont, pCont),
              style: ElevatedButton.styleFrom(backgroundColor: unimetOrange),
              child: const Text("Crear cuenta", style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}