import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/material_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // Para Base64
import 'dart:typed_data'; // Para Uint8List

class PublishViewModel extends ChangeNotifier {
  final MaterialService _materialService;
  
  PublishViewModel(this._materialService);

  XFile? _selectedImage;
  Uint8List? _imageBytes; // Aquí guardamos la foto en memoria (Web y Móvil compatible)
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  XFile? get selectedImage => _selectedImage;

  // Función para seleccionar y comprimir la imagen
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    // CONFIGURACIÓN CLAVE PARA QUE FUNCIONE EN FIRESTORE
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,    // Reducimos el ancho a 500px (Suficiente para celular)
      maxHeight: 500,   // Reducimos alto
      imageQuality: 50, // Calidad media para ahorrar espacio
    );
    
    if (image != null) {
      _selectedImage = image;
      
      // Leemos los bytes (Funciona en Web y Móvil)
      _imageBytes = await image.readAsBytes();
      
      notifyListeners();
    }
  }

  Future<bool> publish({
    required String title,
    required String author,
    required String category,
    required String subject,
    required String description,
  }) async {
    // Validamos que haya imagen cargada en memoria
    if (_imageBytes == null) return false;
    
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    _isLoading = true;
    notifyListeners(); 

    try {
      // convierte la foto en un texto para guardarla en la BD
      String base64Image = base64Encode(_imageBytes!);

      await _materialService.addMaterial({
        'userId': currentUserId,
        'title': title,
        'author': author,
        'category': category,
        'subject': subject,
        'description': description,
        'imageUrl': base64Image, // Guardamos la foto aquí
        'isBase64': true,        // Marca para saber cómo leerla luego
        'status': 'disponible',
        'createdAt': DateTime.now(),
      });
      
      clearData();
      return true;
    } catch (e) {
      print("Error al publicar: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _selectedImage = null;
    _imageBytes = null;
    _isLoading = false;
    notifyListeners();
  }
}