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

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? "Error al iniciar sesión"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚀 ¡Bienvenido a BookLoop!"),
        backgroundColor: unimetOrange,
      ),
    );

    if (email.startsWith('admin')) {
      Navigator.pushReplacementNamed(context, '/home_admin');
    } else {
      Navigator.pushReplacementNamed(context, '/home_page');
    }
  }

  Widget _backButton({required Color color}) {
    return IconButton(
      tooltip: 'Volver',
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: color),
      onPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 900;

    // PANEL IZQUIERDO 
    final Widget leftPane = Container(
      color: unimetBlue,
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: _backButton(color: Colors.white),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 56 : 24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "¡Bienvenido\nde nuevo!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWide ? 48 : 32, 
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isWide) ...[ 
                    Text(
                      "Acceso exclusivo para la comunidad UNIMET.\nInicia sesión y sigue tu intercambio académico.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const _BenefitRow(
                      icon: Icons.verified_user_outlined,
                      text: "Perfiles verificados (correo institucional).",
                    ),
                    const SizedBox(height: 10),
                    const _BenefitRow(
                      icon: Icons.swap_horiz_rounded,
                      text: "Intercambio y trazabilidad del material.",
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // PANEL DERECHO 
    final Widget rightPane = Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 50 : 24, // Menos espacio a los lados en móvil
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Image.asset(
                'assets/images/bookloop_logo.png',
                height: isWide ? 160 : 100, // Logo más pequeño en móvil
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.menu_book, size: 70, color: unimetBlue),
              ),
              const SizedBox(height: 12),
              const Text(
                "Inicio de sesión",
                style: TextStyle(
                  fontSize: 24,
                  color: unimetOrange,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Correo UNIMET",
                  style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "usuario@correo.unimet.edu.ve",
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: unimetBlue.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Contraseña",
                  style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "••••••••",
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: unimetBlue.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authVM.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unimetOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: authVM.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ENTRAR", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text(
                  "¿No tienes cuenta? Regístrate aquí",
                  style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );


    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(child: leftPane),
            Expanded(child: rightPane),
          ],
        ),
      );
    }

    // DISEÑO MÓVIL
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            SizedBox(
              height: 200, 
              width: double.infinity, 
              child: leftPane
            ),
            rightPane,
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
          ),
        ),
      ],
    );
  }
}