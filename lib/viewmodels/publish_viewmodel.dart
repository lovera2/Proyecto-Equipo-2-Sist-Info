import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/material_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublishViewModel extends ChangeNotifier {
  final MaterialService _materialService;
  
  // El constructor recibe el servicio de materiales que definimos en el main.
  PublishViewModel(this._materialService);

  XFile? _selectedImage;
  XFile? get selectedImage => _selectedImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // usamos image_picker para la foto.
  // IMPORTANTE: En Web, el .path de la imagen es un "blob URL" temporal.
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Le bajamos un poco la calidad para que no pese tanto en la bd.
    );
    
    if (image != null) {
      _selectedImage = image;
      notifyListeners(); // Avisamos a la vista que ya hay foto para que la muestre.
    }
  }

  // Esta función empaqueta todo y lo manda al servicio.
  Future<bool> publish({
    required String title,
    required String author,
    required String category,
    required String subject,
    required String description,
  }) async {
    if (_selectedImage == null) return false;
    
    // Con esta línea le pedimos a Firebase el ID del usuario que está logueado
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Si por algún motivo no hay usuario, cancelamos la subida
    if (currentUserId == null) return false;
    _isLoading = true;
    notifyListeners(); // Ponemos el botón en modo "cargando".

    try {
      await _materialService.uploadMaterial({
        'userId': currentUserId,
        'title': title,
        'author': author,
        'category': category,
        'subject': subject,
        'description': description,
        'imageUrl': _selectedImage!.path, // esto es temporal, luego hay que subirlo a Storage.
        'status': 'disponible',
        'createdAt': DateTime.now(),
      });
      
      _selectedImage = null; // Limpiamos para la próxima.
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _selectedImage = null; // Borra la imagen de la memoria
    _isLoading = false;    // Reinicia la carga
    notifyListeners();     // Avisa a la pantalla que se actualice
  }
  
}