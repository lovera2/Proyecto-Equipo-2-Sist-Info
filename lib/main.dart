import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  // Va a mostrar error en pantalla, si lo hay.
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

  runApp(const BookLoopApp());
}

class BookLoopApp extends StatelessWidget {
  const BookLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookLoop Unimet',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}