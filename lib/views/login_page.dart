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

  final TextEditingController _emailController=TextEditingController();
  final TextEditingController _passwordController=TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email=_emailController.text.trim();
    final password=_passwordController.text.trim();

    if(email.isEmpty || password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa correo y contraseña.")),
      );
      return;
    }

    final authVM=context.read<AuthViewModel>();
    final ok=await authVM.login(email,password);

    if(!mounted) return;

    if(ok){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Sesión iniciada correctamente."),
          backgroundColor: unimetBlue,
        ),
      );
      Navigator.pop(context); // vuelve a StartPage
    }else{
      final msg=authVM.errorMessage ?? "❌ No se pudo iniciar sesión.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM=context.watch<AuthViewModel>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context,constraints){
          final bool isWide=constraints.maxWidth >= 900;

          final Widget leftPane=Container(
            color: unimetBlue,
            child: const Center(
              child: Text(
                "¡Bienvenido\nde nuevo!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
          );

          final Widget rightPane=Container(
            padding: const EdgeInsets.all(50),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/bookloop_logo.png', height: 190),
                const SizedBox(height: 20),
                const Text(
                  "Inicio de sesión",
                  style: TextStyle(fontSize: 28, color: unimetOrange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Usuario / e-mail",
                    filled: true,
                    fillColor: unimetBlue.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Contraseña",
                    filled: true,
                    fillColor: unimetBlue.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: authVM.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unimetOrange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: authVM.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Iniciar sesión", style: TextStyle(color: Colors.white)),
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text(
                    "Crear una cuenta",
                    style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          );

          if(isWide){
            return Row(
              children: [
                Expanded(flex: 1, child: leftPane),
                Expanded(flex: 1, child: rightPane),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 260,
                  child: leftPane,
                ),
                rightPane,
              ],
            ),
          );
        },
      ),
    );
  }
}