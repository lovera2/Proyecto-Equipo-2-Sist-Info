import 'package:flutter/material.dart';
// Importé aquí las pantallas que llevamos listas para que no den error al compilar
import 'profile_page.dart';
import 'login_page.dart'; 

void main() {
  runApp(const BookLoopApp());
}

class BookLoopApp extends StatelessWidget {
  const BookLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookLoop Unimet',
      debugShowCheckedModeBanner: false, // Quité el banner de "Debug" para que la interfaz se vea más limpia
      theme: ThemeData(
        // Aquí configuré los colores que sacamos de las láminas:
        // El azul marino de fondo y el naranja para los botones de acción
        primaryColor: const Color(0xFF1B3A57), 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B3A57),
          secondary: const Color(0xFFF28B31), 
        ),
        useMaterial3: true,
      ),
      // Cambié la página inicial a LoginPage para que probemos de una vez
      // el diseño dividido que teníamos en el PowerPoint. 
      // Si necesitan volver al perfil, solo cámbienlo por ProfilePage().
      home: const LoginPage(), 
    );
  }
}