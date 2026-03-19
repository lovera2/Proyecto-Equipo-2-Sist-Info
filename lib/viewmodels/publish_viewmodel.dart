import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/material_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublishViewModel extends ChangeNotifier {
  final MaterialService _materialService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PublishViewModel(this._materialService);

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  XFile? get selectedImage => _selectedImage;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 50,
    );

    if (image != null) {
      _selectedImage = image;
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
    _errorMessage = null;
    if (_imageBytes == null) {
      _errorMessage = "Por favor, selecciona una imagen.";
      notifyListeners();
      return false;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = await _db.collection('usuarios').doc(user.uid).get();
      if (!userDoc.exists) throw "Usuario no encontrado";

      int exchanges = userDoc.data()?['free_exchanges'] ?? 0;

      if (exchanges == 0) {
        _errorMessage =
            "Has agotado tus intercambios gratuitos. Realiza una donación para obtener acceso ilimitado.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      String base64Image = base64Encode(_imageBytes!);

      await _materialService.addMaterial({
        'userId': user.uid,
        'title': title,
        'author': author,
        'category': category,
        'normalizedCategory': category.trim().toLowerCase(),
        'subject': subject,
        'description': description,
        'imageUrl': base64Image,
        'isBase64': true,
        'status': 'disponible',
        'createdAt': DateTime.now(),
      });

      if (exchanges > 0) {
        await _db.collection('usuarios').doc(user.uid).update({
          'free_exchanges': exchanges - 1,
        });
      }

      clearData();
      return true;
    } catch (e) {
      print("Error al publicar: $e");
      _errorMessage = "Error al conectar con el servidor.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _selectedImage = null;
    _imageBytes = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

// PublishViewModel es una clase que maneja la lógica de publicación de materiales en la plataforma. Permite a los usuarios seleccionar una imagen, ingresar detalles del material y publicar el material en la base de datos. También gestiona el estado de carga y los mensajes de error, asegurando una experiencia de usuario fluida y clara durante el proceso de publicación.