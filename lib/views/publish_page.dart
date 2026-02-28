import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/publish_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'dart:io'; 
import 'package:flutter/foundation.dart'; 


class PublishPage extends StatefulWidget {
  final bool isUserAdmin;

  const PublishPage({super.key, this.isUserAdmin = false});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  // definimos controladores para capturar el texto de cada campo
  // esto nos permite obtener lo que el usuario escribe para mandarlo a Firebase
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ScrollController _myScrollController = ScrollController();

  String? _selectedCategory; // Aquí guardaremos la opción elegida
  final List<String> _categories = [
    'Fases',
    'Ingeniería',
    'Humanidades',
    'Derecho',
  ];

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  // Se decide el color dependiendo de si es admin o no
  late final Color themeColor = widget.isUserAdmin ? unimetBlue : unimetOrange;

  @override
  void dispose() {
    // Cerramos los controladores al salir de la pantalla para evitar fugas de memoria
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    _myScrollController.dispose();
    
    
    super.dispose();
  }

  // logica de cerras sesion 
  Future<void> _handleLogout(BuildContext context) async {
    context.read<PublishViewModel>().clearData();
    await context.read<AuthViewModel>().logout();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: unimetOrange,
        content: Text("👋 Sesión cerrada. ¡Vuelve pronto!", style: TextStyle(color: Colors.white)),
      ),
    );
    
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al ViewModel para manejar el estado de la imagen y la carga
    final viewModel = context.watch<PublishViewModel>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Usamos un Stack para poner el fondo decorativo detrás del formulario
      body: Stack(
        children: [
          // Fondo con el degradado azul 
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2A3F), unimetBlue, Color(0xFF2C5E8C)],
              ),
            ),
          ),
          //  círculos decorativos para mantener la estética 
          const _BackgroundBlobs(),

          SafeArea(
            child: Column(
              children: [
                // Barra superior con el botón de volver y los iconos de navegación
                _buildHeader(context),

                // Contenedor principal: Una tarjeta blanca centrada
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: size.width > 850 ? 850 : size.width * 0.95,
                      child: RawScrollbar(
                        controller: _myScrollController,
                        thumbColor: Colors.grey, // Gris clásico 
                        radius: const Radius.circular(20),
                        thickness: 6,
                        thumbVisibility: false, 
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                        child: SingleChildScrollView(
                          controller: _myScrollController,
                          padding: const EdgeInsets.symmetric(vertical: 10), 
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                const Text(
                                  "Publicar Material",
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: unimetBlue),
                                ),
                                const SizedBox(height: 25),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        GestureDetector(
                                          onTap: viewModel.pickImage,
                                          child: Container(
                                            // Lógica de tamaño, grande en Web, Normal en Móvil
                                            height: kIsWeb ? 500 : 280,
                                            width: kIsWeb ? 350 : 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: Colors.grey[300]!),
                                              boxShadow: const [
                                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                              ],
                                            ),
                                            child: viewModel.selectedImage == null
                                                ? Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.add_photo_alternate_outlined, 
                                                        size: kIsWeb ? 80 : 50, 
                                                        color: Colors.grey[400]
                                                      ),
                                                      const SizedBox(height: 10),
                                                      const Text("Subir Portada", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                                    ],
                                                  )
                                                : ClipRRect(
                                                    borderRadius: BorderRadius.circular(15),
                                                    child: kIsWeb
                                                        // CASO 1: WEB (Usa Image.network)
                                                        ? Image.network(
                                                            viewModel.selectedImage!.path,
                                                            fit: BoxFit.cover,
                                                            width: 350,
                                                            height: 500,
                                                          )
                                                        // CASO 2: MÓVIL (Usa Image.file)
                                                        : Image.file(
                                                            File(viewModel.selectedImage!.path),
                                                            fit: BoxFit.cover,
                                                            width: 190,
                                                            height: 280,
                                                          ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text("Portada del Material", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                    const SizedBox(width: 30),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: [
                                          _buildUnimetField("Título...", _titleController),
                                          _buildUnimetField("Autor...", _authorController),
                                          Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8DA4B9).withOpacity(0.5), // Mismo color que tus inputs
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedCategory,
                                              hint: const Text("Selecciona una Categoría...", style: TextStyle(color: Colors.white70)),
                                              dropdownColor: const Color(0xFF1B3A57), // Azul oscuro para el menú desplegado
                                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                              isExpanded: true,
                                              style: const TextStyle(color: Colors.white, fontSize: 16),
                                              borderRadius: BorderRadius.circular(15), 
                                              items: _categories.map((String category) {
                                                return DropdownMenuItem<String>(
                                                  value: category,
                                                  child: Text(category),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedCategory = newValue;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                          _buildUnimetField("Asignatura...", _subjectController),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                _buildUnimetField("Descripción corta...", _descController, maxLines: 3),

                                const SizedBox(height: 25),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: 180,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: viewModel.isLoading ? null : _handlePublish,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: themeColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: viewModel.isLoading
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Text("Publicar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                onPressed: () {
                  // Limpiamos datos antes de volver
                  context.read<PublishViewModel>().clearData();
                  Navigator.pop(context); 
                }, 
              ),
              const SizedBox(width: 5),
              const Icon(Icons.menu_book, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              const Text(
                "BookLoop",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Botones Funcionales (Copiados del Home)
          Row(
            children: [
              
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                tooltip: 'Ir al Inicio',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home_page', (route) => false);
                },
              ),
              const SizedBox(width: 10),

              // Notificaciones
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("🔔 Notificaciones en desarrollo...")),
                  );
                },
              ),
              
              // Perfil
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');    
                },
              ),
              
              // Menú de 3 puntos 
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: unimetBlue),
                        SizedBox(width: 10),
                        Text("Cerrar Sesión"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget reutilizable para crear los campos de texto con el estilo de la Unimet.
  Widget _buildUnimetField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFF8DA4B9).withOpacity(0.5),
          hintStyle: const TextStyle(color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  //Valida los datos y llama al ViewModel para publicar.
  Future<void> _handlePublish() async {
    final vm = context.read<PublishViewModel>();
    
    //Aquí validamos que NADA esté vacío
  if (_titleController.text.trim().isEmpty || 
      _authorController.text.trim().isEmpty || 
      _selectedCategory == null || 
      _subjectController.text.trim().isEmpty || 
      vm.selectedImage == null) {
    
    // Si falta algo, mandamos este aviso y el 'return' detiene la publicación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ Debes rellenar todos los campos y subir una foto del material."),
        backgroundColor: Colors.redAccent,
      ),
    );
      return;
    }

    final success = await vm.publish(
      title: _titleController.text,
      author: _authorController.text,
      category: _selectedCategory!,
      subject: _subjectController.text,
      description: _descController.text,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Material publicado con éxito 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Clase para pintar los círculos decorativos del fondo.
class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlobPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 150, p1);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 200, p1);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}