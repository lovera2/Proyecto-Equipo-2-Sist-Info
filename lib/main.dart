import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importación necesaria
import 'firebase_options.dart'; // El archivo generado con flutterfire
import 'home_page.dart';

void main() async { // Se coloco 'async' para que pueda esperar por Firebase
  // Esta funcion se asegura que Flutter esté listo antes de conectar a Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Esto usa las credenciales del archivo que creamos
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Manejo de errores
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.red,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  // ------------------------------------------------

  runApp(const BookLoopApp());
}

class BookLoopApp extends StatelessWidget {
  const BookLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookLoop Unimet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange, 
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}