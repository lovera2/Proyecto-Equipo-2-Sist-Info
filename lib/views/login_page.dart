import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa correo y contraseña.")),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final ok = await authVM.login(email, password);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚀 ¡Bienvenido a BookLoop!"),
          backgroundColor: unimetBlue,
        ),
      );

      if (email.startsWith('admin')) {
        Navigator.pushReplacementNamed(context, '/home_admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home_page');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? "Error al iniciar sesión"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _backButton({required Color color}) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: color,
      onPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isWide = MediaQuery.of(context).size.width > 600;

    final leftPane = Container(
      color: unimetBlue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "BookLoop",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text("UNIMET", style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8))),
          ],
        ),
      ),
    );

    final rightPane = Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Iniciar Sesión", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: unimetBlue)),
          const SizedBox(height: 30),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Correo UNIMET", prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authVM.isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(backgroundColor: unimetOrange, foregroundColor: Colors.white),
              child: authVM.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTRAR"),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
              },
              child: const Text("Crear una cuenta", style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: isWide 
        ? Row(children: [Expanded(child: leftPane), Expanded(child: rightPane)])
        : SingleChildScrollView(
            child: Column(
              children: [
                Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.all(12), child: _backButton(color: unimetBlue))),
                SizedBox(height: 250, child: leftPane),
                rightPane,
              ],
            ),
          ),
    );
  }
}