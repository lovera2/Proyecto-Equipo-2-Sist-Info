import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget { // Cambiado a StatefulWidget
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 1. Controladores para capturar la info
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  // 2. Lógica de validación (Requerimiento RF-01)
  void _intentarRegistro() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _mostrarAlerta("Por favor, llena todos los campos.");
      return;
    }

    if (email.endsWith('@unimet.edu.ve') || email.endsWith('@correo.unimet.edu.ve')) {
      // En esta seccion voy a conectar luego la parte de firebase
      _mostrarAlerta("¡Cuenta creada con éxito para $email! (Próximo paso: Pago)");
      
      // Simulación de navegación a la página de pago (sera una especie de muestra de como luce la pagina de pago)
      print("Navegando a Paywall..."); 
    } else {
      _mostrarAlerta("Error: Solo se permiten correos institucionales (@unimet.edu.ve)");
    }
  }

  void _mostrarAlerta(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
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

  Widget _buildRoleCard(String title, IconData icon) {
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
            // ASIGNAMOS EL CONTROLLER AQUÍ
            TextField(
              controller: _emailController, 
              decoration: const InputDecoration(hintText: "E-mail")
            ),
            TextField(
              controller: _passwordController, 
              obscureText: true, 
              decoration: const InputDecoration(hintText: "Contraseña")
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _intentarRegistro, // LLAMAMOS A LA FUNCIÓN DE VALIDACIÓN
              style: ElevatedButton.styleFrom(backgroundColor: unimetOrange),
              child: const Text("Crear cuenta", style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}