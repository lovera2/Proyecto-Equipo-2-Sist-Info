import 'package:flutter/material.dart';
import 'home_viewmodel.dart';
import 'profile_page.dart';
import 'login_page.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeViewModel _viewModel = HomeViewModel();

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: _buildAppBar(context),
          body: _viewModel.isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildContent(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: unimetBlue,
      elevation: 0,
      title: const Text("BookLoop", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      actions: [
        IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
        IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
        ),
        _buildOptionsMenu(context),
      ],
    );
  }

  Widget _buildOptionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) async {
        if (value == 'logout') {
          await _viewModel.logout();
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'settings', child: Text('Configuración')),
        const PopupMenuItem(value: 'logout', child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 40),
          const Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey),
          const Text("El esqueleto está listo.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: unimetBlue,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: const Text(
        "¡Bienvenido,\nUnimetano!",
        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }
}