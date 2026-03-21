import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/publish_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bookloop_unimet/views/chat_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_screen.dart';
import '../services/material_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublishPage extends StatefulWidget {
  final bool isUserAdmin;

  const PublishPage({super.key, this.isUserAdmin = false});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ScrollController _myScrollController = ScrollController();

  String? _selectedCategory;

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  late final Color themeColor =
      widget.isUserAdmin ? unimetBlue : unimetOrange;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    _myScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    context.read<PublishViewModel>().clearData();
    await context.read<AuthViewModel>().logout();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: unimetOrange,
        content: Text(
          "👋 Sesión cerrada. ¡Vuelve pronto!",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PublishViewModel>();
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 800; // Detección de pantalla responsiva

    // 1. Fragmento para la imagen
    final Widget selectorImagen = Column(
      children: [
        GestureDetector(
          onTap: viewModel.pickImage,
          child: Container(
            height: isWide ? (kIsWeb ? 500 : 280) : 220,
            width: isWide ? (kIsWeb ? 350 : 190) : 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: viewModel.selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: isWide ? (kIsWeb ? 80 : 50) : 40, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      const Text("Subir Portada", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: kIsWeb
                        ? Image.network(viewModel.selectedImage!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                        : Image.file(File(viewModel.selectedImage!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        const Text("Portada del Material", style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );

    // 2. Fragmento para los campos
    final Widget camposFormulario = Column(
      children: [
        _buildUnimetField("Título...", _titleController),
        _buildUnimetField("Autor...", _authorController),
        StreamBuilder<List<String>>(
          stream: context.read<MaterialService>().getCategoriesStream(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? MaterialService.defaultCategories;

            if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedCategory = null);
              });
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF8DA4B9).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text("Selecciona una Categoría...", style: TextStyle(color: Colors.white70)),
                  dropdownColor: const Color(0xFF1B3A57),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  borderRadius: BorderRadius.circular(15),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (String? newValue) => setState(() => _selectedCategory = newValue),
                ),
              ),
            );
          },
        ),
        _buildUnimetField("Asignatura...", _subjectController),
        _buildUnimetField("Descripción corta...", _descController, maxLines: 3),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2A3F), unimetBlue, Color(0xFF2C5E8C)],
              ),
            ),
          ),
          const _BackgroundBlobs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: isWide ? 850 : size.width * 0.95,
                      child: RawScrollbar(
                        controller: _myScrollController,
                        thumbColor: Colors.grey,
                        radius: const Radius.circular(20),
                        thickness: 6,
                        thumbVisibility: false,
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                        child: SingleChildScrollView(
                          controller: _myScrollController,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            padding: EdgeInsets.all(isWide ? 30 : 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Publicar Material",
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: unimetBlue),
                                ),
                                const SizedBox(height: 25),
                                
                                // responsivo
                                isWide
                                    ? Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(flex: 1, child: selectorImagen),
                                          const SizedBox(width: 30),
                                          Expanded(flex: 2, child: camposFormulario),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Center(child: selectorImagen),
                                          const SizedBox(height: 25),
                                          camposFormulario,
                                        ],
                                      ),
                                      
                                const SizedBox(height: 25),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: isWide ? 180 : double.infinity,
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
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    context.read<PublishViewModel>().clearData();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 4),
                const Icon(Icons.menu_book, color: Colors.white, size: 22),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    "BookLoop",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ],
            ),
          ),
          
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: unimetOrange, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
              _headerCircleBtn(Icons.home_outlined, () {
                Navigator.pushNamedAndRemoveUntil(context, '/home_page', (route) => false);
              }),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chats').where('users', arrayContains: currentUid).snapshots(),
                builder: (context, snapshot) {
                  bool hasActivity = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return Badge(
                    isLabelVisible: hasActivity,
                    backgroundColor: Colors.redAccent,
                    child: _headerCircleBtn(Icons.notifications_none_outlined, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListPage()));
                    }),
                  );
                },
              ),
              _headerCircleBtn(Icons.person_outline, () {
                Navigator.pushNamed(context, '/profile');
              }),
              _buildPopupMenu(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCircleBtn(IconData icon, VoidCallback tap) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        padding: EdgeInsets.zero, 
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: Colors.white, size: 18), 
        onPressed: tap
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) async {
        if (value == 'donate') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen()));
        } else if (value == 'logout') {
          await _handleLogout(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'donate',
          child: Row(children: [Icon(Icons.volunteer_activism, color: Color(0xFFF28B31)), SizedBox(width: 10), Text('Realizar donación')]),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(children: [Icon(Icons.logout, color: Color(0xFF1B3A57)), SizedBox(width: 10), Text('Cerrar sesión')]),
        ),
      ],
    );
  }

  Widget _buildUnimetField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _handlePublish() async {
    final vm = context.read<PublishViewModel>();

    if (_titleController.text.trim().isEmpty ||
        _authorController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _subjectController.text.trim().isEmpty ||
        vm.selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ Debes rellenar todos los campos y subir una foto del material.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await vm.publish(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      category: _selectedCategory!,
      subject: _subjectController.text.trim(),
      description: _descController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ ¡Material publicado con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? "Error al publicar material"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

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

// PublishPage es una pantalla que permite a los usuarios publicar nuevos materiales en la plataforma. Incluye un formulario para ingresar detalles del material, subir una imagen de portada y seleccionar una categoría. La interfaz es moderna y adaptada a diferentes tamaños de pantalla, con un diseño atractivo y fácil de usar. El ViewModel asociado maneja la lógica de publicación, incluyendo validaciones, interacción con el servicio de materiales y gestión del estado de carga y errores.