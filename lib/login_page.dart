import 'package:flutter/material.dart';
import 'register_page.dart'; // Importación necesaria para habilitar la navegación

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // Colores del manual de marca de nuestro equipo
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row( // Usamos un Row para dividir la pantalla en dos (como en el PPT)
        children: [
          // Lado Izquierdo: El mensaje de bienvenida azul
          Expanded(
            flex: 1,
            child: Container(
              color: unimetBlue,
              child: const Center(
                child: Text(
                  "¡Bienvenido\nde nuevo!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          // Lado Derecho: El formulario de login blanco
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(50),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
  'assets/images/bookloop_logo.png',
  height: 190,
),
                  const SizedBox(height: 20),
                  const Text("Inicio de sesión", style: TextStyle(fontSize: 28, color: unimetOrange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  
                  // Campos de texto estilizados como en las láminas
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Usuario / e-mail",
                      filled: true,
                      fillColor: unimetBlue.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Contraseña",
                      filled: true,
                      fillColor: unimetBlue.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Botón de iniciar sesión naranja
                  // Botón principal de acceso
                  ElevatedButton(
                    onPressed: () {
                      // Lógica de autenticación pendiente
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: unimetOrange,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Iniciar sesión",
                      style: TextStyle(color: Colors.white),
                    ),
                  ), // <-- Aquí termina el botón de iniciar sesión

                  const SizedBox(height: 20),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 10),

                  // Botón de navegación hacia la pantalla de registro según el diseño
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Crear una cuenta",
                      style: TextStyle(
                        color: unimetBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}